import 'package:flutter/material.dart';
import 'package:resturent_application/core/widget/shimmer.dart';
import '../../../../../core/constants/app_colors.dart';

/// Shimmer placeholder grid shown while the KDS stream loads its first batch
/// of orders. Card layout mirrors OrderCardWidget so nothing jumps on load.
class KDSSkeleton extends StatelessWidget {
  const KDSSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 360,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const _OrderCardSkeleton(),
    );
  }
}

class _OrderCardSkeleton extends StatelessWidget {
  const _OrderCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: const Shimmer(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ShimmerBox(width: 30, height: 30, radius: 8),
                SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ShimmerBox(width: 70, height: 16),
                    SizedBox(height: 6),
                    ShimmerBox(width: 50, height: 10),
                  ]),
                ),
                SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  ShimmerBox(width: 46, height: 18),
                  SizedBox(height: 4),
                  ShimmerBox(width: 40, height: 9),
                ]),
              ]),
              SizedBox(height: 10),
              Row(children: [
                ShimmerBox(width: 54, height: 20, radius: 6),
                SizedBox(width: 6),
                ShimmerBox(width: 70, height: 20, radius: 6),
                Spacer(),
                ShimmerBox(width: 76, height: 20, radius: 6),
              ]),
            ]),
          ),
        ),

        // ── Items ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Shimmer(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  ShimmerBox(width: 34, height: 10),
                  Spacer(),
                  ShimmerBox(width: 24, height: 10),
                ]),
                const SizedBox(height: 8),
                for (var i = 0; i < 3; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8)),
                    child: const Row(children: [
                      ShimmerBox(width: 18, height: 18, radius: 4),
                      SizedBox(width: 8),
                      Expanded(child: ShimmerBox(width: double.infinity, height: 12)),
                      SizedBox(width: 6),
                      ShimmerBox(width: 22, height: 14, radius: 4),
                    ]),
                  ),
              ]),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Action button ──
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Shimmer(
            child: Column(children: [
              ShimmerBox(width: double.infinity, height: 42, radius: 11),
              const SizedBox(height: 6),
              ShimmerBox(width: double.infinity, height: 32, radius: 10),
            ]),
          ),
        ),
      ]),
    );
  }
}
