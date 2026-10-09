import 'package:resturent_application/core/widget/stat_card.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/model/delivery_model.dart';
import 'delivery_micro_widgets.dart';
import 'package:resturent_application/core/constants/currency.dart';

// ─── Summary Card ─────────────────────────────────────────────────────────────

// ─── Reports Tab ──────────────────────────────────────────────────────────────

class ReportsTabWidget extends StatelessWidget {
  final List<Rider> riders;
  final List<DeliveryOrder> orders;

  const ReportsTabWidget(
      {super.key, required this.riders, required this.orders});

  @override
  Widget build(BuildContext context) {
    final totalDel =
        orders.where((o) => o.status == DeliveryOrderStatus.delivered).length;
    final totalRev = orders
        .where((o) => o.status == DeliveryOrderStatus.delivered)
        .fold(0.0, (s, o) => s + o.amount);
    final totalRidersEarn =
        riders.fold(0.0, (s, r) => s + r.totalEarnings);
    final today = DateTime.now();
    final todayDel = orders
        .where((o) =>
            o.status == DeliveryOrderStatus.delivered &&
            o.deliveredAt != null &&
            o.deliveredAt!.day == today.day)
        .length;

    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              StatCardRow(cards: [
                StatCardData(AppIcons.checkCircleRounded, 'Total Delivered', '$totalDel orders', kGreen),
                StatCardData(AppIcons.todayRounded, "Today's Deliveries", '$todayDel orders', kBlue),
                StatCardData(AppIcons.paymentsRounded, 'Total Revenue', formatMoney(totalRev), kPrimary),
                StatCardData(AppIcons.accountBalanceWalletRounded, 'Rider Earnings',
                    formatMoney(totalRidersEarn), kPurple),
              ]),
              const SizedBox(height: 24),

              // Rider Report Table
              const Text('Rider-wise Report',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kText)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kBorder),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x08000020),
                          blurRadius: 8,
                          offset: Offset(0, 3))
                    ]),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: const BoxDecoration(
                        color: kLight,
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(13)),
                        border: Border(
                            bottom: BorderSide(color: kBorder))),
                    child: const Row(children: [
                      HWidget('Rider', flex: 3),
                      HWidget('Vehicle', flex: 2),
                      HWidget('Total Deliveries', flex: 2),
                      HWidget('Charge/Del', flex: 2),
                      HWidget('Total Earnings', flex: 2),
                      HWidget('Status', flex: 2),
                    ]),
                  ),
                  ...riders.asMap().entries.map((e) {
                    final r = e.value;
                    final isLast = e.key == riders.length - 1;
                    final sc = r.status == RiderStatus.available
                        ? kGreen
                        : r.status == RiderStatus.busy
                            ? kYellow
                            : kMuted;
                    final sl = r.status == RiderStatus.available
                        ? 'Available'
                        : r.status == RiderStatus.busy
                            ? 'Busy'
                            : 'Offline';
                    return Container(
                      decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : const Border(
                                  bottom: BorderSide(color: kBorder))),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 13),
                      child: Row(children: [
                        Expanded(
                            flex: 3,
                            child: Row(children: [
                              CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      kPrimary.withOpacity(0.12),
                                  child: Text(r.name[0],
                                      style: const TextStyle(
                                          color: kPrimary,
                                          fontWeight: FontWeight.w800))),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(r.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: kText)),
                                    Text(r.phone,
                                        style: const TextStyle(
                                            fontSize: 10, color: kMuted)),
                                  ])),
                            ])),
                        Expanded(
                            flex: 2,
                            child: Text(r.vehicle,
                                style: const TextStyle(
                                    fontSize: 12, color: kSub))),
                        Expanded(
                            flex: 2,
                            child: Row(children: [
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: kBlue.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(6)),
                                  child: Text('${r.totalDeliveries}',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: kBlue))),
                            ])),
                        Expanded(
                            flex: 2,
                            child: Text(
                                formatMoney(r.chargePerDelivery),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: kText))),
                        Expanded(
                            flex: 2,
                            child: Row(children: [
                              const SvgIcon(AppIcons.trendingUpRounded,
                                  size: 14, color: kGreen),
                              const SizedBox(width: 4),
                              Text(
                                  formatMoney(r.totalEarnings),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: kGreen)),
                            ])),
                        Expanded(
                            flex: 2,
                            child: StatusBadgeWidget(sl, sc)),
                      ]),
                    );
                  }),
                ]),
              ),

              const SizedBox(height: 24),
              // Recent delivered orders
              const Text('Recent Delivered Orders',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kText)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kBorder),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x08000020),
                          blurRadius: 8,
                          offset: Offset(0, 3))
                    ]),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: const BoxDecoration(
                        color: kLight,
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(13)),
                        border: Border(
                            bottom: BorderSide(color: kBorder))),
                    child: const Row(children: [
                      HWidget('Order', flex: 2),
                      HWidget('Customer', flex: 3),
                      HWidget('Amount', flex: 2),
                      HWidget('Rider', flex: 2),
                      HWidget('Delivered At', flex: 2),
                    ]),
                  ),
                  ...orders
                      .where((o) =>
                          o.status == DeliveryOrderStatus.delivered)
                      .toList()
                      .asMap()
                      .entries
                      .map((e) {
                    final o = e.value;
                    final deliveredList = orders
                        .where((x) =>
                            x.status == DeliveryOrderStatus.delivered)
                        .length;
                    final isLast = e.key == deliveredList - 1;
                    final rName = o.riderId == null
                        ? '—'
                        : riders
                            .firstWhere((r) => r.id == o.riderId,
                                orElse: () => Rider(
                                    id: "",
                                    name: '—',
                                    phone: '',
                                    vehicle: '',
                                    status: RiderStatus.offline,
                                    chargePerDelivery: 0,
                                    totalDeliveries: 0,
                                    totalEarnings: 0))
                            .name;
                    final dt = o.deliveredAt;
                    final dtStr = dt == null
                        ? '—'
                        : '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                    return Container(
                      decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : const Border(
                                  bottom: BorderSide(color: kBorder))),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 11),
                      child: Row(children: [
                        Expanded(
                            flex: 2,
                            child: Text(o.orderNum,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: kPrimary))),
                        Expanded(
                            flex: 3,
                            child: Text(o.customerName,
                                style: const TextStyle(
                                    fontSize: 13, color: kText))),
                        Expanded(
                            flex: 2,
                            child: Text(
                                formatMoney(o.amount),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: kText))),
                        Expanded(
                            flex: 2,
                            child: Text(rName,
                                style: const TextStyle(
                                    fontSize: 12, color: kSub))),
                        Expanded(
                            flex: 2,
                            child: Row(children: [
                              const SvgIcon(AppIcons.checkCircleRounded,
                                  size: 13, color: kGreen),
                              const SizedBox(width: 4),
                              Text(dtStr,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: kGreen,
                                      fontWeight: FontWeight.w700)),
                            ])),
                      ]),
                    );
                  }),
                ]),
              ),
            ]));
  }
}
