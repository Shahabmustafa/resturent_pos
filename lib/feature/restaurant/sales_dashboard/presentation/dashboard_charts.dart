import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/dashboard_stats.dart';
import 'package:resturent_application/core/constants/currency.dart';

/// Chart tokens (validated categorical palette on a white surface; slots 1–3
/// pass the CVD and normal-vision checks, aqua needs visible labels → every
/// payment segment carries its value in the legend rows).
class DashColors {
  DashColors._();
  static const series1 = Color(0xFF2A78D6); // blue — the one-series default
  static const series2 = Color(0xFFEB6834); // orange
  static const series3 = Color(0xFF1BAF7A); // aqua
  static const context = Color(0xFFB5B3AD); // de-emphasised comparison series
  static const grid = Color(0xFFE1E0D9);
  static const axis = Color(0xFF898781);
  static const ink = Color(0xFF0B0B0B);
  static const inkSecondary = Color(0xFF52514E);
  static const tooltipBg = Color(0xFF1A1D3A);
  // Status (always shown with an icon + label).
  static const good = Color(0xFF0CA30C);
  static const goodText = Color(0xFF006300);
  static const warning = Color(0xFFFAB219);
  static const critical = Color(0xFFD03B3B);
}

String rs(double v) => formatMoney(v);
String rsShort(double v) {
  if (v >= 1000) return formatMoneyCompact(v);
  return formatMoney(v);
}

double _niceMax(double v) {
  if (v <= 0) return 100;
  final exp = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  for (final m in [1, 2, 2.5, 5, 10]) {
    if (v <= m * exp) return m * exp;
  }
  return 10 * exp;
}

const _axisStyle = TextStyle(fontSize: 10.5, color: DashColors.axis, fontFeatures: [FontFeature.tabularFigures()]);

/// Revenue over the period (blue area) against the previous period (grey line).
class SalesTrendChart extends StatelessWidget {
  final List<TrendPoint> points;
  final bool hourly;

  const SalesTrendChart({super.key, required this.points, required this.hourly});

  String _label(DateTime t) => hourly ? DateFormat('h a').format(t) : DateFormat('d MMM').format(t);

  @override
  Widget build(BuildContext context) {
    final maxY = _niceMax(points.fold<double>(0, (m, p) => math.max(m, math.max(p.current, p.previous))));
    final every = math.max(1, (points.length / 7).ceil());
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        minX: 0,
        maxX: math.max(1, points.length - 1).toDouble(),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => const FlLine(color: DashColors.grid, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: true, border: const Border(bottom: BorderSide(color: DashColors.grid))),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: maxY / 4,
              getTitlesWidget: (v, _) => Text(rsShort(v), style: _axisStyle),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.round();
                if (i != v || i < 0 || i >= points.length || i % every != 0) return const SizedBox.shrink();
                return Padding(padding: const EdgeInsets.only(top: 6), child: Text(_label(points[i].at), style: _axisStyle));
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          getTouchedSpotIndicator: (bar, idx) => [
            for (final _ in idx)
              TouchedSpotIndicatorData(
                const FlLine(color: DashColors.axis, strokeWidth: 1),
                FlDotData(
                  getDotPainter: (s, _, b, __) => FlDotCirclePainter(
                    radius: 4.5,
                    color: b.color ?? DashColors.series1,
                    strokeColor: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
          ],
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => DashColors.tooltipBg,
            tooltipBorderRadius: BorderRadius.circular(8),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  s.barIndex == 0
                      ? '${_label(points[s.x.round()].at)}\nThis period  ${rs(s.y)}'
                      : 'Previous  ${rs(s.y)}',
                  TextStyle(
                    color: s.barIndex == 0 ? Colors.white : const Color(0xFFC3C2B7),
                    fontSize: 12,
                    fontWeight: s.barIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].current)],
            color: DashColors.series1,
            barWidth: 2,
            isCurved: true,
            preventCurveOverShooting: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [DashColors.series1.withValues(alpha: 0.18), DashColors.series1.withValues(alpha: 0.0)],
              ),
            ),
          ),
          LineChartBarData(
            spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].previous)],
            color: DashColors.context,
            barWidth: 2,
            isCurved: true,
            preventCurveOverShooting: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

/// Revenue by hour of day — one series, one hue.
class BusyHoursChart extends StatelessWidget {
  final List<HourPoint> hours;

  const BusyHoursChart({super.key, required this.hours});

  static String hourLabel(int h) => DateFormat('h a').format(DateTime(2000, 1, 1, h));

  @override
  Widget build(BuildContext context) {
    final maxY = _niceMax(hours.fold<double>(0, (m, h) => math.max(m, h.revenue)));
    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceBetween,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => const FlLine(color: DashColors.grid, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: true, border: const Border(bottom: BorderSide(color: DashColors.grid))),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: maxY / 4,
              getTitlesWidget: (v, _) => Text(rsShort(v), style: _axisStyle),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, _) {
                final h = v.toInt();
                if (h % 3 != 0) return const SizedBox.shrink();
                return Padding(padding: const EdgeInsets.only(top: 6), child: Text(hourLabel(h), style: _axisStyle));
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => DashColors.tooltipBg,
            tooltipBorderRadius: BorderRadius.circular(8),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (group, _, rod, __) {
              final h = hours[group.x];
              return BarTooltipItem(
                '${hourLabel(h.hour)} – ${hourLabel((h.hour + 1) % 24)}\n',
                const TextStyle(color: Color(0xFFC3C2B7), fontSize: 11.5),
                children: [
                  TextSpan(
                    text: '${rs(h.revenue)} · ${h.orders} ${h.orders == 1 ? 'order' : 'orders'}',
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: [
          for (final h in hours)
            BarChartGroupData(x: h.hour, barRods: [
              BarChartRodData(
                toY: h.revenue,
                width: 10,
                color: DashColors.series1,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ]),
        ],
      ),
    );
  }
}

/// 100% stacked bar for part-to-whole (payment methods, sales channel), with
/// 2px gaps between segments. Values live in the legend rows beside it.
class SplitBar extends StatelessWidget {
  final List<(double, Color)> parts;
  final double height;

  const SplitBar({super.key, required this.parts, this.height = 14});

  @override
  Widget build(BuildContext context) {
    final total = parts.fold<double>(0, (s, p) => s + p.$1);
    final visible = parts.where((p) => p.$1 > 0).toList();
    if (total <= 0 || visible.isEmpty) {
      return Container(height: height, decoration: BoxDecoration(color: DashColors.grid, borderRadius: BorderRadius.circular(4)));
    }
    return SizedBox(
      height: height,
      child: Row(children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Expanded(
            flex: math.max(1, (visible[i].$1 / total * 1000).round()),
            child: Container(
              decoration: BoxDecoration(
                color: visible[i].$2,
                borderRadius: BorderRadius.horizontal(
                  left: i == 0 ? const Radius.circular(4) : Radius.zero,
                  right: i == visible.length - 1 ? const Radius.circular(4) : Radius.zero,
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

/// Horizontal magnitude bar for ranked lists (one hue for every row).
class RankBar extends StatelessWidget {
  final double fraction;

  const RankBar({super.key, required this.fraction});

  @override
  Widget build(BuildContext context) => Container(
        height: 6,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(color: const Color(0xFFF1F0EC), borderRadius: BorderRadius.circular(4)),
        child: FractionallySizedBox(
          widthFactor: fraction.clamp(0.0, 1.0),
          child: Container(decoration: BoxDecoration(color: DashColors.series1, borderRadius: BorderRadius.circular(4))),
        ),
      );
}
