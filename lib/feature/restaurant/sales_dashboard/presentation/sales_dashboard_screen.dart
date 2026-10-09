import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/shimmer.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import '../../../../core/constants/app_colors.dart';
import '../data/dashboard_stats.dart';
import 'dashboard_charts.dart';
import 'sales_dashboard_provider.dart';

/// Sales dashboard: headline figures with change vs the previous period, live
/// status, sales trend, busy hours, payment / order-type / channel split, top
/// items and customers, and the latest orders.
class SalesDashboardScreen extends ConsumerWidget {
  const SalesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(salesDashboardProvider);
    final n = ref.read(salesDashboardProvider.notifier);
    final stats = s.stats;

    return Scaffold(
      backgroundColor: kBg,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Header(state: s, onPeriod: n.setPeriod, onRefresh: n.load),
          const SizedBox(height: 16),
          if (s.error != null && stats == null)
            _ErrorCard(message: s.error!, onRetry: n.load)
          else if (stats == null)
            const _DashboardSkeleton()
          else
            // Refetches keep the previous numbers on screen, slightly faded.
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: s.refreshing ? 0.6 : 1,
              child: _Body(stats: stats, period: s.period),
            ),
        ],
      ),
    );
  }
}

// ── Header + period filter (one row above everything it scopes) ──────────────
class _Header extends StatelessWidget {
  final SalesDashboardState state;
  final ValueChanged<DashboardPeriod> onPeriod;
  final VoidCallback onRefresh;

  const _Header({required this.state, required this.onPeriod, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final (from, to) = state.period.range(DateTime.now());
    final sameDay = from.day == to.day && from.month == to.month && to.difference(from).inHours < 24;
    final range = sameDay
        ? DateFormat('EEEE, d MMMM').format(from)
        : '${DateFormat('d MMM').format(from)} – ${DateFormat('d MMM').format(to)}';
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 2),
          Text('Sales · $range', style: const TextStyle(fontSize: 13, color: kMuted)),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (final p in DashboardPeriod.values)
                _PeriodChip(label: p.label, selected: p == state.period, onTap: () => onPeriod(p)),
            ]),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Refresh',
            onPressed: onRefresh,
            icon: state.refreshing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary))
                : const SvgIcon(AppIcons.refreshRounded, size: 20, color: kSub),
          ),
        ]),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? kText : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : kSub,
              )),
        ),
      );
}

// ── Body ──────────────────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final DashboardStats stats;
  final DashboardPeriod period;

  const _Body({required this.stats, required this.period});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final wide = w >= 1100;
      const gap = 16.0;

      // Top-aligned rows: charts use LayoutBuilder, which can't report intrinsic
      // heights, so cards aren't stretched to equal height.
      Widget pair(Widget a, Widget b, {int flexA = 1, int flexB = 1}) => wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: flexA, child: a),
              const SizedBox(width: gap),
              Expanded(flex: flexB, child: b),
            ])
          : Column(children: [a, const SizedBox(height: gap), b]);

      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _KpiRow(stats: stats, period: period, width: w),
        const SizedBox(height: gap),
        _LiveStrip(live: stats.live, width: w),
        const SizedBox(height: gap),
        pair(_TrendCard(stats: stats, period: period), _PaymentCard(stats: stats), flexA: 2),
        const SizedBox(height: gap),
        pair(_BusyHoursCard(stats: stats), _MixCard(stats: stats)),
        const SizedBox(height: gap),
        if (wide)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _TopItemsCard(items: stats.topItems)),
            const SizedBox(width: gap),
            Expanded(child: _TopCustomersCard(customers: stats.topCustomers)),
            const SizedBox(width: gap),
            Expanded(child: _RecentOrdersCard(orders: stats.live.recent)),
          ])
        else ...[
          _TopItemsCard(items: stats.topItems),
          const SizedBox(height: gap),
          _TopCustomersCard(customers: stats.topCustomers),
          const SizedBox(height: gap),
          _RecentOrdersCard(orders: stats.live.recent),
        ],
      ]);
    });
  }
}

// ── KPI tiles ─────────────────────────────────────────────────────────────────
class _KpiRow extends StatelessWidget {
  final DashboardStats stats;
  final DashboardPeriod period;
  final double width;

  const _KpiRow({required this.stats, required this.period, required this.width});

