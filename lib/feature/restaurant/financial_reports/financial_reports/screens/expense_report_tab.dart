import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../models/financial_reports_models.dart';
import '../widgets/report_helpers.dart';

class ExpenseReportTab extends StatelessWidget {
  final List<ExpenseReport> expenses;
  final double totalExpenses;

  const ExpenseReportTab({super.key, required this.expenses, required this.totalExpenses});

  static const _colors = [kPrimary, kBlue, kPurple, kGreen, kRed, Color(0xFFF59E0B), Color(0xFF06B6D4)];

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) return const EmptyReportState(message: 'No expenses in this period');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total expenses card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: kRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const SvgIcon(AppIcons.moneyOff, color: kRed, size: 24),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Expenses', style: TextStyle(fontSize: 12, color: kMuted)),
                const SizedBox(height: 4),
                Text(formatCurrency(totalExpenses), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kRed)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Breakdown by category
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionHeader(title: 'By Category'),
              const SizedBox(height: 12),
              ...expenses.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final color = _colors[i % _colors.length];
                final pct = totalExpenses == 0 ? 0.0 : e.amount / totalExpenses;
                return LegendRow(
                  color: color,
                  label: e.category,
                  value: formatCurrency(e.amount),
                  percent: '${(pct * 100).toStringAsFixed(1)}%',
                );
              }),
              const SizedBox(height: 12),
              // Visual bar
              if (totalExpenses > 0)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 16,
                    child: Row(
                      children: expenses.asMap().entries.map((entry) {
                        final i = entry.key;
                        final e = entry.value;
                        final flex = (e.amount / totalExpenses * 100).round().clamp(1, 100);
                        return Flexible(
                          flex: flex,
                          child: Container(color: _colors[i % _colors.length]),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 16),

          // Expense table
          Container(
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: kLight,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                    border: Border(bottom: BorderSide(color: kBorder)),
                  ),
                  child: const Row(children: [
                    Expanded(flex: 3, child: Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted))),
                    Expanded(child: Text('Count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted), textAlign: TextAlign.right)),
                    Expanded(child: Text('Share', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted), textAlign: TextAlign.right)),
                  ]),
                ),
                ...expenses.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  final pct = totalExpenses == 0 ? 0.0 : e.amount / totalExpenses;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: i.isEven ? kCard : kLight,
                      border: const Border(bottom: BorderSide(color: kBorder)),
                    ),
                    child: Row(children: [
                      Expanded(flex: 3, child: Text(e.category, style: const TextStyle(fontSize: 12, color: kText, fontWeight: FontWeight.w500))),
                      Expanded(child: Text(e.count.toString(), style: const TextStyle(fontSize: 12, color: kMuted), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text(formatCurrency(e.amount), style: const TextStyle(fontSize: 12, color: kRed, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
                      Expanded(child: Text('${(pct * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, color: kMuted), textAlign: TextAlign.right)),
                    ]),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
