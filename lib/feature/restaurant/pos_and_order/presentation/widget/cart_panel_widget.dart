import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/model/order_model.dart';
import '../provider/pos_provider.dart';
import 'pos_misc_widgets.dart';
import 'package:resturent_application/core/constants/currency.dart';

class CartPanelWidget extends ConsumerStatefulWidget {
  final VoidCallback  onPlaceOrder;
  final VoidCallback? onBack;
  const CartPanelWidget({super.key, required this.onPlaceOrder, this.onBack});

  @override
  ConsumerState<CartPanelWidget> createState() => _CartPanelState();
}

class _CartPanelState extends ConsumerState<CartPanelWidget> {
  bool _showDiscount = false;
  bool _showNotes    = false;

  static const _orderTypes      = [('Dine-in', AppIcons.restaurantRounded), ('Takeaway', AppIcons.takeoutDiningRounded), ('Delivery', AppIcons.deliveryDiningRounded)];
  static const _paymentMethods  = [('Cash', AppIcons.paymentsRounded), ('Card', AppIcons.creditCardRounded), ('Online', AppIcons.phoneAndroidRounded)];
  static const _paymentStatuses = [('Paid', kGreen), ('Unpaid', kRed), ('Partial', Color(0xFFFFAA00))];

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(posProvider);
    final n = ref.read(posProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
          color: kCard,
          border: Border(left: BorderSide(color: kBorder)),
          boxShadow: [BoxShadow(color: Color(0x08000020), blurRadius: 10, offset: Offset(-3, 0))]),
      child: Column(children: [
        _header(s),
        Expanded(child: s.cart.isEmpty ? const EmptyCartWidget() : _body(s, n)),
        if (s.cart.isNotEmpty) _placeOrderBtn(s),
      ]),
    );
  }

  Widget _header(PosState s) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), color: kText,
    child: Row(children: [
      if (widget.onBack != null)
        GestureDetector(
          onTap: widget.onBack,
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: const SvgIcon(AppIcons.arrowBackRounded, color: Colors.white70, size: 16),
          ),
        ),
      const SvgIcon(AppIcons.shoppingCartRounded, color: kPrimary, size: 18),
      const SizedBox(width: 8),
      const Text('Order', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
      const Spacer(),
      if (s.cart.isNotEmpty)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: kPrimary.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: Text('${s.cart.length} items', style: const TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
    ]),
  );

  Widget _body(PosState s, PosNotifier n) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      _orderTypeRow(s, n),
      if (s.orderType == 'Dine-in')  _tableDropdown(s, n),
      if (s.orderType == 'Delivery') ...[
        _deliveryAddressField(s, n),
        _riderDropdown(s, n),          // ── Rider dropdown
      ],
      _walkInFields(s, n),
      const Divider(color: kBorder, height: 1), const SizedBox(height: 12),
      _cartItems(s, n),
      const Divider(color: kBorder, height: 1), const SizedBox(height: 8),
      _discountSection(s, n),
      const SizedBox(height: 10),
      _notesSection(s, n),
      const SizedBox(height: 12),
      const Divider(color: kBorder, height: 1), const SizedBox(height: 10),
      _billSummary(s),
      const SizedBox(height: 12),
      _paymentSection(s, n),
      const SizedBox(height: 16),
    ],
  );

  // ── Order Type ────────────────────────────────────────────────────────────
  Widget _orderTypeRow(PosState s, PosNotifier n) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionLabelWidget('Order Type'), const SizedBox(height: 6),
      Row(children: _orderTypes.map((t) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ToggleBtnWidget(label: t.$1, icon: t.$2, isSelected: s.orderType == t.$1, onTap: () => n.setOrderType(t.$1)),
        ),
      )).toList()),
      const SizedBox(height: 12),
    ],
  );

  // ── Table Dropdown ────────────────────────────────────────────────────────
  Widget _tableDropdown(PosState s, PosNotifier n) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionLabelWidget('Select Table'), const SizedBox(height: 6),
      _TableDropdown(tables: s.tables, selected: s.selectedTable, onChanged: n.setTable),
      const SizedBox(height: 12),
    ],
  );

  // ── Delivery Address ──────────────────────────────────────────────────────
  Widget _deliveryAddressField(PosState s, PosNotifier n) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionLabelWidget('Delivery Address *'), const SizedBox(height: 6),
      _AddressField(value: s.deliveryAddress, onChanged: n.setDeliveryAddress),
      const SizedBox(height: 12),
    ],
  );

  // ── Rider Dropdown ────────────────────────────────────────────────────────
  Widget _riderDropdown(PosState s, PosNotifier n) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionLabelWidget('Select Rider *'), const SizedBox(height: 6),
      _RiderDropdown(
        riders:     s.availableRiders,
        selectedId: s.selectedRiderId,
        onChanged:  n.setRider,
      ),
      const SizedBox(height: 12),
    ],
  );

  /// Regular customer picker, or walk-in name/phone with a "save as regular" link.
  Widget _walkInFields(PosState s, PosNotifier n) {
    final selected = s.customers.where((c) => c.id == s.selectedCustomerId).firstOrNull;
    final digits   = s.customerPhone.replaceAll(RegExp(r'\D'), '');
    final match    = selected == null && digits.length >= 7
        ? s.customers.where((c) => c.phoneDigits == digits).firstOrNull
        : null;
    final canSave  = selected == null && match == null && s.customerName.trim().isNotEmpty && digits.length >= 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabelWidget('Customer'), const SizedBox(height: 6),
        if (selected != null)
          _SelectedCustomerCard(customer: selected, onClear: () => n.selectCustomer(null))
        else ...[
          _CustomerDropdown(
            customers: s.customers,
            onOpen: n.refreshCustomers,
            onSelected: n.selectCustomer,
          ),
          const SizedBox(height: 8),
          _CustomerSearch(customers: s.customers, onSelected: (c) => n.selectCustomer(c.id)),
          const SizedBox(height: 8),
          // Keyed so the fields reset after a customer is picked and cleared.
          Row(key: ValueKey('walkin-${s.selectedCustomerId}'), children: [
            Expanded(child: _SimpleField(hint: 'Walk-in name', icon: AppIcons.personOutlineRounded, value: s.customerName, onChanged: n.setCustomerName)),
            const SizedBox(width: 8),
            Expanded(child: _SimpleField(hint: 'Phone', icon: AppIcons.phoneOutlined, value: s.customerPhone, onChanged: n.setCustomerPhone, keyboardType: TextInputType.phone)),
          ]),
          if (match != null)
            _CustomerHint(
              text: 'This phone belongs to ${match.name}',
              action: 'Use',
              onTap: () => n.selectCustomer(match.id),
            )
          else if (canSave)
            _CustomerHint(
              text: 'Visits often?',
              action: 'Save as regular customer',
              icon: AppIcons.personAddRounded,
              onTap: n.saveAsRegular,
            ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _cartItems(PosState s, PosNotifier n) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionLabelWidget('Items'), const SizedBox(height: 8),
      ...s.cart.map((item) => CartItemTileWidget(item: item, onChangeQty: (d) => n.changeQty(item, d), onRemove: () => n.removeFromCart(item))),
      const SizedBox(height: 8),
    ],
  );

  Widget _discountSection(PosState s, PosNotifier n) => Column(children: [
    GestureDetector(
      onTap: () => setState(() => _showDiscount = !_showDiscount),
      child: Row(children: [
        const SvgIcon(AppIcons.localOfferOutlined, size: 15, color: kGreen), const SizedBox(width: 6),
        const Text('Add Discount', style: TextStyle(fontSize: 13, color: kGreen, fontWeight: FontWeight.w600)),
        const Spacer(),
        if (s.discountAmt > 0)
          Text('−${formatMoney(s.discountAmt)}', style: const TextStyle(fontSize: 12, color: kGreen, fontWeight: FontWeight.w700)),
        const SizedBox(width: 4),
        SvgIcon(_showDiscount ? AppIcons.keyboardArrowUpRounded : AppIcons.keyboardArrowDownRounded, size: 18, color: kMuted),
      ]),
    ),
    if (_showDiscount) ...[
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _SimpleField(hint: '% Discount', icon: AppIcons.percentRounded, value: s.discountPct > 0 ? '${s.discountPct}' : '', onChanged: (v) => n.setDiscountPct(double.tryParse(v) ?? 0), keyboardType: TextInputType.number)),
        const SizedBox(width: 8),
        Expanded(child: _SimpleField(hint: '£ Flat Off', icon: AppIcons.currencyPoundRounded, value: s.discountFlat > 0 ? '${s.discountFlat}' : '', onChanged: (v) => n.setDiscountFlat(double.tryParse(v) ?? 0), keyboardType: TextInputType.number)),
      ]),
    ],
  ]);

  Widget _notesSection(PosState s, PosNotifier n) {
    const amber = Color(0xFFFFAA00);
    return Column(children: [
      GestureDetector(
        onTap: () => setState(() => _showNotes = !_showNotes),
        child: Row(children: [
          const SvgIcon(AppIcons.stickyNote2Outlined, size: 15, color: amber), const SizedBox(width: 6),
          const Text('Order Notes', style: TextStyle(fontSize: 13, color: amber, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (s.orderNotes.isNotEmpty) const SvgIcon(AppIcons.checkCircleRounded, size: 14, color: amber),
          const SizedBox(width: 4),
          SvgIcon(_showNotes ? AppIcons.keyboardArrowUpRounded : AppIcons.keyboardArrowDownRounded, size: 18, color: kMuted),
        ]),
      ),
      if (_showNotes) ...[
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: amber.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: amber.withOpacity(0.3))),
          child: _NotesField(value: s.orderNotes, onChanged: n.setNotes),
        ),
      ],
    ]);
  }

  Widget _billSummary(PosState s) => Column(children: [
    BillRowWidget('Subtotal', formatMoney(s.subtotal)),
    if (s.discountAmt > 0) BillRowWidget('Discount', '− ${formatMoney(s.discountAmt)}', isGreen: true),
    if (s.taxRate > 0) BillRowWidget('Tax (${s.taxRate.toStringAsFixed(1)}%)', formatMoney(s.tax)),
    const SizedBox(height: 6),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: kPrimary.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: kPrimary.withOpacity(0.2))),
      child: Row(children: [
        const Text('TOTAL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kText, letterSpacing: 0.5)),
        const Spacer(),
        Text(formatMoney(s.total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kPrimary)),
      ]),
    ),
  ]);

  Widget _paymentSection(PosState s, PosNotifier n) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionLabelWidget('Payment Method'), const SizedBox(height: 6),
      Row(children: _paymentMethods.map((m) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ToggleBtnWidget(label: m.$1, icon: m.$2, isSelected: s.paymentMethod == m.$1, onTap: () => n.setPaymentMethod(m.$1), activeColor: kBlue),
        ),
      )).toList()),
      const SizedBox(height: 10),
      const SectionLabelWidget('Payment Status'), const SizedBox(height: 6),
      Row(children: _paymentStatuses.map((ps) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: StatusBtnWidget(label: ps.$1, color: ps.$2, isSelected: s.paymentStatus == ps.$1, onTap: () => n.setPaymentStatus(ps.$1)),
        ),
      )).toList()),
    ],
  );

  Widget _placeOrderBtn(PosState s) => Container(
    padding: const EdgeInsets.all(14),
    decoration: const BoxDecoration(color: kCard, border: Border(top: BorderSide(color: kBorder))),
    child: SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white,
            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        onPressed: widget.onPlaceOrder,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SvgIcon(AppIcons.checkCircleRounded, size: 20), const SizedBox(width: 10),
          Text('Place Order — ${formatMoney(s.total)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.2)),
        ]),
      ),
    ),
  );
}

