import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/constants/currency.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:resturent_application/feature/restaurant/live_orders/presentation/live_orders_screen.dart';
import '../../../pos_and_order/data/model/order_model.dart';
import '../provider/order_provider.dart';
import '../widget/receipt_dilog_widget.dart';

const _bg = Color(0xFFF2F2F2);
const _barBg = Color(0xFFD4D4D2);
const _perPage = 15;

const _statusOptions = [
  ('pending', 'Ordered'),
  ('preparing', 'Preparing'),
  ('completed', 'Complete'),
  ('cancelled', 'Cancelled'),
];

String _statusLabel(String s) =>
    _statusOptions.where((o) => o.$1 == s.toLowerCase()).firstOrNull?.$2 ?? s;

Color _statusColor(String s) => switch (s.toLowerCase()) {
  'completed' || 'delivered' => const Color(0xFF2DC937),
  'preparing' => const Color(0xFF2EC4B6),
  'cancelled' => const Color(0xFF6B6B6B),
  _ => const Color(0xFFE05FE8),
};

Color _typeColor(String t) => switch (t) {
  'Dine-in' => const Color(0xFF2368D6),
  'Delivery' => const Color(0xFFFF7A00),
  _ => const Color(0xFFC9168A),
};

String _typeLabel(String t) => switch (t) {
  'Dine-in' => 'dine',
  'Delivery' => 'delivery',
  _ => 'collection',
};

AppIcon _typeIcon(String t) => switch (t) {
  'Dine-in' => AppIcons.restaurantRounded,
  'Delivery' => AppIcons.localShippingRounded,
  _ => AppIcons.shoppingBagRounded,
};

