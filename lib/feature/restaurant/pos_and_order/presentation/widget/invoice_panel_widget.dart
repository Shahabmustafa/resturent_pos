import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/constants/currency.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import '../../data/model/order_model.dart';
import '../provider/pos_provider.dart';
import '../screen/adhoc_screen.dart';
import 'till_dialog.dart';
import 'package:resturent_application/feature/restaurant/customer_lookup/presentation/collection_flow.dart';

const _navy = Color(0xFF22337A);
const _selected = Color(0xFF2346B8);
const _text = Color(0xFF1F2A44);
const _muted = Color(0xFF6B7280);

const _orderTypes = [
  ('Dine-in', 'DINE IN'),
  ('Takeaway', 'COLLECTION'),
  ('Delivery', 'DELIVERY'),
];

String _typeLabel(String type) => _orderTypes
    .firstWhere((t) => t.$1 == type, orElse: () => (type, type.toUpperCase()))
    .$2;

/// "6:23 AM" for a picked HH:mm time, or the current time when none is picked (as soon as possible).
String _timeLabel(String hhmm) {
  final p = hhmm.split(':');
  final t = p.length == 2
      ? DateTime(2000, 1, 1, int.parse(p[0]), int.parse(p[1]))
      : DateTime.now();
  return DateFormat('h:mm a').format(t);
}

String _money(double v) => formatMoney(v).replaceAll('£', '');

/// Sale invoice in the style of a touch till: lines, totals, item and order
/// action buttons, and SAVE / PAY.
class InvoicePanelWidget extends ConsumerStatefulWidget {
  /// Places the order as unpaid.
  final VoidCallback onSave;

  /// Places the order as paid with [PosState.paymentMethod].
  final VoidCallback onPay;

  /// Void: drop this sale and go back to the home screen.
  final VoidCallback? onVoid;

  const InvoicePanelWidget({
    super.key,
    required this.onSave,
    required this.onPay,
    this.onVoid,
  });

  @override
  ConsumerState<InvoicePanelWidget> createState() => _InvoicePanelState();
}

class _InvoicePanelState extends ConsumerState<InvoicePanelWidget> {
  final _menuKey = GlobalKey();

  int _selectedLine = -1;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(posProvider);
    final n = ref.read(posProvider.notifier);
    if (s.cart.isEmpty) {
      _selectedLine = -1;
    } else if (_selectedLine >= s.cart.length || _selectedLine < 0) {
      _selectedLine = s.cart.length - 1; // newest line
    }
    final line = _selectedLine >= 0 ? s.cart[_selectedLine] : null;

