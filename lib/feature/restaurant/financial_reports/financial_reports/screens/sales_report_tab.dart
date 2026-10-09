import 'package:flutter/material.dart';
import '../models/financial_reports_models.dart';
import '../widgets/report_helpers.dart';
import '../widgets/summary_cards.dart';

class SalesReportTab extends StatelessWidget {
  final FinancialSummary summary;
  final List<DailySales> dailySales;

  const SalesReportTab({super.key, required this.summary, required this.dailySales});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SummaryCardsSection(summary: summary),
          const SizedBox(height: 24),

          // Daily sales chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionHeader(title: 'Revenue Trend'),
              const SizedBox(height: 16),
              dailySales.isEmpty
                  ? const EmptyReportState()
                  : SimpleBarChart(
                      data: dailySales.map((d) => (formatDate(d.date), d.revenue)).toList(),
                    ),
            ]),
          ),
          const SizedBox(height: 16),

          // Payment method breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionHeader(title: 'Payment Methods'),
              const SizedBox(height: 12),
              _PaymentMethodRow(label: 'Cash', value: summary.cashRevenue, total: summary.totalRevenue, color: kGreen),
              _PaymentMethodRow(label: 'Card', value: summary.cardRevenue, total: summary.totalRevenue, color: kBlue),
              _PaymentMethodRow(label: 'Online', value: summary.onlineRevenue, total: summary.totalRevenue, color: kPurple),
            ]),
          ),
          const SizedBox(height: 16),

          // Order status breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionHeader(title: 'Order Status'),
              const SizedBox(height: 12),
              _StatRow(label: 'Total Orders', value: summary.totalOrders.toString()),
              _StatRow(label: 'Paid', value: summary.paidOrders.toString(), valueColor: kGreen),
              _StatRow(label: 'Unpaid', value: summary.unpaidOrders.toString(), valueColor: kRed),
              _StatRow(label: 'Average Order Value', value: formatCurrency(summary.averageOrderValue)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  final String label;
  final double value;
  final double total;
  final Color color;

  const _PaymentMethodRow({required this.label, required this.value, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : value / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: const TextStyle(fontSize: 12, color: kText)),
          const Spacer(),
          Text('${(pct * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, color: kMuted)),
          const SizedBox(width: 8),
          Text(formatCurrency(value), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: kBorder,
            color: color,
            minHeight: 5,
          ),
        ),
      ]),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Text(label, style: const TextStyle(fontSize: 12, color: kMuted)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: valueColor ?? kText)),
        ]),
      );
}
