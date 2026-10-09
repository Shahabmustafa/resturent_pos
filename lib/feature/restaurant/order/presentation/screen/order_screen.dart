import 'package:resturent_application/core/widget/status_pill.dart';
import 'package:resturent_application/core/widget/stat_card.dart';
import '../widget/order_skeleton.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../pos_and_order/data/model/order_model.dart';
import '../provider/order_provider.dart';
import '../widget/receipt_dilog_widget.dart';
import 'package:resturent_application/core/constants/currency.dart';


class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderProvider);

    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: kPrimary, behavior: SnackBarBehavior.floating));
        ref.read(orderProvider.notifier).clearError();
      });
    }

    return Scaffold(
      backgroundColor: kBg,
      body: Row(children: [
        // ── Left: List ───────────────────────────────────────────────
        Expanded(
          child: Column(children: [
            _TopBar(
              isLoading: state.loading || state.updating,
              hasActiveFilters: state.statusFilter != 'All' || state.typeFilter != 'All' || state.paymentFilter != 'All' || state.search.isNotEmpty || state.from != null,
              onRefresh:     () => ref.read(orderProvider.notifier).load(),
              onClearFilter: () => ref.read(orderProvider.notifier).clearFilters(),
            ),
            state.loading && state.orders.isEmpty
                ? const OrderSummaryStripSkeleton()
                : _SummaryStrip(state: state),
            _FilterBar(state: state, notifier: ref.read(orderProvider.notifier), context: context),
            Expanded(
              child: state.loading && state.orders.isEmpty ?
              const OrderTableSkeleton() :
              state.orders.isEmpty ?
              _EmptyState(hasFilters: state.statusFilter != 'All' || state.typeFilter != 'All' || state.search.isNotEmpty) :
              _OrderTable(
                orders: state.orders,
                selected: state.selected,
                onSelect: (o) => ref.read(orderProvider.notifier).select(state.selected?.id == o.id ? null : o),
                onPrint: (o) => showDialog(
                  context: context,
                  builder: (_) => ReceiptPrintDialog(order: o),
                ),
              ),
            ),
          ]),
        ),

        // ── Right: Detail Panel ──────────────────────────────────────
        if (state.selected != null)
          SizedBox(
            width: 340,
            child: _DetailPanel(
              order: state.selected!,
              updating: state.updating,
              onClose: () => ref.read(orderProvider.notifier).select(null),
              onUpdateStatus:  (s) => ref.read(orderProvider.notifier).updateStatus(state.selected!.id, s),
              onUpdatePayment: (s) => ref.read(orderProvider.notifier).updatePaymentStatus(state.selected!.id, s),
              onPrint: () => showDialog(
                context: context,
                builder: (_) => ReceiptPrintDialog(order: state.selected!),
              ),
            ),
          ),
      ]),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool isLoading, hasActiveFilters;
  final VoidCallback onRefresh, onClearFilter;
  const _TopBar({required this.isLoading, required this.hasActiveFilters,
    required this.onRefresh, required this.onClearFilter});

  @override
  Widget build(BuildContext context) => Container(
    height: 60,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: const BoxDecoration(color: kCard, border: Border(bottom: BorderSide(color: kBorder))),
    child: Row(children: [
      const SvgIcon(AppIcons.receiptLongRounded, color: kPrimary, size: 20),
      const SizedBox(width: 10),
      const Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Orders', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kText)),
        Text('View and manage all orders', style: TextStyle(fontSize: 11, color: kMuted)),
      ]),
      const Spacer(),
      if (hasActiveFilters)
        TextButton.icon(
          onPressed: onClearFilter,
          icon: const SvgIcon(AppIcons.filterAltOffRounded, size: 14),
          label: const Text('Clear Filters', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(foregroundColor: kPrimary),
        ),
      const SizedBox(width: 4),
      if (isLoading)
        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary))
      else
        IconButton(onPressed: onRefresh, icon: const SvgIcon(AppIcons.refreshRounded, color: kPrimary, size: 20), tooltip: 'Refresh'),
    ]),
  );
}

