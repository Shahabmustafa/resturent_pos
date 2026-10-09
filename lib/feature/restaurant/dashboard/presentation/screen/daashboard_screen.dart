// lib/features/dashboard/screen/dashboard_screen.dart

import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../provider/dashboard_provider.dart';
import '../widget/dashboard_skeleton.dart';
import 'package:resturent_application/core/constants/currency.dart';

// ── AppColors (single accent color: red) ──
class AppColors {
  static const primary     = Color(0xFFB91C1C);
  static const primaryLight= Color(0xFFFEF2F2);
  // All former accent colors now resolve to the single red accent.
  static const blue        = Color(0xFFB91C1C);
  static const blueLight   = Color(0xFFFEF2F2);
  static const teal        = Color(0xFFB91C1C);
  static const tealLight   = Color(0xFFFEF2F2);
  static const purple      = Color(0xFFB91C1C);
  static const purpleLight = Color(0xFFFEF2F2);
  static const amber       = Color(0xFFB91C1C);
  static const amberLight  = Color(0xFFFEF2F2);
  static const danger      = Color(0xFFB91C1C);
  static const dangerLight = Color(0xFFFEF2F2);
  static const success     = Color(0xFFB91C1C);
  static const successLight= Color(0xFFFEF2F2);
  static const white       = Color(0xFFFFFFFF);
  static const border      = Color(0xFFE8EAF0);
  static const textDark    = Color(0xFF1A1D3A);
  static const textGrey    = Color(0xFF9396B0);
  static const textMid     = Color(0xFF3D4060);
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KpiRow(),
          const SizedBox(height: 16),
          _MidRow(),
          const SizedBox(height: 16),
          _BottomRow(),
          const SizedBox(height: 16),
          _MiniStatsRow(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════
//  KPI ROW
// ════════════════════════════════════════════
class _KpiRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpiAsync = ref.watch(dashboardKpiProvider);

    return kpiAsync.when(
      loading: () => const KpiRowSkeleton(),
      error: (e, _) => Text('Error: $e'),
      data: (kpi) {
        final revenue  = kpi['revenue'] as double;
        final orders   = kpi['orders'] as int;
        final customers= kpi['customers'] as int;
        final avg      = kpi['avg_order'] as double;

        return Row(children: [
          Expanded(child: _KpiCard(
            title: "Today's Revenue", value: formatMoney(revenue),
            change: '${orders} orders', positive: true,
            icon: AppIcons.paymentsOutlined, iconBg: AppColors.primaryLight, iconColor: AppColors.primary,
          )),
          const SizedBox(width: 12),
          Expanded(child: _KpiCard(
            title: 'Total Orders', value: '$orders',
            change: 'today', positive: true,
            icon: AppIcons.shoppingCartOutlined, iconBg: AppColors.primaryLight, iconColor: AppColors.primary,
          )),
          const SizedBox(width: 12),
          Expanded(child: _KpiCard(
            title: 'Customers Served', value: '$customers',
            change: 'unique', positive: true,
            icon: AppIcons.peopleOutline, iconBg: AppColors.primaryLight, iconColor: AppColors.primary,
          )),
          const SizedBox(width: 12),
          Expanded(child: _KpiCard(
            title: 'Avg Order Value', value: formatMoney(avg),
            change: 'per order', positive: true,
            icon: AppIcons.receiptOutlined, iconBg: AppColors.primaryLight, iconColor: AppColors.primary,
          )),
        ]);
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title, value, change;
  final bool positive;
  final AppIcon icon;
  final Color iconBg, iconColor;
  const _KpiCard({required this.title, required this.value, required this.change,
    required this.positive, required this.icon, required this.iconBg, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(width: 38, height: 38,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: SvgIcon(icon, color: iconColor, size: 18)),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6)),
              child: Text(change, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: AppColors.primary))),
        ]),
        const SizedBox(height: 14),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
            color: AppColors.textDark, letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
      ]),
    );
  }
}

// ════════════════════════════════════════════
//  MID ROW: Revenue Chart + Donut
// ════════════════════════════════════════════
class _MidRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 5, child: _RevenueChartCard()),
      const SizedBox(width: 16),
      Expanded(flex: 2, child: _OrderTypeDonut()),
    ]);
  }
}

class _RevenueChartCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RevenueChartCard> createState() => _RevenueChartCardState();
}

class _RevenueChartCardState extends ConsumerState<_RevenueChartCard> {
  static const _days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

