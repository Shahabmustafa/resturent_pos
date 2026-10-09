import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SectionCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey, letterSpacing: 0.5)),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
      const SizedBox(height: 18),
    ],
  );
}

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const PageHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
      ],
    ),
  );
}