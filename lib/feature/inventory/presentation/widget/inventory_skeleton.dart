import 'package:flutter/material.dart';
import 'package:resturent_application/core/widget/shimmer.dart';
import '../../../../core/constants/app_colors.dart';

/// Shimmer placeholder for the Stock tab body, shown while inventory is
/// loading for the first time. Toolbar + column flexes mirror the real
/// search/filter row and StockTableWidget so the layout doesn't jump.
class InventoryStockSkeleton extends StatelessWidget {
  const InventoryStockSkeleton({super.key});

  static const _rowCount = 10;
  static const _flex = [3, 2, 2, 2, 2, 2, 2, 2, 2];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Search + filter toolbar
      Container(
        color: kCard,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: const Shimmer(
          child: Row(children: [
            ShimmerBox(width: 220, height: 34, radius: 8),
            SizedBox(width: 10),
            ShimmerBox(width: 52, height: 28, radius: 8),
            SizedBox(width: 6),
            ShimmerBox(width: 58, height: 28, radius: 8),
            SizedBox(width: 6),
            ShimmerBox(width: 66, height: 28, radius: 8),
          ]),
        ),
      ),

      // Column header
      Container(
        color: kLight,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Shimmer(
          child: Row(children: [
            for (final f in _flex)
              Expanded(
                flex: f,
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: ShimmerBox(width: 50, height: 11),
                ),
              ),
          ]),
        ),
      ),
      const Divider(height: 1, color: kBorder),

      // Rows
      Expanded(
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: _rowCount,
          separatorBuilder: (_, __) => const Divider(height: 1, color: kBorder),
          itemBuilder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            child: const Shimmer(child: _RowSkeleton()),
          ),
        ),
      ),
    ]);
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(children: [
      Expanded(flex: 3, child: Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 110, height: 13))),
      Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 64, height: 12))),
      Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 50, height: 13))),
      Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 56, height: 12))),
      Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 60, height: 13))),
      Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 60, height: 11))),
      Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 52, height: 20, radius: 5))),
      Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 46, height: 11))),
      Expanded(
        flex: 2,
        child: Row(children: [
          ShimmerBox(width: 24, height: 24, radius: 6),
          SizedBox(width: 4),
          ShimmerBox(width: 24, height: 24, radius: 6),
          SizedBox(width: 4),
          ShimmerBox(width: 24, height: 24, radius: 6),
        ]),
      ),
    ]);
  }
}
