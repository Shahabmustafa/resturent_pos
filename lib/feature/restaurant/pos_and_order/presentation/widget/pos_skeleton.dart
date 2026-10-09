import 'package:flutter/material.dart';
import 'package:resturent_application/core/constants/app_colors.dart';
import 'package:resturent_application/core/widget/shimmer.dart';

/// Product grid placeholder for the POS menu panel. Uses the same grid delegate
/// and card structure as [ProductCardWidget] so nothing jumps when data arrives.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key});

  static const _cards = 15;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: _cards,
      itemBuilder: (_, __) => const _ProductCardSkeleton(),
    );
  }
}

class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: const Shimmer(
          child: Column(children: [
            Expanded(child: SizedBox.expand(child: ShimmerBox(radius: 0))),
            Padding(
              padding: EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ShimmerBox(width: 104, height: 12),
                SizedBox(height: 8),
                Row(children: [
                  ShimmerBox(width: 58, height: 13),
                  Spacer(),
                  ShimmerBox(width: 22, height: 22, circle: true),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