  @override
  Widget build(BuildContext context) {
    final revenueAsync = ref.watch(weeklyRevenueProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border)),
      child: revenueAsync.when(
        loading: () => const RevenueChartSkeleton(),
        error: (e, _) => Text('Error: $e'),
        data: (data) {
          final thisWeek = data['this_week']!;
          final lastWeek = data['last_week']!;
          final thisTotal = thisWeek.fold(0.0, (a, b) => a + b);
          final lastTotal = lastWeek.fold(0.0, (a, b) => a + b);
          final maxY = [...thisWeek, ...lastWeek].fold(0.0, (a, b) => a > b ? a : b);

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 30, height: 30,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                  child: const SvgIcon(AppIcons.showChart, color: AppColors.primary, size: 15)),
              const SizedBox(width: 10),
              const Text('Revenue Overview', style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w700, color: AppColors.textDark)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('This week', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                Text(formatMoney(thisTotal),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              ]),
              const SizedBox(width: 24),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Last week', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                Text(formatMoney(lastTotal),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textGrey)),
              ]),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LineChart(LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 0.5)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50,
                      getTitlesWidget: (v, _) => Text('£${v.toInt()}', style: const TextStyle(fontSize: 9, color: AppColors.textGrey)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        return i >= 0 && i < 7 ? Text(_days[i], style: const TextStyle(fontSize: 10, color: AppColors.textGrey)) : const SizedBox();
                      })),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxY * 1.2 == 0 ? 100 : maxY * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: thisWeek.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true, color: AppColors.primary, barWidth: 2,
                    dotData: FlDotData(getDotPainter: (_, __, ___, ____) =>
                        FlDotCirclePainter(radius: 4, color: AppColors.primary, strokeWidth: 0)),
                    belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.08)),
                  ),
                  LineChartBarData(
                    spots: lastWeek.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true, color: AppColors.primary.withOpacity(0.35), barWidth: 1.5,
                    dashArray: [4, 4],
                    dotData: FlDotData(getDotPainter: (_, __, ___, ____) =>
                        FlDotCirclePainter(radius: 3, color: AppColors.primary.withOpacity(0.35), strokeWidth: 0)),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              )),
            ),
          ]);
        },
      ),
    );
  }
}

class _OrderTypeDonut extends ConsumerWidget {
  static const _colors = {
    'Dine-in': AppColors.primary,
    'Takeaway': AppColors.primary,
    'Delivery': AppColors.primary,
  };
  static const _opacities = {
    'Dine-in': 1.0,
    'Takeaway': 0.6,
    'Delivery': 0.35,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderTypeCountsProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 30, height: 30,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
              child: const SvgIcon(AppIcons.donutLarge, color: AppColors.primary, size: 15)),
          const SizedBox(width: 10),
          const Text('Order Types', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 16),
        async.when(
          loading: () => const OrderTypeSkeleton(),
          error: (e, _) => Text('$e'),
          data: (counts) {
            final total = counts.values.fold(0, (a, b) => a + b);
            return Column(children: [
              SizedBox(height: 140, child: PieChart(PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 42,
                sections: counts.entries.map((e) => PieChartSectionData(
                  value: e.value.toDouble(),
                  color: AppColors.primary.withOpacity(_opacities[e.key] ?? 1.0),
                  radius: 28, showTitle: false,
                )).toList(),
              ))),
              const SizedBox(height: 14),
              ...counts.entries.map((e) {
                final pct = total > 0 ? (e.value / total * 100).round() : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(children: [
                    Container(width: 9, height: 9,
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(_opacities[e.key] ?? 1.0), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e.key, style: const TextStyle(fontSize: 12, color: AppColors.textGrey))),
                    Text('$pct%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  ]),
                );
              }),
            ]);
          },
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════
//  BOTTOM ROW
// ════════════════════════════════════════════
class _BottomRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 5, child: _RecentOrdersCard()),
      const SizedBox(width: 16),
      Expanded(flex: 3, child: _TopSellingCard()),
      const SizedBox(width: 16),
      Expanded(flex: 3, child: _LowStockCard()),
    ]);
  }
}

class _RecentOrdersCard extends ConsumerWidget {
  static Color _statusColor(String s) => AppColors.primary;
  static Color _statusBg(String s) => AppColors.primaryLight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentOrdersProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 30, height: 30,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
              child: const SvgIcon(AppIcons.receiptRounded, color: AppColors.primary, size: 15)),
          const SizedBox(width: 10),
          const Text('Recent Orders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const Spacer(),
          TextButton(onPressed: () {}, child: const Text('View all →', style: TextStyle(fontSize: 11, color: AppColors.primary))),
        ]),
        const SizedBox(height: 8),
        const Row(children: [
          Expanded(flex: 2, child: Text('Order',    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey))),
          Expanded(flex: 2, child: Text('Customer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey))),
          Expanded(flex: 2, child: Text('Type',     style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey))),
          Expanded(flex: 3, child: Text('Amount',   style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey))),
          Expanded(flex: 2, child: Text('Status',   style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey))),
        ]),
        const Divider(color: AppColors.border, height: 12),
        async.when(
          loading: () => const RecentOrdersSkeleton(),
          error: (e, _) => Text('$e'),
          data: (orders) => Column(
            children: orders.map((o) {
              final customer = (o['customer_name'] ?? '').toString().isEmpty
                  ? (o['table_number'] ?? 'Walk-in').toString().isEmpty ? 'Walk-in' : o['table_number']
                  : o['customer_name'];
              final status = o['payment_status'] ?? 'Unpaid';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Expanded(flex: 2, child: Text(o['order_number'] ?? '',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary))),
                  Expanded(flex: 2, child: Text('$customer',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMid), overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 2, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF0F2F8), borderRadius: BorderRadius.circular(4)),
                      child: Text(o['order_type'] ?? '', style: const TextStyle(fontSize: 10, color: AppColors.textGrey)))),
                  Expanded(flex: 3, child: Text(formatMoney((o['total'] as num?) ?? 0),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark))),
                  Expanded(flex: 2, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _statusBg(status), borderRadius: BorderRadius.circular(20)),
                      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status))))),
                ]),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