// ── Regular customer picker ───────────────────────────────────────────────────
/// Every saved customer (POS regulars and website customers) in a dropdown.
class _CustomerDropdown extends StatelessWidget {
  final List<PosCustomerModel> customers;
  final VoidCallback onOpen;
  final ValueChanged<String?> onSelected;

  const _CustomerDropdown({required this.customers, required this.onOpen, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) return _emptyState(AppIcons.peopleOutlineRounded, 'No registered customers yet');
    final sorted = [...customers]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: kLight, borderRadius: BorderRadius.circular(9), border: Border.all(color: kBorder)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: null,
          isExpanded: true,
          menuMaxHeight: 340,
          borderRadius: BorderRadius.circular(10),
          dropdownColor: kCard,
          onTap: onOpen,
          icon: const SvgIcon(AppIcons.keyboardArrowDownRounded, color: kMuted),
          hint: Row(children: [
            const SvgIcon(AppIcons.peopleRounded, size: 15, color: kMuted),
            const SizedBox(width: 6),
            Text('Select registered customer (${customers.length})',
                style: const TextStyle(color: kMuted, fontSize: 13)),
          ]),
          items: [
            for (final c in sorted)
              DropdownMenuItem(
                value: c.id,
                child: Row(children: [
                  _CustomerInitial(c.name),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
                        Text(
                          '${c.phone.isNotEmpty ? c.phone : 'No phone'} · ${c.orders} orders',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: kMuted),
                        ),
                      ],
                    ),
                  ),
                  if (c.type == 'online') ...[const SizedBox(width: 4), const _Pill('Online', kBlue)],
                  if (c.discount > 0) ...[const SizedBox(width: 4), _Pill('${c.discount.toStringAsFixed(0)}% off', kGreen)],
                ]),
              ),
          ],
          onChanged: onSelected,
        ),
      ),
    );
  }
}