  @override
  Widget build(BuildContext context) {
    final cols = width >= 1100 ? 4 : (width >= 620 ? 2 : 1);
    const gap = 16.0;
    final tileW = (width - gap * (cols - 1)) / cols;
    final vs = 'vs ${period.previousLabel}';
    final tiles = [
      _KpiTile(
        label: 'Revenue',
        value: rs(stats.revenue),
        hero: true,
        icon: AppIcons.pointOfSaleRounded,
        delta: _Delta.of(stats.revenue, stats.prevRevenue, vs),
      ),
      _KpiTile(
        label: 'Paid orders',
        value: NumberFormat('#,##0').format(stats.paidOrders),
        icon: AppIcons.receiptLongRounded,
        delta: _Delta.of(stats.paidOrders.toDouble(), stats.prevPaidOrders.toDouble(), vs),
        footnote: stats.cancelled > 0 ? '${stats.cancelled} cancelled' : null,
      ),
      _KpiTile(
        label: 'Average order',
        value: rs(stats.avgOrder),
        icon: AppIcons.paymentsRounded,
        delta: _Delta.of(stats.avgOrder, stats.prevAvgOrder, vs),
      ),
      _KpiTile(
        label: 'Items sold',
        value: NumberFormat('#,##0').format(stats.itemsSold),
        icon: AppIcons.restaurantRounded,
        footnote: stats.discounts > 0 ? '${rs(stats.discounts)} in discounts' : 'No discounts given',
      ),
    ];
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [for (final t in tiles) SizedBox(width: tileW, child: t)],
    );
  }
}

class _Delta {
  final double? pct; // null → nothing to compare against
  final String vs;
  const _Delta(this.pct, this.vs);

  static _Delta of(double cur, double prev, String vs) =>
      _Delta(prev <= 0 ? (cur > 0 ? null : 0) : (cur - prev) / prev * 100, vs);
}

class _KpiTile extends StatelessWidget {
  final String label, value;
  final AppIcon icon;
  final bool hero;
  final _Delta? delta;
  final String? footnote;

  const _KpiTile({required this.label, required this.value, required this.icon, this.hero = false, this.delta, this.footnote});

  @override
  Widget build(BuildContext context) {
    Widget? deltaRow;
    final d = delta;
    if (d != null) {
      if (d.pct == null) {
        deltaRow = Text('New · nothing ${d.vs.replaceFirst('vs ', 'in ')}', style: const TextStyle(fontSize: 12, color: kMuted));
      } else {
        final up = d.pct! > 0.5, down = d.pct! < -0.5;
        final color = up ? DashColors.goodText : (down ? DashColors.critical : kMuted);
        deltaRow = Row(children: [
          if (up || down) SvgIcon(up ? AppIcons.arrowUpwardRounded : AppIcons.arrowDownwardRounded, size: 14, color: color),
          if (up || down) const SizedBox(width: 2),
          Text(up || down ? '${d.pct!.abs().toStringAsFixed(d.pct!.abs() >= 10 ? 0 : 1)}%' : 'No change',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 5),
          Flexible(child: Text(d.vs, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: kMuted))),
        ]);
      }
    }
    return Container(
      height: 156, // same height for every tile, whatever lines it shows
      padding: const EdgeInsets.all(18),
      decoration: _card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kSub))),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(9)),
            child: SvgIcon(icon, size: 16, color: kPrimary),
          ),
        ]),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: TextStyle(fontSize: hero ? 32 : 26, fontWeight: FontWeight.w800, color: kText, height: 1.1)),
        ),
        const SizedBox(height: 8),
        if (deltaRow != null) deltaRow,
        if (footnote != null) ...[
          if (deltaRow != null) const SizedBox(height: 2),
          Text(footnote!, style: const TextStyle(fontSize: 12, color: kMuted)),
        ],
      ]),
    );
  }
}

// ── Live status (status colours always paired with an icon + label) ──────────
class _LiveStrip extends StatelessWidget {
  final LiveStatus live;
  final double width;

  const _LiveStrip({required this.live, required this.width});

