import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/constants/currency.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:resturent_application/feature/restaurant/auth/presentation/provider/branch_auth_provider.dart';
import 'package:resturent_application/feature/restaurant/live_orders/presentation/live_orders_screen.dart';
import 'package:resturent_application/feature/restaurant/pos_and_order/data/model/order_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bg = Color(0xFFD4D4D2);
const _panel = Color(0xFFE9E9E9);
// The sales day runs from 6:00 AM to 6:00 AM the next morning.
const _dayStartHour = 6;
const _hourSteps = [1, 2, 3, 4, 6, 8];

class _Section {
  final String key;
  final String label;
  final Color color;
  const _Section(this.key, this.label, this.color);
}

const _sections = [
  _Section('time', 'Time Based Sales', Color(0xFF1AB0C5)),
  _Section('payments', 'Payment Report', Color(0xFFA8C08A)),
  _Section('deliveries', 'Delivery Report', Color(0xFF2368D6)),
  _Section('category', 'Category Report', Color(0xFFFF7A00)),
  _Section('products', 'Products Report', Color(0xFF3DBB16)),
  _Section('detailed', 'Detailed Order Sales', Color(0xFF9B51B8)),
  _Section('offers', 'Offers Report', Color(0xFFE0301E)),
  _Section('other', 'Other Orders', Color(0xFF9CA3AF)),
];

Color _sectionColor(String key) =>
    _sections.firstWhere((s) => s.key == key).color;

/// Orders of one sales day plus a menu item → category name lookup.
class _ReportData {
  final List<OrderModel> orders; // cancelled orders are left out
  final List<OrderModel> cancelled;
  final Map<String, String> categoryOf;
  const _ReportData(this.orders, this.cancelled, this.categoryOf);
}

typedef _Totals = Map<String, ({int qty, double amount})>;

String _typeName(String t) => switch (t) {
  'Dine-in' => 'Dine',
  'Delivery' => 'Delivery',
  _ => 'Collection',
};

_Totals _add(_Totals m, String key, int qty, double amount) {
  final old = m[key];
  m[key] = (qty: (old?.qty ?? 0) + qty, amount: (old?.amount ?? 0) + amount);
  return m;
}

List<MapEntry<String, ({int qty, double amount})>> _sorted(_Totals m) =>
    m.entries.toList()
      ..sort((a, b) => b.value.amount.compareTo(a.value.amount));

_Totals _byProduct(Iterable<OrderModel> orders) {
  final m = <String, ({int qty, double amount})>{};
  for (final o in orders) {
    for (final i in o.items) {
      _add(m, i.itemName, i.qty, i.totalPrice);
    }
  }
  return m;
}

_Totals _byCategory(
  Iterable<OrderModel> orders,
  Map<String, String> categoryOf,
) {
  final m = <String, ({int qty, double amount})>{};
  for (final o in orders) {
    for (final i in o.items) {
      _add(m, categoryOf[i.menuItemId] ?? 'Other', i.qty, i.totalPrice);
    }
  }
  return m;
}

