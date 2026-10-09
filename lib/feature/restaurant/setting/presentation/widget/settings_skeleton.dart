import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widget/shimmer.dart';

/// One row inside a skeleton section: [fields] inputs side by side, or a
/// label + switch row when [toggle] is true.
class SkeletonRow {
  final int fields;
  final bool toggle;

  const SkeletonRow.fields(this.fields) : toggle = false;
  const SkeletonRow.toggle() : fields = 0, toggle = true;
}

/// Shimmer placeholder shaped like a settings tab: page header, section cards
/// with fields / toggles, and the action buttons. Set [preview] for tabs with a
/// side preview (Receipt).
class SettingsSkeleton extends StatelessWidget {
  final List<List<SkeletonRow>> sections;
  final bool preview;
  final bool buttons;

  const SettingsSkeleton({super.key, required this.sections, this.preview = false, this.buttons = true});

  @override
  Widget build(BuildContext context) {
    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rows in sections) _SectionSkeleton(rows: rows),
        if (buttons)
          const Shimmer(
            child: Row(children: [
              ShimmerBox(width: 110, height: 40, radius: 10),
              SizedBox(width: 12),
              ShimmerBox(width: 150, height: 40, radius: 10),
            ]),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page header
        const Shimmer(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShimmerBox(width: 200, height: 20),
            SizedBox(height: 8),
            ShimmerBox(width: 300, height: 12),
          ]),
        ),
        const SizedBox(height: 26),
        if (!preview)
          form
        else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: form),
            const SizedBox(width: 20),
            const ReceiptPreviewSkeleton(),
          ]),
      ],
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  final List<SkeletonRow> rows;

  const _SectionSkeleton({required this.rows});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Shimmer(child: ShimmerBox(width: 110, height: 10)),
      const SizedBox(height: 12),
      // Card background stays outside the shimmer so only placeholders sweep.
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Shimmer(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              rows[i].toggle ? const _ToggleSkeleton() : _FieldsSkeleton(count: rows[i].fields),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 18),
    ],
  );
}

class _FieldsSkeleton extends StatelessWidget {
  final int count;

  const _FieldsSkeleton({required this.count});

  @override
  Widget build(BuildContext context) => Row(children: [
    for (var i = 0; i < count; i++) ...[
      if (i > 0) const SizedBox(width: 12),
      const Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ShimmerBox(width: 80, height: 10),
          SizedBox(height: 7),
          ShimmerBox(height: 38, radius: 9),
        ]),
      ),
    ],
  ]);
}

class _ToggleSkeleton extends StatelessWidget {
  const _ToggleSkeleton();

  @override
  Widget build(BuildContext context) => const Row(children: [
    Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ShimmerBox(width: 140, height: 12),
        SizedBox(height: 6),
        ShimmerBox(width: 220, height: 10),
      ]),
    ),
    ShimmerBox(width: 40, height: 22, radius: 11),
  ]);
}

/// Receipt-shaped block standing in for the live receipt preview.
class ReceiptPreviewSkeleton extends StatelessWidget {
  const ReceiptPreviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 210,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Shimmer(
      child: Column(children: [
        const ShimmerBox(width: 48, height: 48, circle: true),
        const SizedBox(height: 10),
        const ShimmerBox(width: 120, height: 12),
        const SizedBox(height: 6),
        const ShimmerBox(width: 90, height: 9),
        const SizedBox(height: 16),
        for (var i = 0; i < 6; i++) ...[
          const Row(children: [
            Expanded(child: ShimmerBox(height: 9)),
            SizedBox(width: 24),
            ShimmerBox(width: 36, height: 9),
          ]),
          const SizedBox(height: 9),
        ],
        const SizedBox(height: 6),
        const ShimmerBox(height: 14),
        const SizedBox(height: 14),
        const ShimmerBox(width: 110, height: 9),
      ]),
    ),
  );
}