  @override
  Widget build(BuildContext context) {
    final cols = width >= 900 ? 3 : 1;
    const gap = 16.0;
    final w = (width - gap * (cols - 1)) / cols;
    final items = [
      _LiveItem(
        icon: AppIcons.pendingActionsRounded,
        title: 'Pending orders',
        value: '${live.pendingOrders}',
        status: live.pendingOrders == 0 ? 'All caught up' : 'Waiting to be completed',
        color: live.pendingOrders == 0 ? DashColors.good : DashColors.warning,
      ),
      _LiveItem(
        icon: AppIcons.deliveryDiningRounded,
        title: 'Active deliveries',
        value: '${live.activeDeliveries}',
        status: live.activeDeliveries == 0 ? 'None on the road' : 'Out or waiting for a rider',
        color: live.activeDeliveries == 0 ? DashColors.good : DashColors.series1,
      ),
      _LiveItem(
        icon: live.counterOpen ? AppIcons.lockOpenRounded : AppIcons.lockOutlineRounded,
        title: 'Cash counter',
        value: live.counterOpen ? rs(live.counterExpectedCash) : 'Closed',
        status: live.counterOpen
            ? 'Open since ${DateFormat('h:mm a').format(live.counterOpenedAt!)} · ${live.counterOpenedBy}'
            : 'Open it before taking cash',
        color: live.counterOpen ? DashColors.good : DashColors.critical,
      ),
    ];
    return Wrap(spacing: gap, runSpacing: gap, children: [for (final i in items) SizedBox(width: w, child: i)]);
  }
}

class _LiveItem extends StatelessWidget {
  final AppIcon icon;
  final String title, value, status;
  final Color color;

  const _LiveItem({required this.icon, required this.title, required this.value, required this.status, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: _card(),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: SvgIcon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600)),
              Text(status, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: kSub)),
            ]),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kText)),
        ]),
      );
}

// ── Charts ────────────────────────────────────────────────────────────────────
class _TrendCard extends StatelessWidget {
  final DashboardStats stats;
  final DashboardPeriod period;

  const _TrendCard({required this.stats, required this.period});

  @override
  Widget build(BuildContext context) {
    final best = stats.trend.isEmpty
        ? null
        : stats.trend.reduce((a, b) => b.current > a.current ? b : a);
    return _Panel(
      title: 'Sales trend',
      subtitle: stats.hourly ? 'Revenue by hour' : 'Revenue by day',
      trailing: const Wrap(spacing: 14, children: [
        _LegendKey(color: DashColors.series1, label: 'This period'),
        _LegendKey(color: DashColors.context, label: 'Previous'),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (best != null && best.current > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Best ${stats.hourly ? 'hour' : 'day'}: '
              '${stats.hourly ? DateFormat('h a').format(best.at) : DateFormat('EEE d MMM').format(best.at)} · ${rs(best.current)}',
              style: const TextStyle(fontSize: 12, color: kSub),
            ),
          ),
        SizedBox(
          height: 240,
          child: stats.trend.every((p) => p.current == 0 && p.previous == 0)
              ? const _EmptyChart('No sales in this period yet')
              : SalesTrendChart(points: stats.trend, hourly: stats.hourly),
        ),
      ]),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final DashboardStats stats;

  const _PaymentCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Cash', stats.cash, DashColors.series1, AppIcons.paymentsRounded),
      ('Card', stats.card, DashColors.series2, AppIcons.creditCardRounded),
      ('Online', stats.online, DashColors.series3, AppIcons.phoneAndroidRounded),
    ];
    final total = stats.cash + stats.card + stats.online;
    return _Panel(
      title: 'Payment methods',
      subtitle: 'Share of revenue',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SplitBar(parts: [for (final r in rows) (r.$2, r.$3)]),
        const SizedBox(height: 16),
        for (final r in rows) ...[
          _ValueRow(
            color: r.$3,
            icon: r.$4,
            label: r.$1,
            value: rs(r.$2),
            share: total > 0 ? r.$2 / total : 0,
          ),
          const SizedBox(height: 12),
        ],
        const Divider(color: kBorder, height: 12),
        Row(children: [
          const Expanded(child: Text('Total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText))),
          Text(rs(total), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kText)),
        ]),
        if (stats.unpaidAmount > 0) ...[
          const SizedBox(height: 10),
          Row(children: [
            const SvgIcon(AppIcons.warningAmberRounded, size: 14, color: DashColors.warning),
            const SizedBox(width: 6),
            Expanded(
              child: Text('${rs(stats.unpaidAmount)} ordered but not paid yet',
                  style: const TextStyle(fontSize: 12, color: kSub)),
            ),
          ]),
        ],
      ]),
    );
  }
}

class _BusyHoursCard extends StatelessWidget {
  final DashboardStats stats;