// ── Summary Strip ─────────────────────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  final OrderState state;
  const _SummaryStrip({required this.state});

  @override
  Widget build(BuildContext context) => Container(
    color: kCard,
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
    child: StatCardRow(cards: [
      StatCardData(AppIcons.receiptRounded,     'Total Orders', '${state.totalOrders}',    kBlue),
      StatCardData(AppIcons.pendingRounded,     'Pending',      '${state.pendingCount}',   kYellow),
      StatCardData(AppIcons.checkCircleRounded, 'Completed',    '${state.completedCount}', kGreen),
      StatCardData(AppIcons.paymentsRounded,    'Revenue',      formatMoney(state.totalRevenue), kPrimary),
      StatCardData(AppIcons.checkRounded,       'Collected',    formatMoney(state.totalPaid),    kPurple),
    ]),
  );
}

// ── Filter Bar ────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final OrderState state;
  final OrderNotifier notifier;
  final BuildContext context;
  const _FilterBar({required this.state, required this.notifier, required this.context});

  static const _statuses = ['All', 'pending', 'completed', 'cancelled'];
  static const _types    = ['All', 'Dine-in', 'Takeaway', 'Delivery'];
  static const _payments = ['All', 'Paid', 'Unpaid', 'Partial'];

  @override
  Widget build(BuildContext context) => Container(
    color: kCard,
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        // Search
        SizedBox(
          width: 190,
          child: TextField(
            onChanged: notifier.setSearch,
            style: const TextStyle(fontSize: 13, color: kText),
            decoration: InputDecoration(
              hintText: 'Search...', hintStyle: const TextStyle(color: kMuted, fontSize: 12),
              prefixIcon: const SvgIcon(AppIcons.searchRounded, size: 16, color: kMuted),
              filled: true, fillColor: kLight, isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimary, width: 1.5)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _vDivider(),
        const SizedBox(width: 10),
        // Status chips
        ..._statuses.map((s) => Padding(padding: const EdgeInsets.only(right: 6), child: _Chip(
          label: s == 'All' ? 'All' : s[0].toUpperCase() + s.substring(1),
          selected: state.statusFilter == s,
          color: kPrimary,
          onTap: () => notifier.setStatusFilter(s),
        ))),
        _vDivider(), const SizedBox(width: 6),
        // Type chips
        ..._types.map((t) => Padding(padding: const EdgeInsets.only(right: 6), child: _Chip(
          label: t, selected: state.typeFilter == t, color: kPrimary,
          onTap: () => notifier.setTypeFilter(t),
        ))),
        _vDivider(), const SizedBox(width: 6),
        // Payment chips
        ..._payments.map((p) => Padding(padding: const EdgeInsets.only(right: 6), child: _Chip(
          label: p,
          selected: state.paymentFilter == p,
          color: kPrimary,
          onTap: () => notifier.setPaymentFilter(p),
        ))),
        _vDivider(), const SizedBox(width: 6),
        // Date range
        GestureDetector(
          onTap: () async {
            final r = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2024),
              lastDate: DateTime.now(),
              initialDateRange: state.from != null && state.to != null ?
              DateTimeRange(start: state.from!, end: state.to!) : null,
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)),
                child: child!,
              ),
            );
            if (r != null) notifier.setDateRange(r.start, r.end);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: state.from != null ? kPrimary.withValues(alpha: 0.08) : kLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: state.from != null ? kPrimary.withValues(alpha: 0.4) : kBorder),
            ),
            child: Row(children: [
              SvgIcon(AppIcons.dateRangeRounded, size: 14, color: state.from != null ? kPrimary : kMuted),
              const SizedBox(width: 5),
              Text(
                state.from != null
                    ? '${state.from!.day}/${state.from!.month} – ${state.to!.day}/${state.to!.month}'
                    : 'Date Range',
                style: TextStyle(fontSize: 12, color: state.from != null ? kPrimary : kMuted, fontWeight: FontWeight.w600),
              ),
              if (state.from != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => notifier.setDateRange(null, null),
                  child: const SvgIcon(AppIcons.closeRounded, size: 13, color: kPrimary),
                ),
              ],
            ]),
          ),
        ),
      ]),
    ),
  );

  Widget _vDivider() => Container(width: 1, height: 20, color: kBorder);
}

