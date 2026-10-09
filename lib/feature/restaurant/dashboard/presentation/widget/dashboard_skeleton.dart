import 'package:flutter/material.dart';
import 'package:resturent_application/core/widget/shimmer.dart';

// Shimmer placeholders for the dashboard. Sizes mirror the loaded widgets in
// daashboard_screen.dart so the layout does not jump when data arrives.

const _border = Color(0xFFE8EAF0);

BoxDecoration _cardDecoration(double radius) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _border),
    );

/// Four KPI cards, replaces the whole KPI row while loading.
class KpiRowSkeleton extends StatelessWidget {
  const KpiRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          const Expanded(child: _KpiCardSkeleton()),
        ],
      ]);
}

class _KpiCardSkeleton extends StatelessWidget {
  const _KpiCardSkeleton();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(16),
        child: const Shimmer(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              ShimmerBox(width: 38, height: 38, radius: 10),
              ShimmerBox(width: 64, height: 22),
            ]),
            SizedBox(height: 14),
            ShimmerBox(width: 110, height: 24),
            SizedBox(height: 8),
            ShimmerBox(width: 90, height: 12),
          ]),
        ),
      );
}

/// Four mini stat cards, replaces the whole mini-stats row while loading.
class MiniStatsRowSkeleton extends StatelessWidget {
  const MiniStatsRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(14),
              child: const Shimmer(
                child: Row(children: [
                  ShimmerBox(width: 36, height: 36, radius: 10),
                  SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ShimmerBox(width: 56, height: 16),
                    SizedBox(height: 6),
                    ShimmerBox(width: 84, height: 11),
                  ]),
                ]),
              ),
            ),
          ),
        ],
      ]);
}

/// Content of the revenue chart card (header, totals and bars).
class RevenueChartSkeleton extends StatelessWidget {
  const RevenueChartSkeleton({super.key});

  static const _bars = [0.45, 0.7, 0.55, 0.85, 0.65, 0.95, 0.6];
  static const _chartHeight = 180.0;

  @override
  Widget build(BuildContext context) => Shimmer(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            ShimmerBox(width: 30, height: 30, radius: 8),
            SizedBox(width: 10),
            ShimmerBox(width: 130, height: 14),
          ]),
          const SizedBox(height: 14),
          const Row(children: [
            _Total(),
            SizedBox(width: 24),
            _Total(),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: _chartHeight,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final h in _bars)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ShimmerBox(height: _chartHeight * h, radius: 6),
                  ),
                ),
            ]),
          ),
        ]),
      );
}

class _Total extends StatelessWidget {
  const _Total();

  @override
  Widget build(BuildContext context) => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ShimmerBox(width: 52, height: 10),
        SizedBox(height: 6),
        ShimmerBox(width: 96, height: 17),
      ]);
}

/// Content of the order-type donut card (ring and legend).
class OrderTypeSkeleton extends StatelessWidget {
  const OrderTypeSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Shimmer(
        child: Column(children: [
          const SizedBox(height: 140, child: Center(child: ShimmerBox(width: 128, height: 128, circle: true))),
          const SizedBox(height: 14),
          for (var i = 0; i < 3; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 7),
              child: Row(children: [
                ShimmerBox(width: 8, height: 8, circle: true),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 12)),
                SizedBox(width: 8),
                ShimmerBox(width: 28, height: 12),
              ]),
            ),
        ]),
      );
}

/// Rows of the recent orders table.
class RecentOrdersSkeleton extends StatelessWidget {
  const RecentOrdersSkeleton({super.key});

  static const _flex = [2, 2, 2, 3, 2];

  @override
  Widget build(BuildContext context) => Shimmer(
        child: Column(children: [
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                for (final f in _flex)
                  Expanded(
                    flex: f,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: ShimmerBox(height: 18),
                    ),
                  ),
              ]),
            ),
        ]),
      );
}

/// Rows of the top selling list (rank badge, name, progress bar, amount).
class TopSellingSkeleton extends StatelessWidget {
  const TopSellingSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Shimmer(
        child: Column(children: [
          for (var i = 0; i < 5; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 13),
              child: Row(children: [
                ShimmerBox(width: 22, height: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ShimmerBox(width: 90, height: 12),
                    SizedBox(height: 6),
                    ShimmerBox(height: 4, radius: 4),
                  ]),
                ),
                SizedBox(width: 10),
                ShimmerBox(width: 52, height: 12),
              ]),
            ),
        ]),
      );
}

/// Rows of the low stock list (dot, name, quantity).
class LowStockSkeleton extends StatelessWidget {
  const LowStockSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Shimmer(
        child: Column(children: [
          for (var i = 0; i < 5; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 11),
              child: Row(children: [
                ShimmerBox(width: 7, height: 7, circle: true),
                SizedBox(width: 10),
                Expanded(child: ShimmerBox(height: 12)),
                SizedBox(width: 12),
                ShimmerBox(width: 40, height: 12),
              ]),
            ),
        ]),
      );
}
