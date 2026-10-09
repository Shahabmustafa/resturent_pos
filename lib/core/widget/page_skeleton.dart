import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'shimmer.dart';

/// Shimmer placeholder for pages made of stat cards + a table/list card
/// (delivery, customers, cash register, users).
class PageSkeleton extends StatelessWidget {
  final int statCount;
  final int rows;
  final int columns;
  final EdgeInsetsGeometry padding;

  const PageSkeleton({
    super.key,
    this.statCount = 4,
    this.rows = 8,
    this.columns = 5,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      child: Column(children: [
        if (statCount > 0) ...[
          _StatRowSkeleton(count: statCount),
          const SizedBox(height: 20),
        ],
        _TableCardSkeleton(rows: rows, columns: columns),
      ]),
    );
  }
}

/// Shimmer placeholder for a report tab: stat cards + chart card.
class ReportSkeleton extends StatelessWidget {
  const ReportSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const _StatRowSkeleton(count: 4),
        const SizedBox(height: 20),
        Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration,
          child: const Shimmer(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ShimmerBox(width: 140, height: 16),
              SizedBox(height: 20),
              Expanded(child: ShimmerBox(width: double.infinity, radius: 10)),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        const _TableCardSkeleton(rows: 4, columns: 4),
      ]),
    );
  }
}

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: kBorder),
);

class _StatRowSkeleton extends StatelessWidget {
  final int count;
  const _StatRowSkeleton({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (var i = 0; i < count; i++) ...[
        if (i > 0) const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder),
            ),
            child: const Shimmer(
              child: Row(children: [
                ShimmerBox(width: 38, height: 38, radius: 10),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 56, height: 20),
                      SizedBox(height: 6),
                      ShimmerBox(width: 80, height: 11),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ],
    ]);
  }
}

class _TableCardSkeleton extends StatelessWidget {
  final int rows;
  final int columns;
  const _TableCardSkeleton({required this.rows, required this.columns});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
          child: const Shimmer(
            child: Row(children: [
              ShimmerBox(width: 90, height: 16),
              Spacer(),
              ShimmerBox(width: 220, height: 36, radius: 8),
            ]),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          color: const Color(0xFFF8F9FC),
          child: Shimmer(child: _cells(11, 50)),
        ),
        for (var i = 0; i < rows; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: i == rows - 1 ? null : const Border(bottom: BorderSide(color: Color(0xFFF0F2F8))),
            ),
            child: Shimmer(child: _cells(13, 80)),
          ),
      ]),
    );
  }

  Widget _cells(double height, double width) => Row(children: [
        for (var c = 0; c < columns; c++)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ShimmerBox(width: width - (c % 3) * 12, height: height),
            ),
          ),
      ]);
}
