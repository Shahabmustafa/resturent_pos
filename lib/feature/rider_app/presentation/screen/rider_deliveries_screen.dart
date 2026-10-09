import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/shimmer.dart';
import '../../../../core/widget/svg_icon.dart';
import '../../../delivery/data/model/delivery_model.dart';
import '../provider/rider_provider.dart';
import '../widget/rider_actions.dart';
import '../widget/rider_order_card.dart';
import 'rider_order_detail_screen.dart';
import 'package:resturent_application/core/constants/currency.dart';

/// Deliveries tab: online switch, today's numbers, active deliveries and history.
class RiderDeliveriesScreen extends ConsumerWidget {
  const RiderDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(riderProvider);
    final n = ref.read(riderProvider.notifier);
    final me = s.me!; // the shell only shows tabs once the rider is loaded

    final active = s.active;
    final history = s.history;
    final now = DateTime.now();
    final today = history.where((o) {
      final d = o.deliveredAt?.toLocal();
      return o.status == DeliveryOrderStatus.delivered &&
          d != null &&
          d.year == now.year &&
          d.month == now.month &&
          d.day == now.day;
    }).toList();
    final cashToHandIn = today.fold<double>(0, (sum, o) => sum + o.amount);

    void openDetail(DeliveryOrder o) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => RiderOrderDetailScreen(orderId: o.id)));

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: _Header(
              rider: me,
              toggling: s.togglingOnline,
              onToggle: (online) async {
                final msg = await n.setOnline(online);
                if (msg != null && context.mounted) riderToast(context, msg, kYellow);
              },
              todayCount: today.length,
              todayEarnings: today.length * me.chargePerDelivery,
              cashToHandIn: cashToHandIn,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabsHeader(activeCount: active.length, historyCount: history.length),
          ),
        ],
        body: s.orders == null
            ? const _LoadingList()
            : TabBarView(
                children: [
                  _OrderList(
                    orders: active,
                    onRefresh: n.refresh,
                    empty: _Empty(
                      icon: AppIcons.deliveryDiningRounded,
                      title: me.status == RiderStatus.offline ? "You're offline" : 'No delivery right now',
                      body: me.status == RiderStatus.offline
                          ? 'Go online so the restaurant can assign you deliveries.'
                          : 'Stay online — new deliveries show up here instantly.',
                    ),
                    itemBuilder: (o) => RiderOrderCard(
                      order: o,
                      busy: s.working.contains(o.id),
                      onTap: () => openDetail(o),
                      onStartTrip: o.status == DeliveryOrderStatus.assigned ? () => startTrip(context, ref, o) : null,
                      onDelivered: o.status == DeliveryOrderStatus.onTheWay
                          ? () => markDelivered(context, ref, o)
                          : null,
                    ),
                  ),
                  _OrderList(
                    orders: history,
                    onRefresh: n.refresh,
                    groupByDay: true,
                    empty: const _Empty(
                      icon: AppIcons.historyRounded,
                      title: 'No past deliveries',
                      body: 'Deliveries you finish will be listed here.',
                    ),
                    itemBuilder: (o) => RiderHistoryTile(order: o, onTap: () => openDetail(o)),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Header: greeting, online status, today's numbers ─────────────────────────
class _Header extends StatelessWidget {
  final Rider rider;
  final bool toggling;
  final ValueChanged<bool> onToggle;
  final int todayCount;
  final double todayEarnings;
  final double cashToHandIn;

  const _Header({
    required this.rider,
    required this.toggling,
    required this.onToggle,
    required this.todayCount,
    required this.todayEarnings,
    required this.cashToHandIn,
  });

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, color, icon) = switch (rider.status) {
      RiderStatus.available => ("You're online", 'New deliveries will come to you', kGreen, AppIcons.wifiTethering),
      RiderStatus.busy => ('On a delivery', 'Finish it to get the next one', kYellow, AppIcons.directionsBikeRounded),
      RiderStatus.offline => (
        "You're offline",
        'Go online to start getting deliveries',
        kMuted,
        AppIcons.powerOffRounded,
      ),
    };
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimary, Color(0xFF7F1D1D)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 18, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()},',
                      style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.75)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rider.name.split(' ').first,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2.5),
                ),
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  child: Text(
                    rider.name.isEmpty ? '?' : rider.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Status card
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: SvgIcon(icon, size: 22, color: color == kMuted ? kSub : color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: kText),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: kMuted),
                      ),
                    ],
                  ),
                ),
                if (toggling)
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                    ),
                  )
                else if (rider.status == RiderStatus.busy)
                  // Can't go offline mid-delivery, so no switch here.
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kYellow.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'BUSY',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kYellow, letterSpacing: 0.8),
                    ),
                  )
                else
                  Switch(
                    value: rider.status == RiderStatus.available,
                    onChanged: onToggle,
                    activeThumbColor: Colors.white,
                    activeTrackColor: kGreen,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: kBorder,
                    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Today
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              'TODAY',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ),
          Row(
            children: [
              _Stat(icon: AppIcons.checkCircleRounded, label: 'Delivered', value: '$todayCount'),
              const SizedBox(width: 10),
              _Stat(icon: AppIcons.savingsRounded, label: 'Earned', value: formatMoney(todayEarnings)),
              const SizedBox(width: 10),
              _Stat(icon: AppIcons.paymentsRounded, label: 'Cash', value: formatMoney(cashToHandIn)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final AppIcon icon;
  final String label, value;
  const _Stat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgIcon(icon, size: 16, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.7))),
        ],
      ),
    ),
  );
}

