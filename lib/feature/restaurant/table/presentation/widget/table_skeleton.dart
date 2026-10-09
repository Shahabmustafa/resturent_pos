import 'package:resturent_application/core/widget/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:resturent_application/core/widget/shimmer.dart';
import '../../../../../core/constants/app_colors.dart';

// Shimmer placeholder for the tables page body. Sizes and column flexes mirror
// TableSummaryRow / TableDataWidget so the layout does not jump on load.

/// Summary cards + data table card, shown while tables are loading.
class TableBodySkeleton extends StatelessWidget {
  const TableBodySkeleton({super.key});

  static const _rowCount = 8;

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatCardRowSkeleton(),
          SizedBox(height: 24),
          _TableCardSkeleton(rows: _rowCount),
        ],
      ),
    );
  }
}


class _TableCardSkeleton extends StatelessWidget {
  final int rows;
  const _TableCardSkeleton({required this.rows});

  // Same flex as the real header/rows: #, Table No., Floor, Section, Capacity, Status, Actions.
  static const _flex = [1, 2, 2, 2, 2, 2, 2];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: const [BoxShadow(color: Color(0x0A000020), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
          child: const Shimmer(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ShimmerBox(width: 64, height: 16),
                Spacer(),
                ShimmerBox(width: 220, height: 36, radius: 8),
              ]),
              SizedBox(height: 12),
              Row(children: [
                ShimmerBox(width: 44, height: 30),
                SizedBox(width: 6),
                ShimmerBox(width: 86, height: 30),
                SizedBox(width: 6),
                ShimmerBox(width: 80, height: 30),
                SizedBox(width: 6),
                ShimmerBox(width: 80, height: 30),
                SizedBox(width: 18),
                ShimmerBox(width: 92, height: 32, radius: 7),
              ]),
            ]),
          ),
        ),

        // Column header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FC),
            border: Border(bottom: BorderSide(color: kBorder)),
          ),
          child: Shimmer(
            child: Row(children: [
              for (final f in _flex)
                Expanded(
                  flex: f,
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: ShimmerBox(width: 44, height: 11),
                  ),
                ),
            ]),
          ),
        ),

        // Rows
        for (var i = 0; i < rows; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            decoration: BoxDecoration(
              border: i == rows - 1 ? null : const Border(bottom: BorderSide(color: Color(0xFFF0F2F8))),
            ),
            child: const Shimmer(child: _RowSkeleton()),
          ),

        // Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FC),
            border: Border(top: BorderSide(color: kBorder)),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: const Shimmer(child: ShimmerBox(width: 150, height: 12)),
        ),
      ]),
    );
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(children: [
      // #
      Expanded(flex: 1, child: Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 26, height: 26))),
      // Table No.
      Expanded(
        flex: 2,
        child: Row(children: [
          ShimmerBox(width: 26, height: 26, radius: 7),
          SizedBox(width: 8),
          ShimmerBox(width: 44, height: 13),
        ]),
      ),
      // Floor, Section, Capacity
      Expanded(flex: 2, child: _IconText(textWidth: 60)),
      Expanded(flex: 2, child: _IconText(textWidth: 56)),
      Expanded(flex: 2, child: _IconText(textWidth: 52)),
      // Status badge
      Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 92, height: 26))),
      // Actions
      Expanded(
        flex: 2,
        child: Row(children: [
          ShimmerBox(width: 28, height: 28, radius: 8),
          SizedBox(width: 6),
          ShimmerBox(width: 28, height: 28, radius: 8),
        ]),
      ),
    ]);
  }
}

class _IconText extends StatelessWidget {
  final double textWidth;
  const _IconText({required this.textWidth});

  @override
  Widget build(BuildContext context) => Row(children: [
        const ShimmerBox(width: 13, height: 13, circle: true),
        const SizedBox(width: 5),
        ShimmerBox(width: textWidth, height: 13),
      ]);
}