    return Container(
      color: const Color(0xFFF4F7FB),
      child: Column(
        children: [
          _header(s, n),
          _customerStrip(s),
          Expanded(child: _lines(s)),
          _totals(s),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    _ActionKey(
                      icon: AppIcons.editRounded,
                      color: const Color(0xFF2F80ED),
                      onTap: line == null ? null : () => _editQty(line),
                    ),
                    _ActionKey(
                      icon: AppIcons.removeRounded,
                      color: const Color(0xFFF0A040),
                      onTap: line == null ? null : () => n.changeQty(line, -1),
                    ),
                    _ActionKey(
                      icon: AppIcons.addRounded,
                      color: const Color(0xFF6BBF59),
                      onTap: line == null ? null : () => n.changeQty(line, 1),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _ActionKey(
                      label: 'DISCOUNT',
                      icon: AppIcons.localOfferRounded,
                      color: const Color(0xFF3E5A8A),
                      onTap: () => _discount(s),
                    ),
                    _ActionKey(
                      label: 'COMMENTS',
                      icon: AppIcons.stickyNote2Rounded,
                      color: const Color(0xFFC0574A),
                      onTap: () => _comments(s),
                    ),
                    _ActionKey(
                      label: 'DELETE',
                      icon: AppIcons.deleteOutlineRounded,
                      color: const Color(0xFFC04A6A),
                      onTap: line == null ? null : () => n.removeFromCart(line),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (s.orderType == 'Dine-in')
                      _ActionKey(
                        label: s.selectedTable.isEmpty
                            ? 'TABLE'
                            : 'TABLE ${s.selectedTable}',
                        icon: AppIcons.tableRestaurantRounded,
                        color: const Color(0xFF5B8DB8),
                        onTap: () => _pickTable(s),
                      )
                    else if (s.orderType == 'Delivery')
                      _ActionKey(
                        label: 'ADDRESS',
                        icon: AppIcons.locationOnOutlined,
                        color: const Color(0xFF5B8DB8),
                        onTap: () => _delivery(s),
                      )
                    else
                      _ActionKey(
                        label: 'CUSTOMER',
                        icon: AppIcons.personRounded,
                        color: const Color(0xFF5B8DB8),
                        onTap: () => _startLookup(s.orderType, edit: true),
                      ),
                    // Delivery / collection orders show the requested time here; dine-in keeps the payment method.
                    if (s.orderType == 'Dine-in')
                      _ActionKey(
                        label: s.paymentMethod.toUpperCase(),
                        icon: AppIcons.paymentsRounded,
                        color: const Color(0xFF3AA6A0),
                        onTap: () => _paymentMethod(s),
                      )
                    else
                      _ActionKey(
                        label: _timeLabel(s.deliveryTime),
                        icon: AppIcons.accessTimeRounded,
                        color: const Color(0xFF00A676),
                        onTap: () => _pickTime(s),
                      ),
                    _ActionKey(
                      label: 'CLEAR',
                      icon: AppIcons.refreshRounded,
                      color: const Color(0xFF8A94A6),
                      onTap: s.cart.isEmpty ? null : () => _clear(),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _ActionKey(
                      label: 'ADHOC',
                      icon: AppIcons.stickyNote2Rounded,
                      color: const Color(0xFF6A3FB5),
                      onTap: _adhoc,
                    ),
                    const Expanded(child: SizedBox()),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
            child: Row(
              children: [
                _BigKey(
                  label: 'SAVE',
                  icon: AppIcons.receiptLongRounded,
                  color: const Color(0xFFE2B33C),
                  onTap: s.cart.isEmpty ? null : widget.onSave,
                ),
                const SizedBox(width: 8),
                _BigKey(
                  label: 'PAY ${_money(s.total)}',
                  icon: AppIcons.paymentRounded,
                  color: const Color(0xFF5DBB63),
                  onTap: s.cart.isEmpty ? null : widget.onPay,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sections ────────────────────────────────────────────────────────────────

  Widget _header(PosState s, PosNotifier n) => Container(
    height: 50,
    color: _navy,
    child: Row(
      children: [
        _HeaderButton(
          key: _menuKey,
          icon: AppIcons.menuRounded,
          width: 64,
          onTap: () => _openMenu(s),
        ),
        Expanded(
          child: InkWell(
            onTap: () => _changeType(s),
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border.symmetric(
                  vertical: BorderSide(color: Colors.white24),
                ),
              ),
              child: Text(
                s.isShop ? 'SHOP' : _typeLabel(s.orderType),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
        if (s.orderType == 'Dine-in')
          _TableHeaderButton(table: s.selectedTable, onTap: () => _pickTable(s))
        else
          SizedBox(
            width: 64,
            child: Center(
              child: Text(
                '${s.cart.fold<int>(0, (a, c) => a + c.qty)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _customerStrip(PosState s) {
    final name = s.customerName.trim();
    final phone = s.customerPhone.trim();
    final extra = s.orderType == 'Dine-in' && s.selectedTable.isNotEmpty
        ? 'TABLE ${s.selectedTable}'
        : s.orderType == 'Delivery' && s.deliveryAddress.trim().isNotEmpty
        ? s.deliveryAddress.trim()
        : '';
    return InkWell(
      onTap: () => _startLookup(s.orderType, edit: true),
      child: Container(
        width: double.infinity,
        color: const Color(0xFF8FE3C8),
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        child: Column(
          children: [
            Text(
              name.isEmpty ? 'WALK-IN' : name.toUpperCase(),
              style: const TextStyle(
                color: _text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (phone.isNotEmpty || extra.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      extra,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _text, fontSize: 12),
                    ),
                  ),
                  Text(
                    phone,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _lines(PosState s) {
    if (s.cart.isEmpty) {
      return const Center(
        child: Text(
          'Tap a menu item to add it',
          style: TextStyle(color: _muted),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: s.cart.length,
      itemBuilder: (_, i) {
        final item = s.cart[i];
        final sel = i == _selectedLine;
        final fg = sel ? Colors.white : _text;
        return InkWell(
          onTap: () => setState(() => _selectedLine = i),
          child: Container(
            color: sel ? _selected : Colors.white,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            margin: const EdgeInsets.only(bottom: 1),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name.toUpperCase(),
                        style: TextStyle(
                          color: fg,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 30,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F6),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '${item.qty}',
                        style: const TextStyle(
                          color: _text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        _money(item.total),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: fg,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.size != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 2),
                    child: Row(
                      children: [
                        Text(
                          'SIZE ${item.size!.name.toUpperCase()}',
                          style: TextStyle(
                            color: sel ? Colors.white70 : _muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '@ ${_money(item.unitPrice)}',
                          style: TextStyle(
                            color: sel ? Colors.white70 : _muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _totals(PosState s) {
    Widget row(String label, String value, {bool big = false}) => Container(
      padding: EdgeInsets.fromLTRB(16, big ? 10 : 7, 12, big ? 10 : 7),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: _text,
              fontSize: big ? 15 : 13,
              fontWeight: big ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: _text,
              fontSize: big ? 20 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          row('SUB TOTAL', _money(s.subtotal)),
          if (s.discountAmt > 0) row('DISCOUNT', '-${_money(s.discountAmt)}'),
          if (s.taxRate > 0)
            row('TAX (${s.taxRate.toStringAsFixed(1)}%)', _money(s.tax)),
          if (s.fee > 0) row('DELIVERY', _money(s.fee)),
          if (s.orderNotes.trim().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
              child: Text(
                'NOTE: ${s.orderNotes.trim()}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFC0574A), fontSize: 12),
              ),
            ),
          row('TOTAL', _money(s.total), big: true),
        ],
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  PosNotifier get _n => ref.read(posProvider.notifier);

  /// Drop-down under the header's menu button: void, edit customer and the order types.
  Future<void> _openMenu(PosState s) async {
    final box = _menuKey.currentContext!.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero);
    final action = await showDialog<String>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Stack(
        children: [
          Positioned(
            left: origin.dx,
            top: origin.dy + box.size.height,
            width: 270,
            child: Material(
              color: Colors.white,
              elevation: 10,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MenuAction(
                      'Void',
                      AppIcons.deleteOutlineRounded,
                      const Color(0xFFE5321A),
                      () => Navigator.pop(ctx, 'void'),
                    ),
                    _MenuAction(
                      'Edit Customer',
                      AppIcons.personRounded,
                      const Color(0xFF0096A8),
                      () => Navigator.pop(ctx, 'customer'),
                    ),
                    const SizedBox(height: 22),
                    _MenuAction(
                      'DINE',
                      AppIcons.restaurantRounded,
                      const Color(0xFF2368D6),
                      () => Navigator.pop(ctx, 'Dine-in'),
                    ),
                    _MenuAction(
                      'COLLECTION',
                      AppIcons.shoppingBagRounded,
                      const Color(0xFFC9168A),
                      () => Navigator.pop(ctx, 'Takeaway'),
                    ),
                    _MenuAction(
                      'DELIVERY',
                      AppIcons.localShippingRounded,
                      const Color(0xFFFF7A00),
                      () => Navigator.pop(ctx, 'Delivery'),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.black,
                        ),
                        label: const Text(
                          'Close',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: const RoundedRectangleBorder(),
                          side: const BorderSide(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'void':
        await _void();
      case 'customer':
        await _startLookup(s.orderType, edit: true);
      default:
        await _startLookup(action);
    }
  }

  Future<void> _changeType(PosState s) async {
    final type = await showTillChoice<String>(context, 'Order type', [
      for (final t in _orderTypes) (t.$1, t.$2),
    ], current: s.orderType);
    if (type != null && type != s.orderType) _n.setOrderType(type);
  }

  Future<void> _pickTime(PosState s) async {
    String hhmm(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final title = s.orderType == 'Delivery'
        ? 'DELIVERY TIME'
        : 'COLLECTION TIME';
    // '' = as soon as possible; otherwise an HH:mm time.
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
        child: SizedBox(
          width: 560,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    border: Border.all(color: const Color(0xFFE3E3E3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 20, color: _text),
                      ),
                      Text(
                        DateFormat('h:mm a').format(now),
                        style: const TextStyle(fontSize: 20, color: _text),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TimeChip(
                      'ASAP',
                      const Color(0xFF00A676),
                      72,
                      44,
                      () => Navigator.pop(ctx, ''),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (label, mins) in const [
                            ('+15 Mins', 15),
                            ('+30 Mins', 30),
                            ('+45 Mins', 45),
                            ('+1 Hrs', 60),
                            ('+1.5 Hrs', 90),
                            ('+2 Hrs', 120),
                            ('+2.5 Hrs', 150),
                            ('+3 Hrs', 180),
                          ])
                            _TimeChip(
                              label,
                              const Color(0xFFF0AD4E),
                              96,
                              44,
                              () => Navigator.pop(
                                ctx,
                                hhmm(now.add(Duration(minutes: mins))),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(now),
                      helpText: title,
                      builder: (c, child) => MediaQuery(
                        data: MediaQuery.of(
                          c,
                        ).copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      ),
                    );
                    if (t != null && ctx.mounted) {
                      Navigator.pop(
                        ctx,
                        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(56, 44),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(3)),
                    ),
                    side: const BorderSide(color: Color(0xFFD1D9E2)),
                  ),
                  child: const Icon(
                    Icons.dialpad_rounded,
                    color: _text,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (picked != null) _n.setDeliveryTime(picked);
  }

  Future<void> _paymentMethod(PosState s) async {
    final m = await showTillChoice<String>(context, 'Payment method', const [
      ('Cash', 'CASH'),
      ('Card', 'CARD'),
      ('Online', 'ONLINE'),
    ], current: s.paymentMethod);
    if (m != null) _n.setPaymentMethod(m);
  }

  Future<void> _pickTable(PosState s) async {
    if (s.tables.isEmpty) {
      _snack('No available tables');
      return;
    }
    final t = await showDialog<String>(
      context: context,
      builder: (_) => _TableGridDialog(
        tables: [for (final t in s.tables) t.tableNumber],
        current: s.selectedTable,
      ),
    );
    if (t != null) _n.setTable(t);
  }

  Future<void> _editQty(CartItem line) async {
    final qty = await showTillNumberPad(
      context,
      'Quantity — ${line.product.name}',
      initial: '${line.qty}',
      decimal: false,
    );
    if (qty == null) return;
    final target = qty.round();
    if (target <= 0) {
      _n.removeFromCart(line);
    } else if (target != line.qty) {
      _n.changeQty(line, target - line.qty);
    }
  }

  Future<void> _discount(PosState s) async {
    final kind = await showTillChoice<String>(context, 'Discount', [
      ('pct', '% DISCOUNT'),
      ('flat', '£ OFF'),
      if (s.discountAmt > 0) ('none', 'REMOVE DISCOUNT'),
    ]);
    if (kind == null || !mounted) return;
    if (kind == 'none') {
      _n.setDiscountPct(0);
      _n.setDiscountFlat(0);
      return;
    }
    final pct = kind == 'pct';
    final v = await showTillNumberPad(
      context,
      pct ? 'Discount %' : 'Discount £',
      initial: pct
          ? (s.discountPct > 0 ? '${s.discountPct}' : '')
          : (s.discountFlat > 0 ? '${s.discountFlat}' : ''),
    );
    if (v == null) return;
    // One kind of discount at a time, like the till's DISCOUNT key.
    _n.setDiscountPct(pct ? v.clamp(0, 100).toDouble() : 0);
    _n.setDiscountFlat(pct ? 0 : v);
  }

  /// One-off item that is not on the menu: a name and a price.
  Future<void> _adhoc() async {
    final item = await Navigator.of(context).push<(String, double)>(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: SafeArea(child: AdhocScreen())),
      ),
    );
    if (item != null) _n.addAdhoc(item.$1, item.$2);
  }

  Future<void> _comments(PosState s) async {
    final c = TextEditingController(text: s.orderNotes);
    if (await showTillForm(context, 'Comments', [
      _dialogField(c, 'Kitchen / order notes', lines: 4, autofocus: true),
    ])) {
      _n.setNotes(c.text);
    }
  }

  /// Opens the phone / postcode / street / customer lookup for the chosen sale type.
  Future<void> _startLookup(String type, {bool edit = false}) async {
    final nav = Navigator.of(context);
    final shop = edit && ref.read(posProvider).isShop;
    // Editing keeps the sale type (and the SHOP label) it already has.
    void apply() {
      if (!edit) _n.setOrderType(type);
    }

    await nav.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: SafeArea(
            child: CollectionFlow(
              saleLabel: shop ? 'SHOP' : _typeLabel(type),
              onBack: nav.pop,
              // Change popup: switch the sale type; Collection and Delivery ask for the customer.
              onStartSale: (t) {
                nav.pop();
                if (t == 'Collection') {
                  _startLookup('Takeaway');
                } else if (t == 'Delivery') {
                  _startLookup('Delivery');
                } else {
                  _n.setOrderType(t, shop: t == 'Takeaway');
                }
              },
              onSkip: () {
                nav.pop();
                apply();
              },
              onConfirm: (id) async {
                nav.pop();
                apply();
                await _n.useCustomer(id);
              },
              onDelivery: type == 'Delivery'
                  ? (id, charge, address) async {
                      nav.pop();
                      apply();
                      _n.setDeliveryCharge(charge);
                      _n.setDeliveryAddress(address);
                      await _n.useCustomer(id);
                    }
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delivery(PosState s) async {
    final address = TextEditingController(text: s.deliveryAddress);
    String? rider = s.selectedRiderId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => TillDialog(
          title: 'Delivery',
          width: 560,
          actions: [
            TillButton.cancel(onTap: () => Navigator.pop(ctx, false)),
            TillButton.ok(onTap: () => Navigator.pop(ctx, true)),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogField(
                address,
                'Delivery address',
                lines: 3,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'RIDER',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (s.availableRiders.isEmpty)
                const Text(
                  'No riders available',
                  style: TextStyle(color: _muted),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final r in s.availableRiders)
                      SizedBox(
                        width: 160,
                        child: TillButton(
                          label: r.name.toUpperCase(),
                          icon: AppIcons.deliveryDiningRounded,
                          color: rider == r.id ? _selected : Colors.white,
                          textColor: rider == r.id ? Colors.white : _text,
                          onTap: () => setD(() => rider = r.id),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      _n.setDeliveryAddress(address.text.trim());
      _n.setRider(rider);
    }
  }

  Future<void> _void() async {
    if (ref.read(posProvider).cart.isNotEmpty) {
      final ok = await showTillConfirm(
        context,
        'Void order',
        const Text('This sale will be cancelled and all items removed.'),
        okLabel: 'VOID',
      );
      if (!ok) return;
    }
    _n.clearCart();
    widget.onVoid?.call();
  }

  Future<void> _clear() async {
    final ok = await showTillConfirm(
      context,
      'Clear order',
      const Text('All items on this invoice will be removed.'),
      okLabel: 'CLEAR',
    );
    if (!ok) return;
    // Keep the order type (and its customer) that this sale was started with.
    final s = ref.read(posProvider);
    final type = s.orderType;
    final customer = s.selectedCustomerId;
    _n.clearCart();
    _n.setOrderType(type);
    if (customer != null) _n.selectCustomer(customer);
  }

  Widget _dialogField(
    TextEditingController c,
    String label, {
    bool phone = false,
    int lines = 1,
    bool autofocus = false,
  }) => TextField(
    controller: c,
    autofocus: autofocus,
    minLines: lines,
    maxLines: lines,
    keyboardType: phone
        ? TextInputType.phone
        : null,
    style: const TextStyle(fontSize: 16),
    decoration: tillFieldDecoration(label),
  );

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

// ── Buttons ───────────────────────────────────────────────────────────────────

/// Small coloured choice button in the delivery time dialog.
class _TimeChip extends StatelessWidget {
  final String label;
  final Color color;
  final double width;
  final double height;
  final VoidCallback onTap;
  const _TimeChip(this.label, this.color, this.width, this.height, this.onTap);

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    elevation: 2,
    borderRadius: BorderRadius.circular(3),
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    ),
  );
}

/// One big coloured row in the header's drop-down menu.
class _MenuAction extends StatelessWidget {
  final String label;
  final AppIcon icon;
  final Color color;
  final VoidCallback onTap;
  const _MenuAction(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: color,
      elevation: 3,
      borderRadius: BorderRadius.circular(3),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              const SizedBox(width: 14),
              SvgIcon(icon, size: 26, color: Colors.white),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    ),
  );
}

class _HeaderButton extends StatelessWidget {
  final AppIcon icon;
  final double width;
  final VoidCallback onTap;
  const _HeaderButton({
    super.key,
    required this.icon,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      width: width,
      child: Center(child: SvgIcon(icon, size: 22, color: Colors.white)),
    ),
  );
}

class _ActionKey extends StatelessWidget {
  final String? label;
  final AppIcon icon;
  final Color color;
  final VoidCallback? onTap;
  const _ActionKey({
    this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: onTap == null ? color.withValues(alpha: 0.45) : color,
        elevation: onTap == null ? 0 : 2,
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          borderRadius: BorderRadius.circular(3),
          onTap: onTap,
          child: SizedBox(
            height: 54,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgIcon(
                  icon,
                  size: label == null ? 24 : 18,
                  color: Colors.white,
                ),
                if (label != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _BigKey extends StatelessWidget {
  final String label;
  final AppIcon icon;
  final Color color;
  final VoidCallback? onTap;
  const _BigKey({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: onTap == null ? color.withValues(alpha: 0.5) : color,
      elevation: onTap == null ? 0 : 3,
      borderRadius: BorderRadius.circular(3),
      child: InkWell(
        borderRadius: BorderRadius.circular(3),
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgIcon(icon, size: 22, color: Colors.white),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Right end of the header on Dine-in: table icon, plus the chosen table number.
class _TableHeaderButton extends StatelessWidget {
  final String table;
  final VoidCallback onTap;
  const _TableHeaderButton({required this.table, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(4),
    child: Material(
      color: const Color(0xFF2370D9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          width: 84,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SvgIcon(
                AppIcons.tableRestaurantRounded,
                size: 20,
                color: Colors.white,
              ),
              if (table.isNotEmpty) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    table,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// White "Select Table" dialog: a grid of table tiles and a green Ok button.
class _TableGridDialog extends StatefulWidget {
  final List<String> tables;
  final String current;
  const _TableGridDialog({required this.tables, required this.current});

  @override
  State<_TableGridDialog> createState() => _TableGridDialogState();
}

class _TableGridDialogState extends State<_TableGridDialog> {
  late String _selected = widget.current;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    insetPadding: const EdgeInsets.all(24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760, maxHeight: 560),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: Column(
              children: [
                const Text(
                  'Select Table',
                  style: TextStyle(fontSize: 20, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in widget.tables)
                          SizedBox(
                            width: 110,
                            height: 52,
                            child: Material(
                              color: t == _selected
                                  ? const Color(0xFFFFD54F)
                                  : Colors.white,
                              elevation: 3,
                              child: InkWell(
                                onTap: () => setState(() => _selected = t),
                                child: Center(
                                  child: Text(
                                    t,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                ),
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
          Positioned(
            right: 12,
            bottom: 12,
            child: SizedBox(
              width: 72,
              height: 62,
              child: Material(
                color: const Color(0xFF5CB85C),
                elevation: 3,
                child: InkWell(
                  onTap: () => Navigator.pop(
                    context,
                    _selected.isEmpty ? null : _selected,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, color: Colors.white, size: 30),
                      Text(
                        'Ok',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