class _CustomerSearch extends StatelessWidget {
  final List<PosCustomerModel> customers;
  final ValueChanged<PosCustomerModel> onSelected;

  const _CustomerSearch({required this.customers, required this.onSelected});

  @override
  Widget build(BuildContext context) => Autocomplete<PosCustomerModel>(
    displayStringForOption: (c) => c.name,
    optionsBuilder: (v) {
      final q = v.text.trim().toLowerCase();
      if (q.isEmpty) return const Iterable<PosCustomerModel>.empty();
      final qDigits = q.replaceAll(RegExp(r'\D'), '');
      return customers.where((c) =>
          c.name.toLowerCase().contains(q) || (qDigits.length >= 3 && c.phoneDigits.contains(qDigits))).take(8);
    },
    onSelected: onSelected,
    fieldViewBuilder: (context, ctrl, focus, onSubmit) => TextField(
      controller: ctrl,
      focusNode: focus,
      onSubmitted: (_) => onSubmit(),
      style: const TextStyle(fontSize: 13, color: kText),
      decoration: InputDecoration(
        hintText: customers.isEmpty ? 'No regular customers yet' : 'Search regular customer (name or phone)',
        hintStyle: const TextStyle(color: kMuted, fontSize: 12),
        prefixIcon: const SvgIcon(AppIcons.searchRounded, size: 15, color: kMuted),
        prefixIconConstraints: const BoxConstraints(minWidth: 34),
        filled: true, fillColor: kPrimary.withOpacity(0.04), isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: kPrimary.withOpacity(0.25))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: kPrimary.withOpacity(0.25))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: kPrimary, width: 1.5)),
      ),
    ),
    optionsViewBuilder: (context, onPick, options) => Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 6,
        color: kCard,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260, maxWidth: 340),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            shrinkWrap: true,
            children: [
              for (final c in options)
                InkWell(
                  onTap: () => onPick(c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(children: [
                      _CustomerInitial(c.name),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
                        Text('${c.phone} · ${c.orders} orders', style: const TextStyle(fontSize: 11, color: kMuted)),
                      ])),
                      if (c.discount > 0) _Pill('${c.discount.toStringAsFixed(0)}% off', kGreen),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SelectedCustomerCard extends StatelessWidget {
  final PosCustomerModel customer;
  final VoidCallback onClear;

  const _SelectedCustomerCard({required this.customer, required this.onClear});

  static const _tierColors = {'gold': Color(0xFFCA8A04), 'silver': Color(0xFF64748B)};

  @override
  Widget build(BuildContext context) {
    final tierColor = _tierColors[customer.loyalty] ?? kPrimary;
    final tier = customer.loyalty.isEmpty ? 'Regular' : customer.loyalty[0].toUpperCase() + customer.loyalty.substring(1);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kPrimary.withOpacity(0.3)),
      ),
      child: Row(children: [
        _CustomerInitial(customer.name, size: 38),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(customer.name, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kText))),
            const SizedBox(width: 6),
            _Pill(tier, tierColor),
          ]),
          const SizedBox(height: 2),
          Text(
            '${customer.phone} · ${customer.orders} orders · ${formatMoney(customer.spent)} spent',
            style: const TextStyle(fontSize: 11, color: kMuted),
          ),
          if (customer.discount > 0) ...[
            const SizedBox(height: 4),
            Text('${customer.discount.toStringAsFixed(0)}% regular-customer discount applied',
                style: const TextStyle(fontSize: 11, color: kGreen, fontWeight: FontWeight.w700)),
          ],
        ])),
        IconButton(
          tooltip: 'Remove customer',
          visualDensity: VisualDensity.compact,
          onPressed: onClear,
          icon: const SvgIcon(AppIcons.closeRounded, size: 16, color: kMuted),
        ),
      ]),
    );
  }
}

