import 'package:resturent_application/core/widget/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:resturent_application/core/constants/app_colors.dart';
import 'package:resturent_application/core/widget/shimmer.dart';

// Shimmer placeholders for the Orders list. Column flexes mirror _OrderTable
// (Order #, Time, Type, Customer, Table, Status, Payment, Total, print).

/// Stat cards (totals and revenue) while the numbers are still unknown.
class OrderSummaryStripSkeleton extends StatelessWidget {
  const OrderSummaryStripSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
        color: kCard,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
        child: const StatCardRowSkeleton(count: 5),
      );
}

/// Header and rows of the orders table.
class OrderTableSkeleton extends StatelessWidget {
  const OrderTableSkeleton({super.key});

  static const _rows = 14;

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(color: kCard, border: Border(bottom: BorderSide(color: kBorder))),
          child: const Shimmer(child: _Cells(header: true)),
        ),
        Expanded(
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rows,
            itemBuilder: (_, i) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: i.isEven ? kCard : kBg,
                border: Border(
                  bottom: BorderSide(color: kBorder.withValues(alpha: 0.5)),
                  left: const BorderSide(color: Colors.transparent, width: 3),
                ),
              ),
              child: const Shimmer(child: _Cells(header: false)),
            ),
          ),
        ),
      ]);
}

class _Cells extends StatelessWidget {
  final bool header;
  const _Cells({required this.header});

  @override
  Widget build(BuildContext context) {
    Widget cell(int flex, double width, double height,
            {double radius = 6, Alignment align = Alignment.centerLeft}) =>
        Expanded(
          flex: flex,
          child: Align(alignment: align, child: ShimmerBox(width: width, height: height, radius: radius)),
        );

    if (header) {
      return Row(children: [
        cell(2, 48, 11),
        cell(2, 32, 11),
        cell(2, 32, 11),
        cell(3, 56, 11),
        cell(2, 36, 11),
        cell(2, 40, 11),
        cell(2, 48, 11),
        cell(2, 32, 11, align: Alignment.centerRight),
        const SizedBox(width: 40),
      ]);
    }
    return Row(children: [
      cell(2, 70, 13),
      cell(2, 56, 12),
      cell(2, 64, 22, radius: 6),
      cell(3, 92, 12),
      cell(2, 34, 12),
      cell(2, 66, 22, radius: 20),
      cell(2, 60, 22, radius: 20),
      cell(2, 58, 13, align: Alignment.centerRight),
      const SizedBox(width: 40, child: Center(child: ShimmerBox(width: 16, height: 16, circle: true))),
    ]);
  }
}
