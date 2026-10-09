import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../models/financial_reports_models.dart';
import 'report_helpers.dart';

class SummaryCardsSection extends StatelessWidget {
  final FinancialSummary summary;
  const SummaryCardsSection({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row — Revenue, Cost, Gross Profit
        Row(children: [
          _SummaryCard(label: 'Total Revenue', value: formatCurrency(summary.totalRevenue), color: kGreen, icon: AppIcons.trendingUp),
          const SizedBox(width: 12),
          _SummaryCard(label: 'Total Cost', value: formatCurrency(summary.totalCost), color: kRed, icon: AppIcons.receiptLong),
          const SizedBox(width: 12),
          _SummaryCard(label: 'Gross Profit', value: formatCurrency(summary.grossProfit), color: kPrimary, icon: AppIcons.barChart,
              sub: '${summary.grossMargin.toStringAsFixed(1)}% margin'),
        ]),
        const SizedBox(height: 12),
        // Second row — Expenses, Net Profit, Orders
        Row(children: [
          _SummaryCard(label: 'Expenses', value: formatCurrency(summary.totalExpenses), color: kPurple, icon: AppIcons.moneyOff),
          const SizedBox(width: 12),
          _SummaryCard(
            label: 'Net Profit',
            value: formatCurrency(summary.netProfit),
            color: summary.netProfit >= 0 ? kGreen : kRed,
            icon: summary.netProfit >= 0 ? AppIcons.arrowUpward : AppIcons.arrowDownward,
            sub: '${summary.netMargin.toStringAsFixed(1)}% margin',
          ),
          const SizedBox(width: 12),
          _SummaryCard(label: 'Total Orders', value: summary.totalOrders.toString(), color: kBlue, icon: AppIcons.shoppingBagOutlined,
              sub: '${summary.paidOrders} paid · ${summary.unpaidOrders} unpaid'),
        ]),
        const SizedBox(height: 12),
        // Third row — payment methods + avg order
        Row(children: [
          _SummaryCard(label: 'Cash', value: formatCurrency(summary.cashRevenue), color: kGreen, icon: AppIcons.paymentsOutlined),
          const SizedBox(width: 12),
          _SummaryCard(label: 'Card / Online', value: formatCurrency(summary.cardRevenue + summary.onlineRevenue), color: kBlue, icon: AppIcons.creditCard),
          const SizedBox(width: 12),
          _SummaryCard(label: 'Avg Order Value', value: formatCurrency(summary.averageOrderValue), color: kPrimary, icon: AppIcons.calculateOutlined),
        ]),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final AppIcon icon;
  final String? sub;
  const _SummaryCard({required this.label, required this.value, required this.color, required this.icon, this.sub});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: SvgIcon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Flexible(child: Text(label, style: const TextStyle(fontSize: 11, color: kMuted), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub!, style: const TextStyle(fontSize: 10, color: kSub)),
          ],
        ]),
      ),
    );
  }
}