class _CustomerHint extends StatelessWidget {
  final String text, action;
  final AppIcon? icon;
  final VoidCallback onTap;

  const _CustomerHint({required this.text, required this.action, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(children: [
      Flexible(child: Text(text, style: const TextStyle(fontSize: 11.5, color: kMuted))),
      const SizedBox(width: 6),
      InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[SvgIcon(icon, size: 13, color: kPrimary), const SizedBox(width: 3)],
            Text(action, style: const TextStyle(fontSize: 11.5, color: kPrimary, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    ]),
  );
}

class _CustomerInitial extends StatelessWidget {
  final String name;
  final double size;
  const _CustomerInitial(this.name, {this.size = 30});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), shape: BoxShape.circle),
    alignment: Alignment.center,
    child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(color: kPrimary, fontWeight: FontWeight.w800, fontSize: size * 0.42)),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
  );
}

// ── Rider Dropdown ────────────────────────────────────────────────────────────
class _RiderDropdown extends StatelessWidget {
  final List<PosRiderModel> riders;
  final String?             selectedId;
  final ValueChanged<String?> onChanged;

  const _RiderDropdown({
    required this.riders,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (riders.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: kRed.withOpacity(0.05),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: kRed.withOpacity(0.3)),
        ),
        child: const Row(children: [
          SvgIcon(AppIcons.warningAmberRounded, size: 15, color: kRed),
          SizedBox(width: 8),
          Text('No riders available!', style: TextStyle(color: kRed, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: kLight,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: selectedId != null ? kPrimary.withOpacity(0.6) : kBorder,
          width: selectedId != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: kText),
          icon: const SvgIcon(AppIcons.keyboardArrowDownRounded, color: kMuted),
          hint: const Row(children: [
            SvgIcon(AppIcons.directionsBikeRounded, size: 15, color: kMuted),
            SizedBox(width: 6),
            Text('Select a rider', style: TextStyle(color: kMuted, fontSize: 13)),
          ]),
          items: riders.map((r) => DropdownMenuItem(
            value: r.id,
            child: Row(children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), shape: BoxShape.circle),
                child: Center(child: Text(r.name[0], style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 13))),
              ),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kText)),
                Text('${r.vehicle.isNotEmpty ? r.vehicle : r.phone} • ${formatMoney(r.chargePerDelivery)}/del',
                    style: const TextStyle(color: kMuted, fontSize: 11)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                child: const Text('Available', style: TextStyle(color: kGreen, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ]),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Address Field ─────────────────────────────────────────────────────────────
class _AddressField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _AddressField({required this.value, required this.onChanged});

  @override
  State<_AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<_AddressField> {
  late final TextEditingController _ctrl;

  @override
  void initState() { super.initState(); _ctrl = TextEditingController(text: widget.value); }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: kPrimary.withOpacity(0.04),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: _ctrl.text.isNotEmpty ? kPrimary.withOpacity(0.4) : kBorder,
        width: _ctrl.text.isNotEmpty ? 1.5 : 1,
      ),
    ),
    child: TextField(
      controller: _ctrl,
      onChanged: (v) { widget.onChanged(v); setState(() {}); },
      maxLines: 2,
      textDirection: TextDirection.ltr,
      style: const TextStyle(fontSize: 13, color: kText),
      decoration: const InputDecoration(
        hintText: 'e.g. House 12, Street 4, Hayatabad',
        hintStyle: TextStyle(color: kMuted, fontSize: 12),
        prefixIcon: SvgIcon(AppIcons.locationOnOutlined, size: 15, color: kMuted),
        prefixIconConstraints: BoxConstraints(minWidth: 34),
        border: InputBorder.none,
        contentPadding: EdgeInsets.fromLTRB(0, 10, 12, 10),
      ),
    ),
  );
}

