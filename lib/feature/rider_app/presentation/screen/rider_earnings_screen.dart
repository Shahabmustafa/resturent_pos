import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import '../../../delivery/data/model/delivery_model.dart';
import '../provider/rider_provider.dart';
import 'package:resturent_application/core/constants/currency.dart';

String _rs(double v) => formatMoney(v);

/// Earnings tab: deliveries, earnings and cash collected for a period, day by day.
class RiderEarningsScreen extends ConsumerStatefulWidget {
  const RiderEarningsScreen({super.key});

  @override
  ConsumerState<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends ConsumerState<RiderEarningsScreen> {
  static const _periods = [(1, 'Today'), (7, '7 days'), (30, '30 days')];
  int _days = 1;

  @override
  Widget build(BuildContext context) {
    final charge = ref.watch(riderProvider.select((s) => s.me?.chargePerDelivery ?? 0));
    final async = ref.watch(riderEarningsProvider(_days));

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () => ref.refresh(riderEarningsProvider(_days).future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 16, 16, 24),
        children: [
          const Text(
            'Earnings',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kText),
          ),
          const SizedBox(height: 4),
          const Text('What you delivered and what you earned', style: TextStyle(fontSize: 13.5, color: kSub)),
          const SizedBox(height: 18),

          // Period selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: [
                for (final (days, label) in _periods)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _days = days),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: _days == days ? kPrimary : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: _days == days ? Colors.white : kSub,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ...async.when(
            loading: () => const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator(color: kPrimary)),
              ),
            ],
            error: (_, _) => [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Could not load earnings. Pull down to try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kSub),
                ),
              ),
            ],
            data: (orders) => _content(orders, charge),
          ),
        ],
      ),
    );
  }

  List<Widget> _content(List<DeliveryOrder> orders, double charge) {
    final cash = orders.fold<double>(0, (sum, o) => sum + o.amount);
    final earned = orders.length * charge;

    // Group by local day, newest first.
    final byDay = <DateTime, List<DeliveryOrder>>{};
    for (final o in orders) {
      final d = (o.deliveredAt ?? o.createdAt).toLocal();
      byDay.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(o);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return [
      // Big earnings card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kPrimary, Color(0xFF7F1D1D)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You earned', style: TextStyle(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.8))),
            const SizedBox(height: 4),
            Text(
              _rs(earned),
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              '${orders.length} ${orders.length == 1 ? 'delivery' : 'deliveries'} × ${_rs(charge)}',
              style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.75)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          _MiniStat(icon: AppIcons.checkCircleRounded, color: kGreen, label: 'Delivered', value: '${orders.length}'),
          const SizedBox(width: 12),
          _MiniStat(icon: AppIcons.paymentsRounded, color: kBlue, label: 'Cash collected', value: _rs(cash)),
        ],
      ),
      const SizedBox(height: 22),

      if (orders.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Column(
            children: [
              SvgIcon(AppIcons.savingsRounded, size: 44, color: kMuted),
              SizedBox(height: 10),
              Text('No deliveries in this period yet', style: TextStyle(fontSize: 14.5, color: kSub)),
            ],
          ),
        )
      else ...[
        const Text(
          'Day by day',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kText),
        ),
        const SizedBox(height: 10),
        for (final day in days) ...[_DayRow(day: day, orders: byDay[day]!, charge: charge), const SizedBox(height: 10)],
      ],
      const SizedBox(height: 6),
      Text(
        'Earnings are worked out at your current rate of ${_rs(charge)} per delivery. '
        'Hand the cash you collect to the counter.',
        style: const TextStyle(fontSize: 12, color: kMuted, height: 1.5),
      ),
    ];
  }
}

class _MiniStat extends StatelessWidget {
  final AppIcon icon;
  final Color color;
  final String label, value;
  const _MiniStat({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: SvgIcon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kText),
                  ),
                ),
                Text(label, style: const TextStyle(fontSize: 11.5, color: kMuted)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// One day: date, delivery count, cash collected and earnings; expands to the deliveries.
class _DayRow extends StatelessWidget {
  final DateTime day;
  final List<DeliveryOrder> orders;
  final double charge;
  const _DayRow({required this.day, required this.orders, required this.charge});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final label = day == today
        ? 'Today'
        : day == today.subtract(const Duration(days: 1))
        ? 'Yesterday'
        : DateFormat('EEE, d MMM').format(day);
    final cash = orders.fold<double>(0, (sum, o) => sum + o.amount);

    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Theme(
        // Drop the ExpansionTile's default divider lines.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kText),
          ),
          subtitle: Text(
            '${orders.length} ${orders.length == 1 ? 'delivery' : 'deliveries'} • Cash ${_rs(cash)}',
            style: const TextStyle(fontSize: 12.5, color: kMuted),
          ),
          trailing: Text(
            _rs(orders.length * charge),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kGreen),
          ),
          children: [
            for (final o in orders)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Text(
                      DateFormat('h:mm a').format((o.deliveredAt ?? o.createdAt).toLocal()),
                      style: const TextStyle(fontSize: 12.5, color: kMuted),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${o.orderNum} • ${o.customerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5, color: kText, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(_rs(o.amount), style: const TextStyle(fontSize: 13.5, color: kSub)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