/// One day's orders as touch rows: tick rows to complete, change status or delete them,
/// tap a row for the full order.
class OrdersScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  const OrdersScreen({super.key, required this.onBack});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  late final OrderNotifier _notifier = ref.read(orderProvider.notifier);
  late DateTime _day = _today();
  final Set<String> _checked = {};
  int _page = 0;
  bool _filterOpen = false;

  // Filter panel (empty set = no filter in that group).
  final Set<String> _payFilter = {};
  final Set<String> _typeFilter = {};
  final Set<String> _statusFilter = {};

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadDay);
  }

  @override
  void dispose() {
    // The other screens (live board, manage) read the same list: put it back to the default.
    Future.microtask(_notifier.clearFilters);
    super.dispose();
  }

  void _loadDay() {
    final utc = _day.toUtc(); // the range is sent to the database as UTC
    _notifier.setDateRange(utc, utc);
  }

  void _moveDay(int days) {
    setState(() {
      _day = _day.add(Duration(days: days));
      _page = 0;
      _checked.clear();
    });
    _loadDay();
  }

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
      _page = 0;
      _checked.clear();
    });
    _loadDay();
  }

  bool _sameDay(DateTime a) {
    final l = a.toLocal();
    return l.year == _day.year && l.month == _day.month && l.day == _day.day;
  }

  bool _matches(OrderModel o) {
    if (!_sameDay(o.createdAt)) return false;
    final status = o.status.toLowerCase();
    // Deleted (cancelled) orders stay hidden unless asked for.
    if (_statusFilter.isEmpty
        ? status == 'cancelled'
        : !_statusFilter.contains(status))
      return false;
    if (_typeFilter.isNotEmpty && !_typeFilter.contains(o.orderType))
      return false;
    if (_payFilter.isNotEmpty) {
      final unpaid = o.paymentStatus != 'Paid';
      final keys = {
        if (o.paymentMethod == 'Cash' && !unpaid) 'cash',
        if (o.paymentMethod == 'Cash' && unpaid) 'cash_due',
        if (o.paymentMethod == 'Card') 'card',
        if (o.paymentMethod == 'Online') 'online',
      };
      if (keys.intersection(_payFilter).isEmpty) return false;
    }
    return true;
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  List<OrderModel> _selectedOrders(List<OrderModel> shown) =>
      shown.where((o) => _checked.contains(o.id)).toList();

  Future<void> _setStatus(List<OrderModel> orders, String status) async {
    for (final o in orders) {
      await _notifier.updateStatus(o.id, status);
    }
    if (mounted) setState(_checked.clear);
  }

  Future<void> _chooseStatus(List<OrderModel> orders) async {
    if (orders.isEmpty) return _snack('Tick an order first');
    final status = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Set status'),
        children: [
          for (final s in _statusOptions)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, s.$1),
              child: Text(s.$2),
            ),
        ],
      ),
    );
    if (status != null) await _setStatus(orders, status);
  }

  Future<void> _delete(List<OrderModel> orders) async {
    if (orders.isEmpty) return _snack('Tick an order first');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete orders'),
        content: Text(
          'Delete ${orders.length} order(s)? They are marked cancelled and removed from this list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9534F),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await _setStatus(orders, 'cancelled');
  }

  Future<void> _print(List<OrderModel> orders) async {
    if (orders.isEmpty) return _snack('Tick an order first');
    for (final o in orders) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => ReceiptPrintDialog(order: o),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    final selected = state.selected;
    if (selected != null) {
      // Always show the freshest copy (status changes, realtime updates).
      final fresh =
          state.orders.where((o) => o.id == selected.id).firstOrNull ??
          selected;
      return _OrderDetail(
        order: fresh,
        notifier: _notifier,
        onBack: () => _notifier.select(null),
      );
    }

    final shown = state.orders.where(_matches).toList();
    final pages = (shown.length / _perPage).ceil().clamp(1, 99999);
    final page = _page.clamp(0, pages - 1);
    final rows = shown.skip(page * _perPage).take(_perPage).toList();
    final picked = _selectedOrders(shown);
    final allTicked =
        rows.isNotEmpty && rows.every((o) => _checked.contains(o.id));

    return Stack(
      children: [
        Container(
          color: _barBg,
          child: Column(
            children: [
              Container(
                color: _bg,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    _Tick(
                      value: allTicked,
                      onChanged: (v) => setState(() {
                        for (final o in rows) {
                          v ? _checked.add(o.id) : _checked.remove(o.id);
                        }
                      }),
                    ),
                    const SizedBox(width: 200),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      color: const Color(0xFF6B6B6B),
                      child: Text(
                        'Total Orders: ${shown.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _SmallButton(
                      child: const SvgIcon(
                        AppIcons.arrowBackRounded,
                        size: 18,
                        color: Colors.black,
                      ),
                      onTap: () => _moveDay(-1),
                    ),
                    Material(
                      color: const Color(0xFF1E5FC4),
                      child: InkWell(
                        onTap: _pickDay,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 11,
                          ),
                          child: Text(
                            DateFormat('dd/MM/yy').format(_day),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _SmallButton(
                      child: const SvgIcon(
                        AppIcons.arrowForwardRounded,
                        size: 18,
                        color: Colors.black,
                      ),
                      onTap: () => _moveDay(1),
                    ),
                    const SizedBox(width: 100),
                    Material(
                      color: const Color(0xFF2C73B8),
                      elevation: 2,
                      borderRadius: BorderRadius.circular(3),
                      child: InkWell(
                        onTap: () => _print(picked),
                        child: const SizedBox(
                          width: 110,
                          height: 52,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(width: 30),
                    _PageBtn(
                      '‹',
                      page > 0 ? () => setState(() => _page = page - 1) : null,
                    ),
                    Container(
                      width: 30,
                      height: 34,
                      color: const Color(0xFF1E7BC6),
                      alignment: Alignment.center,
                      child: Text(
                        '${page + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _PageBtn(
                      '›',
                      page < pages - 1
                          ? () => setState(() => _page = page + 1)
                          : null,
                    ),
                    const Spacer(),
                    Material(
                      color: Colors.white,
                      elevation: 2,
                      child: InkWell(
                        onTap: () => setState(() => _filterOpen = true),
                        child: SizedBox(
                          width: 74,
                          height: 40,
                          child: Center(
                            child: Badge(
                              isLabelVisible:
                                  _payFilter.length +
                                      _typeFilter.length +
                                      _statusFilter.length >
                                  0,
                              child: const SvgIcon(
                                AppIcons.tuneRounded,
                                size: 22,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: _bg,
                  child: state.loading && state.orders.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : rows.isEmpty
                      ? const Center(
                          child: Text(
                            'No orders',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        )
                      : ListView(
                          children: [
                            for (final o in rows)
                              _OrderRow(
                                order: o,
                                checked: _checked.contains(o.id),
                                onChecked: (v) => setState(
                                  () => v
                                      ? _checked.add(o.id)
                                      : _checked.remove(o.id),
                                ),
                                onTap: () => _notifier.select(o),
                              ),
                          ],
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                child: Row(
                  children: [
                    const TimeBox(),
                    const SizedBox(width: 10),
                    _BarButton(
                      label: 'Back',
                      icon: AppIcons.arrowBackRounded,
                      color: Colors.black,
                      onTap: widget.onBack,
                    ),
                    const SizedBox(width: 140),
                    _BarButton(
                      label: 'Delete',
                      icon: AppIcons.deleteOutlineRounded,
                      color: const Color(0xFFD9534F),
                      width: 100,
                      onTap: () => _delete(picked),
                    ),
                    const Spacer(),
                    _BarButton(
                      label: 'Complete',
                      icon: AppIcons.checkRounded,
                      color: const Color(0xFF38C73A),
                      width: 160,
                      onTap: () {
                        if (picked.isEmpty)
                          return _snack('Tick an order first');
                        _setStatus(picked, 'completed');
                      },
                    ),
                    const SizedBox(width: 6),
                    _BarButton(
                      label: 'Status',
                      icon: AppIcons.tuneRounded,
                      color: const Color(0xFF5BC0DE),
                      width: 160,
                      onTap: () => _chooseStatus(picked),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_filterOpen)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 480,
            child: _FilterPanel(
              pay: _payFilter,
              type: _typeFilter,
              status: _statusFilter,
              onChanged: () => setState(() => _page = 0),
              onClose: () => setState(() => _filterOpen = false),
            ),
          ),
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  final OrderModel order;
  final bool checked;
  final ValueChanged<bool> onChecked;
  final VoidCallback onTap;
  const _OrderRow({
    required this.order,
    required this.checked,
    required this.onChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final paid = order.paymentStatus == 'Paid';
    final at = order.createdAt.toLocal();
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 88,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
          ),
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Row(
            children: [
              _Tick(value: checked, onChanged: onChecked),
              const SizedBox(width: 48),
              Container(
                width: 100,
                height: 82,
                color: _typeColor(order.orderType),
                padding: const EdgeInsets.all(6),
                child: Stack(
                  children: [
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Text(
                        _typeLabel(order.orderType),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 4,
                      child: SvgIcon(
                        _typeIcon(order.orderType),
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 190,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '#${order.orderNumber}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 176,
                      color: _statusColor(order.status),
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _statusLabel(order.status),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 120),
              Container(
                width: 50,
                height: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${order.items.length}',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              const Spacer(),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('hh:mm a').format(at),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd-MM-yyyy').format(at),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 110,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      formatMoney(order.total),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.paymentMethod,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 120),
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  color: paid
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFD9534F),
                  child: Text(
                    paid ? 'Paid' : order.paymentStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slide-in checkbox panel for payment, order type and status.
class _FilterPanel extends StatefulWidget {
  final Set<String> pay;
  final Set<String> type;
  final Set<String> status;
  final VoidCallback onChanged;
  final VoidCallback onClose;
  const _FilterPanel({
    required this.pay,
    required this.type,
    required this.status,
    required this.onChanged,
    required this.onClose,
  });

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  Widget group(List<(String, String)> items, Set<String> set) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final (key, label) in items)
        SizedBox(
          width: 225,
          height: 66,
          child: Material(
            color: Colors.white,
            elevation: 2,
            child: InkWell(
              onTap: () {
                setState(
                  () => set.contains(key) ? set.remove(key) : set.add(key),
                );
                widget.onChanged();
              },
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  _Tick(
                    value: set.contains(key),
                    onChanged: (_) {
                      setState(
                        () =>
                            set.contains(key) ? set.remove(key) : set.add(key),
                      );
                      widget.onChanged();
                    },
                  ),
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 8,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 60, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  group(const [
                    ('cash', 'Cash'),
                    ('card', 'Card payment'),
                    ('cash_due', 'Cash Due'),
                    ('online', 'Paid Online'),
                  ], widget.pay),
                  const SizedBox(height: 36),
                  group(const [
                    ('Takeaway', 'Collection'),
                    ('Dine-in', 'Dine'),
                    ('Delivery', 'Home Delivery'),
                  ], widget.type),
                  const SizedBox(height: 36),
                  group([
                    for (final s in _statusOptions) (s.$1, s.$2),
                  ], widget.status),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: widget.onClose,
              icon: const SvgIcon(
                AppIcons.closeRounded,
                size: 18,
                color: Colors.black,
              ),
              label: const Text(
                'Close',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── One order ─────────────────────────────────────────────────────────────────

class _OrderDetail extends ConsumerWidget {
  final OrderModel order;
  final OrderNotifier notifier;
  final VoidCallback onBack;
  const _OrderDetail({
    required this.order,
    required this.notifier,
    required this.onBack,
  });

  Future<void> _comment(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: order.notes);
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Comment'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: ctrl,
            minLines: 3,
            maxLines: 5,
            autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (text == null) return;
    try {
      await ref.read(orderDatasourceProvider).updateNotes(order.id, text);
      await notifier.load(silent: true);
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final at = order.createdAt.toLocal();
    final paid = order.paymentStatus == 'Paid';
    final lines = [
      if (order.customerName.isNotEmpty) order.customerName,
      if (order.customerPhone.isNotEmpty) order.customerPhone,
      if (order.tableNumber.isNotEmpty) 'Table ${order.tableNumber}',
      if (order.notes.isNotEmpty) order.notes,
    ];

    return Container(
      color: _barBg,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 340,
                    child: Column(
                      children: [
                        _Box(
                          header: Row(
                            children: [
                              Text(
                                '# ${order.orderNumber}',
                                style: const TextStyle(fontSize: 15),
                              ),
                              const Spacer(),
                              Text(
                                DateFormat('yyyy-MM-dd HH:mm:ss').format(at),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          height: 190,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              lines.join('\n'),
                              style: const TextStyle(fontSize: 13, height: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _Box(
                          header: Text(
                            order.paymentMethod,
                            style: const TextStyle(fontSize: 15),
                          ),
                          height: 190,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  paid ? 'Paid' : order.paymentStatus,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: paid
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFB91C1C),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (!paid)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF38C73A),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => notifier
                                        .updatePaymentStatus(order.id, 'Paid'),
                                    child: const Text('Mark as paid'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _Box(
                          header: Row(
                            children: [
                              Column(
                                children: [
                                  SvgIcon(
                                    _typeIcon(order.orderType),
                                    size: 26,
                                    color: _typeColor(order.orderType),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.orderType == 'Dine-in'
                                        ? 'Dine'
                                        : order.orderType,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    DateFormat('hh:mm a').format(at),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd-MM-yyyy').format(at),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          height: 220,
                          child: const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: Container(
                      color: _bg,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                            child: Row(
                              children: [
                                const Text(
                                  'Items',
                                  style: TextStyle(fontSize: 15),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF111827),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${order.items.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  width: 176,
                                  color: _statusColor(order.status),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 1,
                                  ),
                                  child: Text(
                                    _statusLabel(order.status),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: ListView(
                                children: [
                                  for (final i in order.items) _ItemLine(i),
                                  const Divider(height: 24),
                                  _Sum('Sub Total', order.subtotal),
                                  if (order.discountAmt > 0)
                                    _Sum('Discount', -order.discountAmt),
                                  if (order.taxAmt > 0)
                                    _Sum('Tax', order.taxAmt),
                                  if (order.deliveryFee > 0)
                                    _Sum('Delivery', order.deliveryFee),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 60),
                                Text(
                                  formatMoney(order.total),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: Container(
                      color: _bg,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Expanded(
                            child: _Box(
                              header: const Text(
                                'History',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: ListView(
                                padding: const EdgeInsets.all(12),
                                children: [
                                  Text(
                                    '${DateFormat('dd-MM-yyyy hh:mm a').format(at)}  ·  Ordered',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Payment: ${order.paymentMethod}, ${order.paymentStatus}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Now: ${_statusLabel(order.status)}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          PopupMenuButton<String>(
                            onSelected: (s) =>
                                notifier.updateStatus(order.id, s),
                            itemBuilder: (_) => [
                              for (final s in _statusOptions)
                                PopupMenuItem(value: s.$1, child: Text(s.$2)),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              color: _statusColor(order.status),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _statusLabel(order.status),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  const Icon(
                                    Icons.arrow_drop_up,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: Row(
              children: [
                const TimeBox(),
                const SizedBox(width: 10),
                _BarButton(
                  label: 'BACK',
                  icon: AppIcons.arrowBackRounded,
                  color: Colors.black,
                  onTap: onBack,
                ),
                const SizedBox(width: 6),
                _BarButton(
                  label: 'COMMENT',
                  icon: AppIcons.stickyNote2Rounded,
                  color: Colors.white,
                  dark: true,
                  onTap: () => _comment(context, ref),
                ),
                const SizedBox(width: 6),
                _BarButton(
                  label: 'PRINT',
                  icon: AppIcons.printRounded,
                  color: const Color(0xFFFF7A00),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => ReceiptPrintDialog(order: order),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final Widget header;
  final Widget child;
  final double? height;
  const _Box({required this.header, required this.child, this.height});

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    color: _bg,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: header,
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: Colors.white,
            child: child,
          ),
        ),
        const SizedBox(height: 4),
      ],
    ),
  );
}

class _ItemLine extends StatelessWidget {
  final OrderItemModel item;
  const _ItemLine(this.item);

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFF2C73B8), width: 3)),
    ),
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(
                item.itemName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${item.qty}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                formatMoney(item.totalPrice),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        if (item.size.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 4),
            child: Text(item.size, style: const TextStyle(fontSize: 12)),
          ),
      ],
    ),
  );
}

class _Sum extends StatelessWidget {
  final String label;
  final double value;
  const _Sum(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 3),
    child: Row(
      children: [
        Expanded(
          flex: 5,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
        ),
        const Expanded(flex: 2, child: SizedBox.shrink()),
        Expanded(
          flex: 2,
          child: Text(formatMoney(value), style: const TextStyle(fontSize: 14)),
        ),
      ],
    ),
  );
}

class _Tick extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Tick({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onChanged(!value),
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFBBBBBB)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: value
          ? const Icon(Icons.check, size: 20, color: Color(0xFF1E5FC4))
          : null,
    ),
  );
}

class _SmallButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _SmallButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: Border.all(color: const Color(0xFFDDDDDD)),
    child: InkWell(
      onTap: onTap,
      child: SizedBox(width: 56, height: 40, child: Center(child: child)),
    ),
  );
}

class _PageBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PageBtn(this.label, this.onTap);

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      width: 30,
      height: 34,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            color: onTap == null ? Colors.black26 : const Color(0xFF1E7BC6),
          ),
        ),
      ),
    ),
  );
}

class _BarButton extends StatelessWidget {
  final String label;
  final AppIcon icon;
  final Color color;
  final double width;
  final bool dark;
  final VoidCallback onTap;
  const _BarButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.width = 150,
    this.dark = false,
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
            SvgIcon(
              icon,
              size: 26,
              color: dark ? Colors.black87 : Colors.white,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: dark ? Colors.black87 : Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