class _Chip extends StatelessWidget {
  final String label; final bool selected; final Color color; final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.1) : kLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? color.withValues(alpha: 0.4) : kBorder),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: selected ? color : kMuted,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
    ),
  );
}

// ── Orders Table ──────────────────────────────────────────────────────────────
// ── Orders Table (FIXED — flexible columns instead of fixed SizedBox widths) ──
class _OrderTable extends StatelessWidget {
  final List<OrderModel> orders;
  final OrderModel? selected;
  final ValueChanged<OrderModel> onSelect;
  final ValueChanged<OrderModel> onPrint;
  const _OrderTable({required this.orders, required this.selected,
    required this.onSelect, required this.onPrint});

  Color _sc(String s) => orderStatusColor(s);
  Color _pc(String s) => paymentStatusColor(s);

  @override
  Widget build(BuildContext context) => Column(children: [
    // Header row
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(color: kCard, border: Border(bottom: BorderSide(color: kBorder))),
      child: Row(children: const [
        Expanded(flex: 2, child: Text('Order #',  style: _h)),
        Expanded(flex: 2, child: Text('Time',     style: _h)),
        Expanded(flex: 2, child: Text('Type',     style: _h)),
        Expanded(flex: 3, child: Text('Customer', style: _h)),
        Expanded(flex: 2, child: Text('Table',    style: _h)),
        Expanded(flex: 2, child: Text('Status',   style: _h)),
        Expanded(flex: 2, child: Text('Payment',  style: _h)),
        Expanded(flex: 2, child: Text('Total',    style: _h, textAlign: TextAlign.right)),
        SizedBox(width: 40), // print column — stays fixed
      ]),
    ),
    Expanded(
      child: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (_, i) {
          final o   = orders[i];
          final sel = selected?.id == o.id;
          return GestureDetector(
            onTap: () => onSelect(o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? kPrimary.withValues(alpha: 0.05) : (i.isEven ? kCard : kBg),
                border: Border(
                  bottom: BorderSide(color: kBorder.withValues(alpha: 0.5)),
                  left: BorderSide(color: sel ? kPrimary : Colors.transparent, width: 3),
                ),
              ),
              child: Row(children: [
                Expanded(flex: 2, child: Text(o.orderNumber, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kPrimary))),
                Expanded(flex: 2, child: Text(_time(o.createdAt), overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: kSub))),
                Expanded(flex: 2, child: _TypeChip(o.orderType)),
                Expanded(flex: 3, child: Text(o.customerName.isNotEmpty ? o.customerName : 'Walk-in',
                    style: const TextStyle(fontSize: 12, color: kText), overflow: TextOverflow.ellipsis)),
                Expanded(flex: 2, child: Text(o.tableNumber.isNotEmpty ? o.tableNumber : '—',
                    overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: kSub))),
                Expanded(flex: 2, child: _Badge(o.status[0].toUpperCase() + o.status.substring(1), _sc(o.status))),
                Expanded(flex: 2, child: _Badge(o.paymentStatus, _pc(o.paymentStatus))),
                Expanded(flex: 2, child: Text(formatMoney(o.total), textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText))),
                // ── Print Icon ──
                SizedBox(
                  width: 40,
                  child: IconButton(
                    onPressed: () => onPrint(o),
                    icon: const SvgIcon(AppIcons.printRounded, size: 16, color: kMuted),
                    tooltip: 'Print Receipt',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    ),
  ]);

  String _time(DateTime d) {
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month)
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${d.day}/${d.month} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static const _h = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 0.3);
}

class _Badge extends StatelessWidget {
  final String text; final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => StatusPill(label: text, color: color, dot: true);
}

