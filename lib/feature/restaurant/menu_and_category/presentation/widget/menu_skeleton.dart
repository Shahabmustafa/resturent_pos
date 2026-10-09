import 'package:resturent_application/core/widget/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:resturent_application/core/widget/shimmer.dart';
import '../../../../../core/constants/app_colors.dart';

// Shimmer placeholders for the Menu & Categories screen. Sizes mirror the
// loaded widgets (categories table, item cards, deal cards) so the layout does
// not jump when data arrives.

/// Body skeleton for the tab at [tabIndex]: 0 categories, 1 menu items, 2 deals.
class MenuBodySkeleton extends StatelessWidget {
  final int tabIndex;
  const MenuBodySkeleton({super.key, required this.tabIndex});

  @override
  Widget build(BuildContext context) => switch (tabIndex) {
        0 => const _CategoriesSkeleton(),
        1 => const _ItemsSkeleton(),
        _ => const _DealsSkeleton(),
      };
}

/// Placeholder for the stat cards while the counts are unknown.
class MenuStatsStripSkeleton extends StatelessWidget {
  const MenuStatsStripSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
        color: kCard,
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
        child: const StatCardRowSkeleton(),
      );
}

// ── Categories ───────────────────────────────────────────────────────────────

class _CategoriesSkeleton extends StatelessWidget {
  const _CategoriesSkeleton();

  static const _rows = 6;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBorder),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: kLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: const Shimmer(
                child: Row(children: [
                  SizedBox(width: 24),
                  Expanded(flex: 3, child: Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 60, height: 12))),
                  Expanded(flex: 4, child: Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 72, height: 12))),
                  SizedBox(width: 90, child: Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 36, height: 12))),
                  SizedBox(width: 80, child: Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 48, height: 12))),
                ]),
              ),
            ),
            for (var i = 0; i < _rows; i++) ...[
              const Divider(height: 1, color: kBorder),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Shimmer(
                  child: Row(children: [
                    ShimmerBox(width: 12, height: 12, circle: true),
                    SizedBox(width: 12),
                    Expanded(flex: 3, child: Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 96, height: 14))),
                    Expanded(flex: 4, child: Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 180, height: 13))),
                    SizedBox(width: 90, child: Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 68, height: 26, radius: 6))),
                    SizedBox(
                      width: 80,
                      child: Row(children: [
                        ShimmerBox(width: 22, height: 22, radius: 6),
                        SizedBox(width: 10),
                        ShimmerBox(width: 22, height: 22, radius: 6),
                      ]),
                    ),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      );
}

// ── Menu items ───────────────────────────────────────────────────────────────

class _ItemsSkeleton extends StatelessWidget {
  const _ItemsSkeleton();

  static const _cards = 8;

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          color: kCard,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: Shimmer(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(children: [
                for (final w in const [70.0, 104.0, 92.0, 118.0, 98.0, 84.0]) ...[
                  ShimmerBox(width: w, height: 32, radius: 20),
                  const SizedBox(width: 8),
                ],
              ]),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: List.generate(_cards, (_) => const _ItemCardSkeleton()),
            ),
          ),
        ),
      ]);
}

class _ItemCardSkeleton extends StatelessWidget {
  const _ItemCardSkeleton();

  @override
  Widget build(BuildContext context) => Container(
        width: 240,
        height: 226,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: const Shimmer(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ShimmerBox(height: 110, radius: 0),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ShimmerBox(width: 130, height: 14),
                    SizedBox(height: 8),
                    ShimmerBox(width: 64, height: 15),
                    SizedBox(height: 6),
                    ShimmerBox(width: 150, height: 11),
                    Spacer(),
                    Row(children: [
                      Expanded(child: ShimmerBox(height: 30, radius: 8)),
                      SizedBox(width: 8),
                      ShimmerBox(width: 40, height: 30, radius: 8),
                    ]),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      );
}

// ── Deals ────────────────────────────────────────────────────────────────────

class _DealsSkeleton extends StatelessWidget {
  const _DealsSkeleton();

  static const _cards = 3;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          for (var i = 0; i < _cards; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            const _DealCardSkeleton(),
          ],
        ]),
      );
}

class _DealCardSkeleton extends StatelessWidget {
  const _DealCardSkeleton();

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
            decoration: const BoxDecoration(
              color: kLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: kBorder)),
            ),
            child: const Shimmer(
              child: Row(children: [
                ShimmerBox(width: 34, height: 34, radius: 10),
                SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ShimmerBox(width: 150, height: 15),
                    SizedBox(height: 6),
                    ShimmerBox(width: 240, height: 12),
                  ]),
                ),
                ShimmerBox(width: 72, height: 26, radius: 8),
              ]),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(18),
            child: Shimmer(
              child: Row(children: [
                ShimmerBox(width: 130, height: 38, radius: 10),
                SizedBox(width: 10),
                ShimmerBox(width: 130, height: 38, radius: 10),
                SizedBox(width: 10),
                ShimmerBox(width: 130, height: 38, radius: 10),
                Spacer(),
                ShimmerBox(width: 90, height: 24),
              ]),
            ),
          ),
        ]),
      );
}