  const _BusyHoursCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final peak = stats.hours.isEmpty ? null : stats.hours.reduce((a, b) => b.revenue > a.revenue ? b : a);
    return _Panel(
      title: 'Busy hours',
      subtitle: 'Revenue by hour of day',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (peak != null && peak.revenue > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Peak: ${BusyHoursChart.hourLabel(peak.hour)} – ${BusyHoursChart.hourLabel((peak.hour + 1) % 24)} · '
              '${rs(peak.revenue)} from ${peak.orders} ${peak.orders == 1 ? 'order' : 'orders'}',
              style: const TextStyle(fontSize: 12, color: kSub),
            ),
          ),
        SizedBox(
          height: 220,
          child: stats.hours.every((h) => h.revenue == 0)
              ? const _EmptyChart('No sales in this period yet')
              : BusyHoursChart(hours: stats.hours),
        ),
      ]),
    );
  }
}

/// Order types (ranked bars) and website vs POS (split bar).
class _MixCard extends StatelessWidget {
  final DashboardStats stats;

  const _MixCard({required this.stats});

  static const _typeIcons = {
    'Dine-in': AppIcons.restaurantRounded,
    'Takeaway': AppIcons.takeoutDiningRounded,
    'Delivery': AppIcons.deliveryDiningRounded,
  };

  @override
  Widget build(BuildContext context) {
    final types = stats.byType;
    final maxType = types.fold<double>(0, (m, t) => t.revenue > m ? t.revenue : m);
    final channelTotal = stats.websiteRevenue + stats.posRevenue;
    return _Panel(
      title: 'Order types',
      subtitle: 'Revenue by how customers ordered',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (types.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No sales in this period yet', style: TextStyle(fontSize: 13, color: kMuted)),
          )
        else
          for (final t in types) ...[
            Row(children: [
              SvgIcon(_typeIcons[t.type] ?? AppIcons.receiptLongRounded, size: 15, color: kSub),
              const SizedBox(width: 8),
              Expanded(child: Text(t.type, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText))),
              Text('${t.orders} orders  ·  ', style: const TextStyle(fontSize: 12, color: kMuted)),
              Text(rs(t.revenue), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText)),
            ]),
            const SizedBox(height: 6),
            RankBar(fraction: maxType > 0 ? t.revenue / maxType : 0),
            const SizedBox(height: 14),
          ],
        const Divider(color: kBorder, height: 20),
        const Text('Website vs POS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText)),
        const SizedBox(height: 10),
        SplitBar(parts: [(stats.websiteRevenue, DashColors.series1), (stats.posRevenue, DashColors.series2)], height: 10),
        const SizedBox(height: 12),
        _ValueRow(
          color: DashColors.series1,
          icon: AppIcons.phoneAndroidRounded,
          label: 'Website · ${stats.websiteOrders} orders',
          value: rs(stats.websiteRevenue),
          share: channelTotal > 0 ? stats.websiteRevenue / channelTotal : 0,
        ),
        const SizedBox(height: 10),
        _ValueRow(
          color: DashColors.series2,
          icon: AppIcons.pointOfSaleRounded,
          label: 'POS · ${stats.posOrders} orders',
          value: rs(stats.posRevenue),
          share: channelTotal > 0 ? stats.posRevenue / channelTotal : 0,
        ),
      ]),
    );
  }
}

// ── Lists ─────────────────────────────────────────────────────────────────────
class _TopItemsCard extends StatelessWidget {
  final List<TopItem> items;

  const _TopItemsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final max = items.fold<double>(0, (m, i) => i.revenue > m ? i.revenue : m);
    return _Panel(
      title: 'Top items',
      subtitle: 'By revenue',
      child: items.isEmpty
          ? const _EmptyList('No items sold yet')
          : Column(children: [
              for (var i = 0; i < items.length; i++) ...[
                Row(children: [
                  SizedBox(
                    width: 22,
                    child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kMuted)),
                  ),
                  Expanded(
                    child: Text(items[i].name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText)),
                  ),
                  Text('${items[i].qty} sold  ·  ', style: const TextStyle(fontSize: 12, color: kMuted)),
                  Text(rs(items[i].revenue), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText)),
                ]),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: RankBar(fraction: max > 0 ? items[i].revenue / max : 0),
                ),
                const SizedBox(height: 12),
              ],
            ]),
    );
  }
}

class _TopCustomersCard extends StatelessWidget {
  final List<TopCustomer> customers;

  const _TopCustomersCard({required this.customers});

