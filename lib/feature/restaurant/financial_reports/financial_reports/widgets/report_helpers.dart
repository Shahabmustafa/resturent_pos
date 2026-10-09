import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resturent_application/core/constants/currency.dart';

// ─── App Colors (match your app_colors.dart) ─────────────────────────────────
const kPrimary  = Color(0xFFB91C1C);
const kBg      = Color(0xFFF5F5F5);
const kCard    = Color(0xFFFFFFFF);
const kBorder  = Color(0xFFE5E7EB);
const kText    = Color(0xFF111827);
const kMuted   = Color(0xFF6B7280);
const kSub     = Color(0xFF9CA3AF);
const kLight   = Color(0xFFF9FAFB);
const kGreen   = Color(0xFF22C55E);
const kRed     = Color(0xFFEF4444);
const kBlue    = Color(0xFF3B82F6);
const kPurple  = Color(0xFF8B5CF6);

// ─── Formatters ───────────────────────────────────────────────────────────────
final _decimalFmt  = NumberFormat('#,##0.0', 'en_US');
final _dateFmt     = DateFormat('d MMM');
final _fullDateFmt = DateFormat('d MMM yyyy');

String formatCurrency(double v) => formatMoney(v);
String formatDate(DateTime d) => _dateFmt.format(d);
String formatFullDate(DateTime d) => _fullDateFmt.format(d);
String formatPercent(double v) => '${_decimalFmt.format(v)}%';

// ─── Reusable section header ──────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kText)),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      );
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class EmptyReportState extends StatelessWidget {
  final String message;
  const EmptyReportState({super.key, this.message = 'No data for selected period'});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SvgIcon(AppIcons.barChartOutlined, size: 48, color: kSub),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: kMuted, fontSize: 13)),
          ]),
        ),
      );
}

// ─── Simple bar chart ─────────────────────────────────────────────────────────
class SimpleBarChart extends StatelessWidget {
  final List<(String label, double value)> data;
  final Color barColor;
  final double maxHeight;

  const SimpleBarChart({super.key, required this.data, this.barColor = kPrimary, this.maxHeight = 120});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const EmptyReportState();
    final maxVal = data.map((e) => e.$2).reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: maxHeight + 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((e) {
          final pct = maxVal == 0 ? 0.0 : e.$2 / maxVal;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: (pct * maxHeight).clamp(2.0, maxHeight),
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(e.$1, style: const TextStyle(fontSize: 9, color: kMuted), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Donut-style legend row ───────────────────────────────────────────────────
class LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String? percent;

  const LegendRow({super.key, required this.color, required this.label, required this.value, this.percent});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: kText))),
          if (percent != null) Text(percent!, style: const TextStyle(fontSize: 11, color: kMuted)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kText)),
        ]),
      );
}
