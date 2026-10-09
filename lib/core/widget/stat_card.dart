import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'shimmer.dart';
import 'svg_icon.dart';

/// One summary number at the top of a screen (e.g. "5 · Available").
class StatCardData {
  final AppIcon icon;
  final String label;
  final String value;
  final Color color;

  const StatCardData(this.icon, this.label, this.value, this.color);
}

/// Row of equal-width stat cards used at the top of every POS screen.
/// Cards keep a fixed height; below 640px they wrap into two columns.
class StatCardRow extends StatelessWidget {
  final List<StatCardData> cards;

  const StatCardRow({super.key, required this.cards});

  static const height = 76.0;
  static const gap = 12.0;

  @override
  Widget build(BuildContext context) {
    return _StatGrid(
      count: cards.length,
      itemBuilder: (i) => _StatCard(data: cards[i]),
    );
  }
}

/// Shimmer placeholder with the same size as [StatCardRow].
class StatCardRowSkeleton extends StatelessWidget {
  final int count;

  const StatCardRowSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return _StatGrid(
      count: count,
      itemBuilder: (_) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: _cardDecoration,
        child: const Shimmer(
          child: Row(children: [
            ShimmerBox(width: 42, height: 42, radius: 12),
            SizedBox(width: 14),
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              ShimmerBox(width: 48, height: 20),
              SizedBox(height: 6),
              ShimmerBox(width: 80, height: 11),
            ]),
          ]),
        ),
      ),
    );
  }
}

final _cardDecoration = BoxDecoration(
  color: kCard,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: kBorder),
);

class _StatGrid extends StatelessWidget {
  final int count;
  final Widget Function(int index) itemBuilder;

  const _StatGrid({required this.count, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth < 640 ? 2 : count;
      final width = (c.maxWidth - StatCardRow.gap * (cols - 1)) / cols;
      return Wrap(
        spacing: StatCardRow.gap,
        runSpacing: StatCardRow.gap,
        children: [
          for (var i = 0; i < count; i++)
            SizedBox(width: width, height: StatCardRow.height, child: itemBuilder(i)),
        ],
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final StatCardData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _cardDecoration.copyWith(
        boxShadow: [BoxShadow(color: data.color.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: SvgIcon(data.icon, color: data.color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: kText, letterSpacing: -0.3, height: 1.15)),
              const SizedBox(height: 2),
              Text(data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ]),
    );
  }
}