  @override
  Widget build(BuildContext context) => _Panel(
        title: 'Top customers',
        subtitle: 'Saved customers by spend',
        child: customers.isEmpty
            ? const _EmptyList('No saved customers ordered in this period')
            : Column(children: [
                for (final c in customers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: kPrimary.withValues(alpha: 0.1),
                        child: Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase(),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kPrimary)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
                          Text('${c.orders} ${c.orders == 1 ? 'order' : 'orders'} · ${c.phone}',
                              style: const TextStyle(fontSize: 11.5, color: kMuted)),
                        ]),
                      ),
                      Text(rs(c.spent), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText)),
                    ]),
                  ),
              ]),
      );
}

class _RecentOrdersCard extends StatelessWidget {
  final List<RecentOrder> orders;

  const _RecentOrdersCard({required this.orders});

  @override
  Widget build(BuildContext context) => _Panel(
        title: 'Latest orders',
        subtitle: 'Updates live',
        child: orders.isEmpty
            ? const _EmptyList('No orders yet')
            : Column(children: [
                for (final o in orders)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(o.number, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText)),
                            if (o.customerType == 'Online') ...[
                              const SizedBox(width: 6),
                              const _Tag('Web', DashColors.series1),
                            ],
                          ]),
                          Text(
                            '${o.customer.isEmpty ? 'Walk-in' : o.customer} · ${o.type} · ${DateFormat('h:mm a').format(o.createdAt)}',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: kMuted),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(rs(o.total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText)),
                        _OrderStatus(o),
                      ]),
                    ]),
                  ),
              ]),
      );
}

class _OrderStatus extends StatelessWidget {
  final RecentOrder order;

  const _OrderStatus(this.order);

  @override
  Widget build(BuildContext context) {
    final s = order.status.toLowerCase();
    final (label, color, icon) = s == 'cancelled'
        ? ('Cancelled', DashColors.critical, AppIcons.cancelOutlined)
        : s == 'pending'
            ? ('Pending', DashColors.warning, AppIcons.pendingRounded)
            : (order.paymentStatus == 'Paid' ? 'Paid' : 'Done · ${order.paymentStatus}', DashColors.good, AppIcons.checkCircleRounded);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SvgIcon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kSub)),
    ]);
  }
}

// ── Building blocks ───────────────────────────────────────────────────────────
BoxDecoration _card() => BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kBorder),
    );

class _Panel extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  final Widget? trailing;

  const _Panel({required this.title, required this.subtitle, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: _card(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kText)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: kMuted)),
              ]),
            ),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: 14),
          child,
        ]),
      );
}

class _LegendKey extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendKey({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: kSub)),
      ]);
}

/// Legend row with the value and share printed (so colour never carries it alone).
class _ValueRow extends StatelessWidget {
  final Color color;
  final AppIcon icon;
  final String label, value;
  final double share;

  const _ValueRow({required this.color, required this.icon, required this.label, required this.value, required this.share});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        SvgIcon(icon, size: 14, color: kSub),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: kText))),
        Text('${(share * 100).toStringAsFixed(0)}%  ', style: const TextStyle(fontSize: 12, color: kMuted)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText)),
      ]);
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kSub)),
      );
}

class _EmptyChart extends StatelessWidget {
  final String text;
  const _EmptyChart(this.text);

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SvgIcon(AppIcons.pointOfSaleOutlined, size: 30, color: DashColors.context),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 13, color: kMuted)),
        ]),
      );
}

class _EmptyList extends StatelessWidget {
  final String text;
  const _EmptyList(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: kMuted))),
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: _card(),
        child: Column(children: [
          const SvgIcon(AppIcons.warningAmberRounded, size: 30, color: DashColors.critical),
          const SizedBox(height: 10),
          const Text('Couldn\'t load the dashboard', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: kMuted)),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ]),
      );
}

/// First-load placeholder in the dashboard's shape.
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget card(double h) => Container(
          height: h,
          padding: const EdgeInsets.all(18),
          decoration: _card(),
          child: const Shimmer(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ShimmerBox(width: 120, height: 12),
              SizedBox(height: 12),
              ShimmerBox(width: 160, height: 26),
              Spacer(),
              ShimmerBox(height: 10),
            ]),
          ),
        );
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 1100 ? 4 : (c.maxWidth >= 620 ? 2 : 1);
      final w = (c.maxWidth - 16 * (cols - 1)) / cols;
      return Column(children: [
        Wrap(spacing: 16, runSpacing: 16, children: [for (var i = 0; i < 4; i++) SizedBox(width: w, child: card(130))]),
        const SizedBox(height: 16),
        card(320),
        const SizedBox(height: 16),
        card(300),
      ]);
    });
  }
}