Color orderStatusColor(String status) => switch (status.toLowerCase()) {
  'pending'   => kYellow,
  'completed' => kGreen,
  'cancelled' => kRed,
  _           => kBlue,
};

Color paymentStatusColor(String status) => switch (status.toLowerCase()) {
  'paid'    => kGreen,
  'unpaid'  => kRed,
  'partial' => kYellow,
  _         => kBlue,
};

class _TypeChip extends StatelessWidget {
  final String type;
  const _TypeChip(this.type);
  AppIcon get _icon => switch (type) {
    'Takeaway' => AppIcons.takeoutDiningRounded,
    'Delivery' => AppIcons.deliveryDiningRounded,
    _ => AppIcons.restaurantRounded,
  };
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    SvgIcon(_icon, size: 12, color: kMuted), const SizedBox(width: 4),
    Text(type, style: const TextStyle(fontSize: 11, color: kSub)),
  ]);
}

// ── Detail Panel ──────────────────────────────────────────────────────────────
class _DetailPanel extends StatelessWidget {
  final OrderModel order;
  final bool updating;
  final VoidCallback onClose;
  final VoidCallback onPrint;
  final ValueChanged<String> onUpdateStatus, onUpdatePayment;
  const _DetailPanel({required this.order, required this.updating, required this.onClose,
    required this.onUpdateStatus, required this.onUpdatePayment, required this.onPrint});

  Color _sc(String s) => orderStatusColor(s);
  Color _pc(String s) => paymentStatusColor(s);