class _TopSellingCard extends ConsumerWidget {
  static const _opacities = [1.0, 0.8, 0.6, 0.45, 0.3];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(topSellingProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 30, height: 30,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
              child: const SvgIcon(AppIcons.emojiEventsRounded, color: AppColors.primary, size: 15)),
          const SizedBox(width: 10),
          const Text('Top Selling', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const Spacer(),
          const Text('by revenue', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
        ]),
        const SizedBox(height: 16),
        async.when(
          loading: () => const TopSellingSkeleton(),
          error: (e, _) => Text('$e'),
          data: (items) => Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              final color = AppColors.primary.withOpacity(_opacities[i % _opacities.length]);
              final revenue = (p['revenue'] as double).toStringAsFixed(0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Row(children: [
                  Container(width: 22, height: 22, alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: i == 0 ? AppColors.primaryLight : const Color(0xFFF0F2F8),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                          color: i == 0 ? AppColors.primary : AppColors.textGrey))),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMid)),
                    const SizedBox(height: 4),
                    ClipRRect(borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: p['ratio'] as double,
                            backgroundColor: const Color(0xFFF0F2F8),
                            valueColor: AlwaysStoppedAnimation(color), minHeight: 4)),
                  ])),
                  const SizedBox(width: 10),
                  Text('£$revenue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                ]),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

class _LowStockCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lowStockProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 30, height: 30,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
              child: const SvgIcon(AppIcons.warningAmberRounded, color: AppColors.primary, size: 15)),
          const SizedBox(width: 10),
          const Flexible(child: Text('Low Stock', style: TextStyle(fontSize: 14,
              fontWeight: FontWeight.w700, color: AppColors.textDark))),
          const Spacer(),
          async.maybeWhen(
              data: (items) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                  child: Text('${items.length} items',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary))),
              orElse: () => const SizedBox()),
        ]),
        const SizedBox(height: 16),
        async.when(
          loading: () => const LowStockSkeleton(),
          error: (e, _) => Text('$e'),
          data: (items) => items.isEmpty
              ? const Text('All stock OK', style: TextStyle(fontSize: 12, color: AppColors.textGrey))
              : Column(children: items.map((item) {
            final isCritical = (item['qty'] ?? 0) < (item['min_qty'] ?? 0) / 2;
            final color = isCritical ? AppColors.primary : AppColors.primary.withOpacity(0.6);
            return Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(item['name'] ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMid), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 6),
                Text('${item['qty']} ${item['unit']}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
              ]),
            );
          }).toList()),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════
//  MINI STATS ROW
// ════════════════════════════════════════════
class _MiniStatsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(miniStatsProvider);

    return async.when(
      loading: () => const MiniStatsRowSkeleton(),
      error: (e, _) => Text('$e'),
      data: (stats) => Row(children: [
        Expanded(child: _MiniStat(
            label: 'Tables Occupied',
            value: '${stats['tables_occupied']}/${stats['tables_total']}',
            icon: AppIcons.tableRestaurantOutlined,
            iconBg: AppColors.primaryLight, iconColor: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _MiniStat(
            label: 'Kitchen Orders',
            value: '${stats['kitchen_orders']}',
            icon: AppIcons.kitchenOutlined,
            iconBg: AppColors.primaryLight, iconColor: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _MiniStat(
            label: 'Active Deliveries',
            value: '${stats['active_deliveries']}',
            icon: AppIcons.deliveryDiningOutlined,
            iconBg: AppColors.primaryLight, iconColor: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _MiniStat(
            label: 'Cash Balance',
            value: formatMoney((stats['cash_balance'] as num?) ?? 0),
            icon: AppIcons.accountBalanceWalletOutlined,
            iconBg: AppColors.primaryLight, iconColor: AppColors.primary)),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final AppIcon icon;
  final Color iconBg, iconColor;
  const _MiniStat({required this.label, required this.value, required this.icon,
    required this.iconBg, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: SvgIcon(icon, color: iconColor, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
        ])),
      ]),
    );
  }
}