// ── Simple Field ──────────────────────────────────────────────────────────────
class _SimpleField extends StatefulWidget {
  final String value, hint;
  final AppIcon icon;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  const _SimpleField({required this.hint, required this.icon, required this.value, required this.onChanged, this.keyboardType});

  @override
  State<_SimpleField> createState() => _SimpleFieldState();
}

class _SimpleFieldState extends State<_SimpleField> {
  late final TextEditingController _ctrl;

  @override
  void initState() { super.initState(); _ctrl = TextEditingController(text: widget.value); }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _ctrl,
    onChanged: widget.onChanged,
    keyboardType: widget.keyboardType,
    textDirection: TextDirection.ltr,
    style: const TextStyle(fontSize: 13, color: Color(0xFF1A1D3A)),
    decoration: InputDecoration(
      hintText: widget.hint,
      hintStyle: const TextStyle(color: Color(0xFF9396B0), fontSize: 12),
      prefixIcon: SvgIcon(widget.icon, size: 15, color: const Color(0xFF9396B0)),
      prefixIconConstraints: const BoxConstraints(minWidth: 34),
      filled: true, fillColor: const Color(0xFFF4F5F9), isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: Color(0xFFE8EAF0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: Color(0xFFE8EAF0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: Color(0xFFB91C1C), width: 1.5)),
    ),
  );
}

