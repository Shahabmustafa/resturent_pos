import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:resturent_application/core/widget/hard_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/constants/currency.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import '../../data/model/order_model.dart';
import '../provider/pos_provider.dart';
import '../screen/adhoc_screen.dart';
import 'till_dialog.dart';
import 'package:resturent_application/feature/restaurant/customer_lookup/presentation/collection_flow.dart';

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

  /// Prints the invoice of the current sale.
  final VoidCallback? onPrint;

  /// Void: drop this sale and go back to the home screen.
  final VoidCallback? onVoid;

  const InvoicePanelWidget({
    super.key,
    required this.onSave,
    required this.onPay,
    this.onPrint,
    this.onVoid,
  });

  @override
  ConsumerState<InvoicePanelWidget> createState() => InvoicePanelState();
}

class InvoicePanelState extends ConsumerState<InvoicePanelWidget> {
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

    const grey = Color(0xFFD0D0CC);
    const greyFg = Color(0xFF555555);
    return Container(
      color: const Color(0xFFFFFFF8),
      child: Column(
        children: [
          _customerStrip(s),
          Expanded(child: _lines(s)),
          _totals(s),
          Container(
            color: const Color(0xFFD3D3D3),
            padding: const EdgeInsets.fromLTRB(5, 8, 5, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    _ActionKey(
                      icon: AppIcons.editRounded,
                      color: line == null ? grey : const Color(0xFF2B6FD6),
                      fg: line == null ? greyFg : Colors.white,
                      onTap: line == null ? null : () => _editQty(line),
                    ),
                    _ActionKey(
                      icon: AppIcons.removeRounded,
                      color: line == null ? grey : const Color(0xFFFF7A00),
                      fg: line == null ? greyFg : Colors.white,
                      onTap: line == null ? null : () => n.changeQty(line, -1),
                    ),
                    _ActionKey(
                      icon: AppIcons.addRounded,
                      color: line == null ? grey : const Color(0xFF3DBB16),
                      fg: line == null ? greyFg : Colors.white,
                      onTap: line == null ? null : () => n.changeQty(line, 1),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _ActionKey(
                      label: 'DISCOUNT',
                      icon: AppIcons.sentimentSatisfied,
                      color: const Color(0xFF2D4B48),
                      onTap: () => _discount(s),
                    ),
                    _ActionKey(
                      label: 'COMMENTS',
                      icon: AppIcons.chatFilled,
                      color: const Color(0xFFE32D0E),
                      onTap: () => _comments(s),
                    ),
                    _ActionKey(
                      label: 'ADHOC',
                      icon: AppIcons.spellcheck,
                      color: const Color(0xFFD32F32),
                      onTap: _adhoc,
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (s.orderType == 'Delivery')
                      _ActionKey(
                        label: 'ADDRESS',
                        icon: AppIcons.locationOnOutlined,
                        color: grey,
                        fg: greyFg,
                        onTap: () => _delivery(s),
                      )
                    else if (s.orderType == 'Dine-in')
                      _ActionKey(
                        label: s.paymentMethod.toUpperCase(),
                        icon: AppIcons.paymentsRounded,
                        color: grey,
                        fg: greyFg,
                        onTap: () => _paymentMethod(s),
                      )
                    else
                      _ActionKey(
                        label: 'CUSTOMER',
                        icon: AppIcons.personRounded,
                        color: grey,
                        fg: greyFg,
                        onTap: () => _startLookup(s.orderType, edit: true),
                      ),
                    if (s.orderType == 'Dine-in')
                      const Expanded(child: SizedBox())
                    else
                      _ActionKey(
                        label: _timeLabel(s.deliveryTime),
                        icon: AppIcons.accessTimeRounded,
                        color: const Color(0xFF02A67B),
                        onTap: () => _pickTime(s),
                      ),
                    _ActionKey(
                      label: 'PRINT/HOLD',
                      icon: AppIcons.printRounded,
                      color: const Color(0xFF55BFE0),
                      onTap: s.cart.isEmpty ? null : widget.onPrint,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 6, 0, 9),
                  child: Row(
                    children: [
                      // Back leaves the till; once items are added it becomes Hold.
                      if (s.cart.isEmpty)
                        _BigKey(
                          label: 'Back',
                          icon: AppIcons.arrowBackRounded,
                          color: Colors.black,
                          onTap: _void,
                        )
                      else
                        _BigKey(
                          label: 'Hold',
                          icon: AppIcons.receiptLongRounded,
                          color: const Color(0xFFFF7200),
                          onTap: _hold,
                        ),
                      const SizedBox(width: 12),
                      _BigKey(
                        label: 'Payments',
                        icon: AppIcons.paymentRounded,
                        color: const Color(0xFF3DBB16),
                        onTap: s.cart.isEmpty ? null : widget.onPay,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sections ────────────────────────────────────────────────────────────────

  Widget _customerStrip(PosState s) {
    final name = s.customerName.trim();
    final phone = s.customerPhone.trim();
    final extra =
        s.orderType == 'Delivery' && s.deliveryAddress.trim().isNotEmpty
        ? s.deliveryAddress.trim()
        : '';
    final title = phone.isNotEmpty
        ? phone
        : (name.isEmpty ? 'WALK-IN' : name.toUpperCase());
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          // Hamburger: opens the list (held sales, save, clear, void, order types).
          Builder(
            builder: (btnCtx) => InkWell(
              onTap: () => openMenu(btnCtx),
              child: Container(
                width: 60,
                color: const Color(0xFF2B6FD6),
                alignment: Alignment.center,
                child: const Icon(Icons.menu, color: Colors.white, size: 26),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _startLookup(s.orderType, edit: true),
              child: Container(
                color: phone.isNotEmpty
                    ? const Color(0xFFE32D0E)
                    : const Color(0xFFF1F5EE),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_typeLabel(s.orderType)} · $title',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: phone.isNotEmpty ? Colors.white : _text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (name.isNotEmpty && phone.isNotEmpty || extra.isNotEmpty)
                      Text(
                        extra.isNotEmpty ? extra : name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: phone.isNotEmpty ? Colors.white70 : _text,
                          fontSize: 11,
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
  }

  Widget _lines(PosState s) {
    if (s.cart.isEmpty) {
      return const Center(
        child: SvgIcon(
          AppIcons.shoppingCartOutlined,
          size: 96,
          color: Color(0xFF222222),
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
              fontSize: big ? 17 : 13,
              fontWeight: big ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: _text,
              fontSize: big ? 26 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.fromLTRB(5, 0, 5, 5),
      child: Column(
        children: [
          if (s.discountAmt > 0 || s.taxRate > 0 || s.fee > 0)
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
  Future<void> openMenu(BuildContext anchor) async {
    final s = ref.read(posProvider);
    final box = anchor.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero);
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final opensDown = origin.dy < screenH / 2;
    final maxH =
        (opensDown ? screenH - origin.dy - box.size.height : origin.dy) - 12;
    final action = await showDialog<String>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Stack(
        children: [
          Positioned(
            left: origin.dx.clamp(0.0, screenW - 270),
            // Opens downward from a header button, upward from the bottom bar.
            top: opensDown ? origin.dy + box.size.height : null,
            bottom: opensDown ? null : screenH - origin.dy,
            width: 270,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: Material(
                color: Colors.white,
                elevation: 10,
                borderRadius: BorderRadius.circular(4),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MenuAction(
                        'Held Sales (${ref.read(heldSalesProvider).length})',
                        AppIcons.receiptLongRounded,
                        const Color(0xFFFF7200),
                        () => Navigator.pop(ctx, 'held'),
                      ),
                      _MenuAction(
                        'Save Order',
                        AppIcons.receiptLongRounded,
                        const Color(0xFFE2B33C),
                        () => Navigator.pop(ctx, 'save'),
                      ),
                      _MenuAction(
                        'Clear',
                        AppIcons.refreshRounded,
                        const Color(0xFF8A94A6),
                        () => Navigator.pop(ctx, 'clear'),
                      ),
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
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'held':
        await _recall();
      case 'save':
        if (s.cart.isNotEmpty) widget.onSave();
      case 'clear':
        if (s.cart.isNotEmpty) await _clear();
      case 'void':
        await _void();
      case 'customer':
        await _startLookup(s.orderType, edit: true);
      default:
        await _startLookup(action);
    }
  }

  /// Opens the list of held sales (the till's Hold List button).
  Future<void> openHeldSales() => _recall();

  /// Opens the order comments dialog (the till's Comments button).
  Future<void> openComments() => _comments(ref.read(posProvider));

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

  /// Parks the current sale (not an order) so the till is free for the next one.
  void _hold() {
    final s = ref.read(posProvider);
    if (s.cart.isEmpty) return;
    // Print the invoice slip first (reads the sale before it is cleared).
    widget.onPrint?.call();
    ref.read(heldSalesProvider.notifier).update((l) => [...l, HeldSale(s)]);
    _n.clearCart();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sale on hold')));
  }

  /// Picks a held sale and puts it back on the till.
  Future<void> _recall() async {
    final held = ref.read(heldSalesProvider);
    if (held.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No sales on hold')));
      return;
    }
    if (ref.read(posProvider).cart.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hold or finish the current sale first')),
      );
      return;
    }
    final i = await showTillChoice<int>(context, 'Held sales', [
      for (final (i, h) in held.indexed)
        (
          i,
          '${DateFormat('h:mm a').format(h.heldAt)}\n'
              '${h.sale.customerName.isEmpty ? _typeLabel(h.sale.orderType) : h.sale.customerName.toUpperCase()}\n'
              '${_money(h.sale.total)}',
        ),
    ]);
    if (i == null || !mounted) return;
    final h = held[i];
    ref.read(heldSalesProvider.notifier).update((l) => [...l]..removeAt(i));
    _n.recallSale(h.sale);
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
    keyboardType: phone ? TextInputType.phone : null,
    style: const TextStyle(fontSize: 16),
    decoration: tillFieldDecoration(label),
  );
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
  Widget build(BuildContext context) => HardShadow(
    child: Material(
      color: color,
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
    child: HardShadow(
      child: Material(
        color: color,
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
    ),
  );
}

class _ActionKey extends StatelessWidget {
  final String? label;
  final AppIcon icon;
  final Color color;
  final Color fg;
  final VoidCallback? onTap;
  const _ActionKey({
    this.label,
    required this.icon,
    required this.color,
    this.fg = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: HardShadow(
        offset: 2,
        enabled: onTap != null && color != const Color(0xFFD0D0CC),
        child: Material(
          color: onTap == null ? color.withValues(alpha: 0.6) : color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: color == const Color(0xFFD0D0CC)
                ? const BorderSide(color: Color(0xFFA9A9A5))
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(5),
            onTap: onTap,
            child: SizedBox(
              height: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgIcon(icon, size: label == null ? 22 : 24, color: fg),
                  if (label != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
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
    child: HardShadow(
      enabled: onTap != null,
      child: Material(
        color: onTap == null ? color.withValues(alpha: 0.5) : color,
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          borderRadius: BorderRadius.circular(3),
          onTap: onTap,
          child: SizedBox(
            height: 66,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgIcon(icon, size: 22, color: Colors.white),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