  // Grey panel so the white invoice cards stand out.
  static const _panelBg = Color(0xFFF1F2F6);

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: _panelBg, border: Border(left: BorderSide(color: kBorder))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: const BoxDecoration(color: kCard, border: Border(bottom: BorderSide(color: kBorder))),
        child: Row(children: [
          Text(order.orderNumber,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kPrimary)),
          const SizedBox(width: 8),
          if (updating)
            const SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary)),
          const Spacer(),
          // Print button in detail panel header
          IconButton(
            onPressed: onPrint,
            icon: const SvgIcon(AppIcons.printRounded, size: 18, color: kMuted),
            tooltip: 'Print Receipt',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 16,
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onClose,
            icon: const SvgIcon(AppIcons.closeRounded, size: 18, color: kMuted),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Badges
            Row(children: [
              _Badge(order.status[0].toUpperCase() + order.status.substring(1), _sc(order.status)),
              const SizedBox(width: 6),
              _Badge(order.paymentStatus, _pc(order.paymentStatus)),
              const SizedBox(width: 6),
              _TypeChip(order.orderType),
            ]),
            const SizedBox(height: 14),

            // Info card
            _Card(children: [
              if (order.customerName.isNotEmpty)
                _Row(AppIcons.personRounded, 'Customer', order.customerName),
              if (order.customerPhone.isNotEmpty)
                _Row(AppIcons.phoneRounded, 'Phone', order.customerPhone),
              if (order.tableNumber.isNotEmpty)
                _Row(AppIcons.tableRestaurantRounded, 'Table', order.tableNumber),
              _Row(AppIcons.accessTimeRounded, 'Time', _fullTime(order.createdAt)),
              _Row(AppIcons.paymentRounded, 'Payment',
                  '${order.paymentMethod} · ${order.customerType}'),
            ]),
            const SizedBox(height: 14),

            // Items
            const Text('Items', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                color: kMuted, letterSpacing: 0.3)),
            const SizedBox(height: 8),
            if (order.items.isEmpty)
              const Text('No items loaded', style: TextStyle(fontSize: 12, color: kMuted))
            else
              ...order.items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: kCard, borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBorder)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.itemName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText)),
                    if (item.size.isNotEmpty)
                      Text(item.size, style: const TextStyle(fontSize: 10, color: kMuted)),
                  ])),
                  Text('× ${item.qty}', style: const TextStyle(fontSize: 12, color: kSub)),
                  const SizedBox(width: 8),
                  Text(formatMoney(item.totalPrice),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kPrimary)),
                ]),
              )),
            const SizedBox(height: 14),

            // Bill
            _Card(children: [
              _BillRow('Subtotal', formatMoney(order.subtotal), kText),
              if (order.discountAmt > 0)
                _BillRow('Discount', '− ${formatMoney(order.discountAmt)}', kPrimary),
              _BillRow('Tax (${order.taxPct.toStringAsFixed(0)}%)',
                  formatMoney(order.taxAmt), kSub),
              const Divider(color: kBorder, height: 16),
              _BillRow('TOTAL', formatMoney(order.total), kPrimary, bold: true),
            ]),

            if (order.notes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kPrimary.withValues(alpha: 0.25)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SvgIcon(AppIcons.stickyNote2Outlined, size: 14, color: kPrimary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(order.notes,
                      style: const TextStyle(fontSize: 12, color: kSub))),
                ]),
              ),
            ],
            const SizedBox(height: 16),

            // Status actions
            if (order.status == 'pending') ...[
              const Text('Update Order Status', style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w800, color: kMuted, letterSpacing: 0.3)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimary,
                      foregroundColor: Colors.white, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: updating ? null : () => onUpdateStatus('completed'),
                  icon: const SvgIcon(AppIcons.checkRounded, size: 15),
                  label: const Text('Complete', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                )),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: kPrimary,
                      side: BorderSide(color: kPrimary.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: updating ? null : () => onUpdateStatus('cancelled'),
                  icon: const SvgIcon(AppIcons.cancelOutlined, size: 15),
                  label: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                )),
              ]),
              const SizedBox(height: 12),
            ],

            // Payment actions
            if (order.paymentStatus != 'Paid') ...[
              const Text('Update Payment', style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w800, color: kMuted, letterSpacing: 0.3)),
              const SizedBox(height: 8),
              Row(children: [
                if (order.paymentStatus == 'Unpaid') ...[
                  Expanded(child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimary,
                        foregroundColor: Colors.white, elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: updating ? null : () => onUpdatePayment('Paid'),
                    icon: const SvgIcon(AppIcons.paymentsRounded, size: 15),
                    label: const Text('Mark Paid', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimary,
                        foregroundColor: Colors.white, elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: updating ? null : () => onUpdatePayment('Partial'),
                    child: const Text('Partial', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  )),
                ],
                if (order.paymentStatus == 'Partial')
                  Expanded(child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimary,
                        foregroundColor: Colors.white, elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: updating ? null : () => onUpdatePayment('Paid'),
                    icon: const SvgIcon(AppIcons.paymentsRounded, size: 15),
                    label: const Text('Mark Paid', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  )),
              ]),
            ],
          ]),
        ),
      ),
    ]),
  );

  String _fullTime(DateTime d) =>
      '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder)),
    child: Column(children: children),
  );
}

class _Row extends StatelessWidget {
  final AppIcon icon; final String label, value;
  const _Row(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      SvgIcon(icon, size: 13, color: kMuted), const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12, color: kMuted)),
      const Spacer(),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText)),
    ]),
  );
}

class _BillRow extends StatelessWidget {
  final String label, value; final Color color; final bool bold;
  const _BillRow(this.label, this.value, this.color, {this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Text(label, style: TextStyle(fontSize: bold ? 13 : 12,
          fontWeight: bold ? FontWeight.w900 : FontWeight.w400, color: bold ? kText : kSub)),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: bold ? 15 : 12,
          fontWeight: FontWeight.w800, color: color)),
    ]),
  );
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  const _EmptyState({required this.hasFilters});
  @override
  Widget build(BuildContext context) => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: const SvgIcon(AppIcons.receiptLongRounded, size: 48, color: kPrimary)),
    const SizedBox(height: 16),
    Text(hasFilters ? 'No orders match the filter' : 'No orders yet',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
    const SizedBox(height: 6),
    Text(hasFilters ? 'Try changing or clearing the filters'
        : 'Orders will appear here after placement',
        style: const TextStyle(fontSize: 13, color: kMuted)),
  ]));
}