/// Active / History switch, styled like the Earnings period selector.
class _TabsHeader extends SliverPersistentHeaderDelegate {
  final int activeCount, historyCount;
  const _TabsHeader({required this.activeCount, required this.historyCount});

  @override
  double get minExtent => 66;
  @override
  double get maxExtent => 66;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final controller = DefaultTabController.of(context);
    return Container(
      color: kBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
          ),
          child: Row(
            children: [
              for (final (i, label, count) in [(0, 'Active', activeCount), (1, 'History', historyCount)])
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.animateTo(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: controller.index == i ? kPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: controller.index == i ? Colors.white : kSub,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                            decoration: BoxDecoration(
                              color: controller.index == i ? Colors.white.withValues(alpha: 0.22) : kBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: controller.index == i ? Colors.white : kSub,
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
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabsHeader old) => old.activeCount != activeCount || old.historyCount != historyCount;
}

class _OrderList extends StatelessWidget {
  final List<DeliveryOrder> orders;
  final Future<void> Function() onRefresh;
  final Widget empty;
  final Widget Function(DeliveryOrder) itemBuilder;

  /// Puts a "Today" / "Yesterday" / date heading above each day's orders.
  final bool groupByDay;

  const _OrderList({
    required this.orders,
    required this.onRefresh,
    required this.empty,
    required this.itemBuilder,
    this.groupByDay = false,
  });

  static DateTime _day(DeliveryOrder o) {
    final d = (o.deliveredAt ?? o.createdAt).toLocal();
    return DateTime(d.year, d.month, d.day);
  }

  static String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('EEE, d MMM').format(day);
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        color: kPrimary,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [empty],
        ),
      );
    }

    // The stream is sorted by creation time; headings follow delivery time, so re-sort by that.
    final sorted = groupByDay
        ? ([...orders]..sort((a, b) => (b.deliveredAt ?? b.createdAt).compareTo(a.deliveredAt ?? a.createdAt)))
        : orders;
    final children = <Widget>[];
    DateTime? lastDay;
    for (final o in sorted) {
      if (groupByDay) {
        final day = _day(o);
        if (day != lastDay) {
          children.add(_DayHeading(_dayLabel(day), first: lastDay == null));
          lastDay = day;
        }
      } else if (children.isNotEmpty) {
        children.add(const SizedBox(height: 12));
      }
      children.add(
        Padding(
          padding: EdgeInsets.only(bottom: groupByDay ? 10 : 0),
          child: itemBuilder(o),
        ),
      );
    }

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
        children: children,
      ),
    );
  }
}

class _DayHeading extends StatelessWidget {
  final String label;
  final bool first;
  const _DayHeading(this.label, {required this.first});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(4, first ? 2 : 12, 4, 8),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: kMuted, letterSpacing: 0.8),
    ),
  );
}

/// Placeholder delivery cards while the first list loads.
class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) => ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
    children: [
      for (var i = 0; i < 2; i++)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kBorder),
          ),
          child: const Shimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerBox(width: 80, height: 16),
                    Spacer(),
                    ShimmerBox(width: 76, height: 22, radius: 11),
                  ],
                ),
                SizedBox(height: 14),
                ShimmerBox(height: 5, radius: 3),
                SizedBox(height: 18),
                ShimmerBox(width: 150, height: 15),
                SizedBox(height: 12),
                ShimmerBox(height: 13),
                SizedBox(height: 8),
                ShimmerBox(width: 200, height: 13),
                SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: ShimmerBox(height: 42, radius: 12)),
                    SizedBox(width: 10),
                    Expanded(child: ShimmerBox(height: 42, radius: 12)),
                  ],
                ),
                SizedBox(height: 16),
                ShimmerBox(height: 54, radius: 14),
              ],
            ),
          ),
        ),
    ],
  );
}

class _Empty extends StatelessWidget {
  final AppIcon icon;
  final String title, body;
  const _Empty({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: SvgIcon(icon, size: 40, color: kPrimary),
      ),
      const SizedBox(height: 16),
      Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kText),
      ),
      const SizedBox(height: 6),
      Text(
        body,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13.5, color: kSub, height: 1.5),
      ),
    ],
  );
}
