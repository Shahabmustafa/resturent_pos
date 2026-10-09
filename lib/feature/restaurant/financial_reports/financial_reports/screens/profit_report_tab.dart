import 'package:flutter/material.dart';
import '../models/financial_reports_models.dart';
import '../widgets/report_helpers.dart';

class ProfitReportTab extends StatelessWidget {
  final FinancialSummary summary;
  final List<DailySales> dailySales;

  const ProfitReportTab({super.key, required this.summary, required this.dailySales});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profit breakdown waterfall style
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionHeader(title: 'Profit & Loss Statement'),
              const SizedBox(height: 16),
              _PLRow(label: 'Total Revenue', value: summary.totalRevenue, color: kGreen, bold: true),
              const Divider(color: kBorder, height: 20),
              _PLRow(label: 'Cost of Goods Sold', value: -summary.totalCost, color: kRed),
              const Divider(color: kBorder, height: 20),
              _PLRow(
                label: 'Gross Profit',
                value: summary.grossProfit,
                color: summary.grossProfit >= 0 ? kGreen : kRed,
                bold: true,
                sub: '${summary.grossMargin.toStringAsFixed(1)}% gross margin',
              ),
              const Divider(color: kBorder, height: 20),
              _PLRow(label: 'Operating Expenses', value: -summary.totalExpenses, color: kRed),
              const Divider(color: kBorder, height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (summary.netProfit >= 0 ? kGreen : kRed).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _PLRow(
                  label: 'Net Profit',
                  value: summary.netProfit,
                  color: summary.netProfit >= 0 ? kGreen : kRed,
                  bold: true,
                  sub: '${summary.netMargin.toStringAsFixed(1)}% net margin',
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Visual breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionHeader(title: 'Revenue Breakdown'),
              const SizedBox(height: 16),
              LegendRow(
                color: kGreen,
                label: 'Gross Profit',
                value: formatCurrency(summary.grossProfit),
                percent: '${summary.grossMargin.toStringAsFixed(1)}%',
              ),
              LegendRow(
                color: kRed,
                label: 'COGS',
                value: formatCurrency(summary.totalCost),
                percent: summary.totalRevenue == 0 ? '0%' : '${(summary.totalCost / summary.totalRevenue * 100).toStringAsFixed(1)}%',
              ),
              LegendRow(
                color: kPurple,
                label: 'Expenses',
                value: formatCurrency(summary.totalExpenses),
                percent: summary.totalRevenue == 0 ? '0%' : '${(summary.totalExpenses / summary.totalRevenue * 100).toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 12),
              // Stacked visual bar
              if (summary.totalRevenue > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 20,
                    child: Row(children: [
                      if (summary.netProfit > 0)
                        Flexible(
                          flex: (summary.netProfit / summary.totalRevenue * 100).round(),
                          child: Container(color: kGreen),
                        ),
                      Flexible(
                        flex: (summary.totalCost / summary.totalRevenue * 100).round().clamp(1, 100),
                        child: Container(color: kRed),
                      ),
                      Flexible(
                        flex: (summary.totalExpenses / summary.totalRevenue * 100).round().clamp(1, 100),
                        child: Container(color: kPurple),
                      ),
                    ]),
                  ),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 16),

          // Daily orders count chart
          if (dailySales.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionHeader(title: 'Daily Orders'),
                const SizedBox(height: 16),
                SimpleBarChart(
                  data: dailySales.map((d) => (formatDate(d.date), d.orders.toDouble())).toList(),
                  barColor: kBlue,
                ),
              ]),
            ),
        ],
      ),
    );
  }
}

class _PLRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool bold;
  final String? sub;

  const _PLRow({required this.label, required this.value, required this.color, this.bold = false, this.sub});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(label,
                style: TextStyle(
                  fontSize: bold ? 13 : 12,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                  color: bold ? kText : kMuted,
                )),
            const Spacer(),
            Text(
              value >= 0 ? formatCurrency(value) : '− ${formatCurrency(-value)}',
              style: TextStyle(
                fontSize: bold ? 14 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ]),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(sub!, style: const TextStyle(fontSize: 10, color: kSub)),
          ],
        ],
      );
}
