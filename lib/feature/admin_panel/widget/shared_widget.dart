import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import 'package:resturent_application/core/constants/currency.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────
String rsFormat(double v) {
  if (v >= 1000) return formatMoneyCompact(v);
  return formatMoney(v);
}

String initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return parts[0][0].toUpperCase();
}

// ── App Card ──────────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const AppCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border, width: 0.5),
    ),
    child: child,
  );
}

// ── Status Badge ──────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final bool isOpen;
  const StatusBadge({super.key, required this.isOpen});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: isOpen ? AppColors.successLt : AppColors.dangerLt,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      isOpen ? 'Open' : 'Closed',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isOpen ? AppColors.success : AppColors.danger,
      ),
    ),
  );
}

// ── Top Bar ───────────────────────────────────────────────────────────────────
class AdminTopBar extends StatelessWidget {
  final String title, subtitle;
  final List<Widget> actions;

  const AdminTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    decoration: const BoxDecoration(
      color: AppColors.white,
      border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5)),
    ),
    child: Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.dark)),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 11, color: AppColors.grey)),
      ]),
      const Spacer(),
      ...actions,
      if (actions.isNotEmpty) const SizedBox(width: 12),
      Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryLt,
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Row(children: [
          SvgIcon(AppIcons.calendarTodayOutlined,
              size: 12, color: AppColors.primary),
          SizedBox(width: 5),
          Text('Jun 11, 2026',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    ]),
  );
}

// ── KPI Card ──────────────────────────────────────────────────────────────────
class KpiCard extends StatelessWidget {
  final String label, value;
  final AppIcon icon;
  final Color color;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SvgIcon(icon, size: 17, color: color),
      ),
      const SizedBox(height: 12),
      Text(value,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.dark)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(fontSize: 11, color: AppColors.grey)),
    ]),
  );
}