// ── Table Dropdown ────────────────────────────────────────────────────────────
class _TableDropdown extends StatelessWidget {
  final List<PosTableModel> tables;
  final String selected;
  final ValueChanged<String> onChanged;
  const _TableDropdown({required this.tables, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (tables.isEmpty) return _emptyState(AppIcons.tableRestaurantRounded, 'No tables available');
    return _dropdown(
      selectedValue: selected.isNotEmpty ? selected : null,
      hint: 'Select a table', hintIcon: AppIcons.tableRestaurantRounded,
      borderColor: selected.isNotEmpty ? kPrimary : kBorder,
      items: tables.map((t) => DropdownMenuItem(
        value: t.tableNumber,
        child: Row(children: [
          const SvgIcon(AppIcons.tableRestaurantRounded, size: 15, color: kPrimary), const SizedBox(width: 8),
          Text(t.tableNumber, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(width: 6),
          Text('(${t.section.isNotEmpty ? t.section : t.floor}) · ${t.capacity} seats',
              style: const TextStyle(color: kMuted, fontSize: 12)),
        ]),
      )).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}

// ── Customer Dropdown ─────────────────────────────────────────────────────────
Widget _emptyState(AppIcon icon, String message) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  decoration: BoxDecoration(color: kLight, borderRadius: BorderRadius.circular(9), border: Border.all(color: kBorder)),
  child: Row(children: [SvgIcon(icon, size: 15, color: kMuted), const SizedBox(width: 8), Text(message, style: const TextStyle(color: kMuted, fontSize: 13))]),
);

Widget _dropdown<T>({required T? selectedValue, required String hint, required AppIcon hintIcon, required Color borderColor, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
          color: kLight, borderRadius: BorderRadius.circular(9),
          border: Border.all(color: borderColor, width: selectedValue != null ? 1.5 : 1)),
      child: DropdownButtonHideUnderline(child: DropdownButton<T>(
        value: selectedValue, isExpanded: true,
        style: const TextStyle(fontSize: 13, color: kText),
        icon: const SvgIcon(AppIcons.keyboardArrowDownRounded, color: kMuted),
        hint: Row(children: [SvgIcon(hintIcon, size: 15, color: kMuted), const SizedBox(width: 6), Text(hint, style: const TextStyle(color: kMuted, fontSize: 13))]),
        items: items, onChanged: onChanged,
      )),
    );

// ── Cart Item Tile ────────────────────────────────────────────────────────────
class CartItemTileWidget extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onChangeQty;
  final VoidCallback onRemove;
  const CartItemTileWidget({super.key, required this.item, required this.onChangeQty, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(color: kLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
    child: Row(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: item.product.imageUrl != null && !item.product.isDeal
            ? Image.network(item.product.imageUrl!, width: 36, height: 36, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback())
            : _fallback(),
      ),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('${formatMoney(item.unitPrice)} × ${item.qty}', style: const TextStyle(fontSize: 11, color: kMuted)),
      ])),
      _QtyControl(qty: item.qty, onChanged: onChangeQty),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(formatMoney(item.total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kPrimary)),
        GestureDetector(onTap: onRemove, child: const SvgIcon(AppIcons.deleteOutlineRounded, size: 14, color: kMuted)),
      ]),
    ]),
  );

  Widget _fallback() => Container(width: 36, height: 36, color: kLight,
      child: Center(child: Text(item.product.isDeal ? '🎁' : '🍽️', style: const TextStyle(fontSize: 20))));
}