/// Sales report for one day: pick the sections, see the figures, print them.
class SalesReportScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  // X & Z report = counting the till and closing the shift.
  final VoidCallback onShiftReport;
  const SalesReportScreen({
    super.key,
    required this.onBack,
    required this.onShiftReport,
  });

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  late DateTime _day = _salesDay(DateTime.now());
  late Future<_ReportData> _future = _load();
  final Set<String> _on = {for (final s in _sections) s.key};
  int _step = 1;
  bool _byCategoryToo = false;
  bool _byProductToo = false;

  static DateTime _salesDay(DateTime now) {
    final d = DateTime(now.year, now.month, now.day);
    return now.hour < _dayStartHour ? d.subtract(const Duration(days: 1)) : d;
  }

  DateTime get _from =>
      DateTime(_day.year, _day.month, _day.day, _dayStartHour);
  DateTime get _to => _from.add(const Duration(days: 1));

  Future<_ReportData> _load() async {
    final db = Supabase.instance.client;
    final branchId = ref.read(branchAuthProvider).branch!.branchId;
    final rows = await db
        .from('orders')
        .select('*, order_items(*)')
        .gte('created_at', _from.toUtc().toIso8601String())
        .lt('created_at', _to.toUtc().toIso8601String())
        .order('created_at', ascending: true)
        .limit(2000);
    final all = [
      for (final e in rows as List)
        OrderModel.fromJson(
          e,
          items: [
            for (final i in (e['order_items'] as List? ?? []))
              OrderItemModel.fromJson(i),
          ],
        ),
    ];
    final cats = {
      for (final c in await db.from('categories').select('id, name'))
        c['id'] as String: c['name'] as String,
    };
    final items = await db.from('menu_items').select('id, category_id');
    final categoryOf = {
      for (final m in items)
        if (cats[m['category_id']] != null)
          m['id'] as String: cats[m['category_id']]!,
    };
    return _ReportData(
      all.where((o) => o.status.toLowerCase() != 'cancelled').toList(),
      all.where((o) => o.status.toLowerCase() == 'cancelled').toList(),
      categoryOf,
    );
  }

  void _moveDay(int days) => setState(() {
    _day = _day.add(Duration(days: days));
    _future = _load();
  });

  Future<void> _pickDay() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null) return;
    setState(() {
      _day = DateTime(d.year, d.month, d.day);
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d/M/yyyy h:mm a');
    return Container(
      color: _bg,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 360,
                    child: Container(
                      color: _panel,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
                            child: Column(
                              children: [
                                Text(
                                  '${fmt.format(_from)} to ${fmt.format(_to)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Material(
                                      color: const Color(0xFF2C73B8),
                                      borderRadius: BorderRadius.circular(3),
                                      child: InkWell(
                                        onTap: _print,
                                        child: const SizedBox(
                                          width: 80,
                                          height: 54,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SvgIcon(
                                                AppIcons.printRounded,
                                                size: 20,
                                                color: Colors.white,
                                              ),
                                              SizedBox(height: 3),
                                              Text(
                                                'Print',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    _OrangeButton(
                                      icon: AppIcons.arrowBackRounded,
                                      onTap: () => _moveDay(-1),
                                    ),
                                    const SizedBox(width: 4),
                                    Material(
                                      color: const Color(0xFF2C73B8),
                                      borderRadius: BorderRadius.circular(3),
                                      child: InkWell(
                                        onTap: _pickDay,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 14,
                                          ),
                                          child: Text(
                                            DateFormat('dd/MM/yy').format(_day),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    _OrangeButton(
                                      icon: AppIcons.arrowForwardRounded,
                                      onTap: () => _moveDay(1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(child: _checklist()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FutureBuilder<_ReportData>(
                      future: _future,
                      builder: (_, snap) {
                        if (snap.hasError)
                          return Center(
                            child: Text(
                              'Could not load the report: ${snap.error}',
                              style: const TextStyle(color: Color(0xFFB91C1C)),
                            ),
                          );
                        if (!snap.hasData)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        return _cards(snap.data!);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
            child: Row(
              children: [
                const TimeBox(),
                const SizedBox(width: 10),
                _BarButton(
                  icon: AppIcons.arrowBackRounded,
                  color: Colors.black,
                  width: 230,
                  onTap: widget.onBack,
                ),
                const Spacer(),
                _BarButton(
                  label: 'X & Z REPORT',
                  icon: AppIcons.receiptLongRounded,
                  color: const Color(0xFF1E5FC4),
                  width: 230,
                  onTap: widget.onShiftReport,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Left: what to show ──────────────────────────────────────────────────────

  Widget _checklist() => ListView(
    children: [
      for (final s in _sections) ...[
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: s.color.withValues(alpha: 0.7)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
          child: Row(
            children: [
              _ColorTick(
                color: s.color,
                on: _on.contains(s.key),
                onTap: () => setState(
                  () =>
                      _on.contains(s.key) ? _on.remove(s.key) : _on.add(s.key),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(s.label, style: const TextStyle(fontSize: 14)),
              ),
              if (s.key == 'time')
                PopupMenuButton<int>(
                  onSelected: (v) => setState(() => _step = v),
                  itemBuilder: (_) => [
                    for (final h in _hourSteps)
                      PopupMenuItem(value: h, child: Text('$h Hr')),
                  ],
                  child: Container(
                    width: 130,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      border: Border.all(color: const Color(0xFFCCCCCC)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Text('$_step Hr'),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (s.key == 'time') ...[
          _subTick(
            'Category',
            _byCategoryToo,
            (v) => setState(() => _byCategoryToo = v),
          ),
          _subTick(
            'Product',
            _byProductToo,
            (v) => setState(() => _byProductToo = v),
          ),
        ],
      ],
    ],
  );

  Widget _subTick(String label, bool value, ValueChanged<bool> onChanged) =>
      Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFD6D6D6))),
        ),
        padding: const EdgeInsets.fromLTRB(60, 8, 10, 8),
        child: Row(
          children: [
            InkWell(
              onTap: () => onChanged(!value),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: value
                    ? const Icon(Icons.check, color: Color(0xFF1E5FC4))
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      );

  // ── Right: the figures ──────────────────────────────────────────────────────

  Widget _cards(_ReportData d) {
    final paid = d.orders.where((o) => o.paymentStatus == 'Paid').toList();
    final unpaid = d.orders.where((o) => o.paymentStatus != 'Paid').toList();

    final payments = <String, ({int qty, double amount})>{};
    for (final o in paid) {
      _add(payments, o.paymentMethod, 1, o.total);
    }
    final deliveries = <String, ({int qty, double amount})>{};
    for (final o in d.orders) {
      _add(deliveries, _typeName(o.orderType), 1, o.total);
    }
    final online = <String, ({int qty, double amount})>{};
    for (final o in d.orders) {
      _add(
        online,
        o.customerType == 'Online' ? 'Online' : 'Offline',
        1,
        o.total,
      );
    }
    online.putIfAbsent('Online', () => (qty: 0, amount: 0));
    online.putIfAbsent('Offline', () => (qty: 0, amount: 0));

    final discounted = d.orders.where((o) => o.discountAmt > 0).toList();

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth - 14; // room for the scrollbar
        final half = (w - 12) / 2;
        Widget? card(String key, double width, Widget Function() build) =>
            _on.contains(key) ? SizedBox(width: width, child: build()) : null;

        final cards = <Widget?>[
          card(
            'payments',
            half,
            () => _TableCard(
              title: 'Payments',
              color: _sectionColor('payments'),
              rows: [
                for (final e in _sorted(payments))
                  [e.key, '${e.value.qty}', formatMoney(e.value.amount)],
              ],
              total: formatMoney(paid.fold<double>(0, (s, o) => s + o.total)),
            ),
          ),
          card(
            'deliveries',
            half,
            () => _TableCard(
              title: 'Deliveries',
              color: _sectionColor('deliveries'),
              rows: [
                for (final e in _sorted(deliveries))
                  [e.key, '${e.value.qty}', formatMoney(e.value.amount)],
              ],
              total: formatMoney(
                d.orders.fold<double>(0, (s, o) => s + o.total),
              ),
            ),
          ),
          card(
            'category',
            half,
            () => _TableCard(
              title: 'Category',
              color: _sectionColor('category'),
              rows: [
                for (final e in _sorted(_byCategory(d.orders, d.categoryOf)))
                  [e.key, '${e.value.qty}', formatMoney(e.value.amount)],
              ],
            ),
          ),
          card(
            'products',
            half,
            () => _TableCard(
              title: 'Products',
              color: _sectionColor('products'),
              rows: [
                for (final e in _sorted(_byProduct(d.orders)))
                  [e.key, '${e.value.qty}', formatMoney(e.value.amount)],
              ],
            ),
          ),
          _on.contains('payments') || _on.contains('time')
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_on.contains('payments'))
                      SizedBox(
                        width: w * 0.38,
                        child: _TableCard(
                          title: 'Online / Offline',
                          color: const Color(0xFF3DBB16),
                          rows: [
                            for (final k in ['Online', 'Offline'])
                              [
                                k,
                                '${online[k]!.qty}',
                                formatMoney(online[k]!.amount),
                              ],
                          ],
                        ),
                      ),
                    if (_on.contains('payments') && _on.contains('time'))
                      const SizedBox(width: 12),
                    if (_on.contains('time'))
                      SizedBox(
                        width: _on.contains('payments') ? w * 0.62 - 12 : w,
                        child: _timeCard(d),
                      ),
                  ],
                )
              : null,
          card(
            'detailed',
            w,
            () => _TableCard(
              title: 'Detailed Order Sales',
              color: _sectionColor('detailed'),
              rows: [
                for (final o in d.orders)
                  [
                    '#${o.orderNumber}',
                    DateFormat('HH : mm').format(o.createdAt.toLocal()),
                    _typeName(o.orderType),
                    o.paymentMethod,
                    formatMoney(o.total),
                  ],
              ],
            ),
          ),
          card(
            'offers',
            half,
            () => _TableCard(
              title: 'Offers Report',
              color: _sectionColor('offers'),
              rows: [
                for (final o in discounted)
                  ['#${o.orderNumber}', 'Discount', formatMoney(o.discountAmt)],
              ],
              total: formatMoney(
                discounted.fold<double>(0, (s, o) => s + o.discountAmt),
              ),
            ),
          ),
          card(
            'other',
            half,
            () => _TableCard(
              title: 'Other orders',
              color: _sectionColor('other'),
              rows: [
                [
                  'Unpaid',
                  '${unpaid.length}',
                  formatMoney(unpaid.fold<double>(0, (s, o) => s + o.total)),
                ],
                [
                  'Cancelled',
                  '${d.cancelled.length}',
                  formatMoney(
                    d.cancelled.fold<double>(0, (s, o) => s + o.total),
                  ),
                ],
              ],
            ),
          ),
        ].whereType<Widget>().toList();

        return SingleChildScrollView(
          child: Wrap(spacing: 12, runSpacing: 14, children: cards),
        );
      },
    );
  }

  /// Orders grouped into [_step]-hour slots counted from the start of the sales day.
  List<({DateTime from, DateTime to, List<OrderModel> orders})> _slots(
    _ReportData d,
  ) {
    final slots = <({DateTime from, DateTime to, List<OrderModel> orders})>[];
    for (var h = 0; h < 24; h += _step) {
      final from = _from.add(Duration(hours: h));
      final to = _from.add(Duration(hours: (h + _step).clamp(0, 24)));
      final inSlot = d.orders.where((o) {
        final t = o.createdAt.toLocal();
        return !t.isBefore(from) && t.isBefore(to);
      }).toList();
      if (inSlot.isNotEmpty) slots.add((from: from, to: to, orders: inSlot));
    }
    return slots;
  }

  Widget _timeCard(_ReportData d) {
    final f = DateFormat('h:mma');
    final slots = _slots(d);
    return _TableCard(
      title: 'Time Based Sales',
      color: _sectionColor('time'),
      highlight: true,
      rows: [
        for (final s in slots) ...[
          [
            '${f.format(s.from)} - ${f.format(s.to)}',
            '${s.orders.length} Order${s.orders.length == 1 ? '' : 's'}',
            formatMoney(s.orders.fold<double>(0, (t, o) => t + o.total)),
          ],
          if (_byCategoryToo)
            for (final e in _sorted(_byCategory(s.orders, d.categoryOf)))
              ['   ${e.key}', '${e.value.qty}', formatMoney(e.value.amount)],
          if (_byProductToo)
            for (final e in _sorted(_byProduct(s.orders)))
              ['   ${e.key}', '${e.value.qty}', formatMoney(e.value.amount)],
        ],
      ],
    );
  }

  // ── Print ───────────────────────────────────────────────────────────────────

  Future<void> _print() async {
    final d = await _future;
    final paid = d.orders.where((o) => o.paymentStatus == 'Paid');
    final doc = pw.Document();

    pw.Widget table(String title, List<List<String>> rows) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 12),
        pw.Text(
          title,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
        ),
        pw.Divider(),
        if (rows.isEmpty)
          pw.Text('-')
        else
          pw.TableHelper.fromTextArray(
            data: rows,
            headerCount: 0,
            border: null,
            cellAlignment: pw.Alignment.centerLeft,
          ),
      ],
    );

    final payments = <String, ({int qty, double amount})>{};
    for (final o in paid) {
      _add(payments, o.paymentMethod, 1, o.total);
    }
    final deliveries = <String, ({int qty, double amount})>{};
    for (final o in d.orders) {
      _add(deliveries, _typeName(o.orderType), 1, o.total);
    }
    List<List<String>> lines(_Totals m) => [
      for (final e in _sorted(m))
        [e.key, '${e.value.qty}', formatMoney(e.value.amount)],
    ];

    final f = DateFormat('h:mma');
    doc.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Text(
            'Sales report',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
          ),
          pw.Text(
            '${DateFormat('d/M/yyyy h:mm a').format(_from)} to ${DateFormat('d/M/yyyy h:mm a').format(_to)}',
          ),
          pw.Text(
            'Orders: ${d.orders.length}   Total: ${formatMoney(d.orders.fold<double>(0, (s, o) => s + o.total))}',
          ),
          if (_on.contains('payments')) table('Payments', lines(payments)),
          if (_on.contains('deliveries'))
            table('Deliveries', lines(deliveries)),
          if (_on.contains('category'))
            table('Category', lines(_byCategory(d.orders, d.categoryOf))),
          if (_on.contains('products'))
            table('Products', lines(_byProduct(d.orders))),
          if (_on.contains('time'))
            table('Time based sales', [
              for (final s in _slots(d))
                [
                  '${f.format(s.from)} - ${f.format(s.to)}',
                  '${s.orders.length} order(s)',
                  formatMoney(s.orders.fold<double>(0, (t, o) => t + o.total)),
                ],
            ]),
          if (_on.contains('detailed'))
            table('Detailed order sales', [
              for (final o in d.orders)
                [
                  '#${o.orderNumber}',
                  DateFormat('HH:mm').format(o.createdAt.toLocal()),
                  _typeName(o.orderType),
                  o.paymentMethod,
                  formatMoney(o.total),
                ],
            ]),
          if (_on.contains('offers'))
            table('Offers', [
              for (final o in d.orders.where((o) => o.discountAmt > 0))
                ['#${o.orderNumber}', 'Discount', formatMoney(o.discountAmt)],
            ]),
        ],
      ),
    );
    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: 'Sales report ${DateFormat('yyyy-MM-dd').format(_day)}',
    );
  }
}

/// Coloured title bar over rows of (name, count, amount); an optional Total line.
class _TableCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<List<String>> rows;
  final String? total;
  final bool highlight;
  const _TableCard({
    required this.title,
    required this.color,
    required this.rows,
    this.total,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 56,
          color: color,
          alignment: Alignment.center,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (var i = 0; i < rows.length; i++)
          Container(
            color: highlight ? const Color(0xFFD9ECF7) : null,
            decoration: i == 0
                ? null
                : const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
                  ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                for (var j = 0; j < rows[i].length; j++)
                  Expanded(
                    flex: j == 0 ? 3 : 2,
                    child: Text(
                      rows[i][j],
                      textAlign: j == 0
                          ? TextAlign.left
                          : (j == rows[i].length - 1
                                ? TextAlign.right
                                : TextAlign.center),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            highlight && rows[i][0].trimLeft() == rows[i][0]
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(18),
            child: Text('No data', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
        if (total != null)
          Container(
            color: const Color(0xFFF3F3F3),
            padding: const EdgeInsets.fromLTRB(60, 14, 12, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  total!,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
      ],
    ),
  );
}

class _ColorTick extends StatelessWidget {
  final Color color;
  final bool on;
  final VoidCallback onTap;
  const _ColorTick({
    required this.color,
    required this.on,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: on ? color : Colors.white,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: on ? const Icon(Icons.check, color: Colors.white, size: 26) : null,
    ),
  );
}

class _OrangeButton extends StatelessWidget {
  final AppIcon icon;
  final VoidCallback onTap;
  const _OrangeButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFF7A00),
    borderRadius: BorderRadius.circular(3),
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        height: 46,
        child: Center(child: SvgIcon(icon, size: 20, color: Colors.white)),
      ),
    ),
  );
}

class _BarButton extends StatelessWidget {
  final String? label;
  final AppIcon icon;
  final Color color;
  final double width;
  final VoidCallback onTap;
  const _BarButton({
    this.label,
    required this.icon,
    required this.color,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    elevation: 4,
    shadowColor: Colors.black,
    borderRadius: BorderRadius.circular(3),
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon(icon, size: 28, color: Colors.white),
            if (label != null) ...[
              const SizedBox(height: 6),
              Text(
                label!,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