class _QtyControl extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onChanged;
  const _QtyControl({required this.qty, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(onTap: () => onChanged(-1), child: const Padding(padding: EdgeInsets.all(6), child: SvgIcon(AppIcons.removeRounded, size: 14, color: kPrimary))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('$qty', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText))),
      GestureDetector(onTap: () => onChanged(1), child: const Padding(padding: EdgeInsets.all(6), child: SvgIcon(AppIcons.addRounded, size: 14, color: kPrimary))),
    ]),
  );
}

class EmptyCartWidget extends StatelessWidget {
  const EmptyCartWidget({super.key});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), shape: BoxShape.circle), child: const SvgIcon(AppIcons.shoppingCartOutlined, size: 40, color: kPrimary)),
    const SizedBox(height: 14),
    const Text('Cart is empty', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
    const SizedBox(height: 5),
    const Text('Select items from the left panel', style: TextStyle(fontSize: 12, color: kMuted)),
  ]));
}

class _NotesField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _NotesField({required this.value, required this.onChanged});
  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  late final TextEditingController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = TextEditingController(text: widget.value); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFFFAA00);
    return Container(
      decoration: BoxDecoration(color: amber.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: amber.withOpacity(0.3))),
      child: TextField(
        controller: _ctrl, onChanged: widget.onChanged, maxLines: 3, textDirection: TextDirection.ltr,
        style: const TextStyle(fontSize: 13, color: Color(0xFF1A1D3A)),
        decoration: const InputDecoration(
          hintText: 'e.g. extra cheese, no veggies, spicy...',
          hintStyle: TextStyle(color: Color(0xFF9396B0), fontSize: 12),
          border: InputBorder.none, contentPadding: EdgeInsets.all(12),
        ),
      ),
    );
  }
}
