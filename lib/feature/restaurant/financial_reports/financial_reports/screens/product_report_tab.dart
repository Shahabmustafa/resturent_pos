import 'package:flutter/material.dart';
import '../models/financial_reports_models.dart';
import '../widgets/report_helpers.dart';

class ProductReportTab extends StatelessWidget {
  final List<ProductReport> products;
  final String sortBy;
  final void Function(String) onSortChange;

  const ProductReportTab({
    super.key,
    required this.products,
    required this.sortBy,
    required this.onSortChange,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const EmptyReportState(message: 'No product sales in this period');

    final top5 = products.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top 5 bar chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionHeader(
                title: 'Top Products',
                trailing: _SortPicker(value: sortBy, onChange: onSortChange),
              ),
              const SizedBox(height: 16),
              SimpleBarChart(
                data: top5.map((p) {
                  final label = p.itemName.length > 8 ? '${p.itemName.substring(0, 8)}…' : p.itemName;
                  final val = sortBy == 'quantity'
                      ? p.quantitySold.toDouble()
                      : sortBy == 'profit'
                          ? p.profit
                          : p.revenue;
                  return (label, val);
                }).toList(),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Full product table
          Container(
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: kLight,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                    border: Border(bottom: BorderSide(color: kBorder)),
                  ),
                  child: const Row(children: [
                    Expanded(flex: 3, child: Text('Item', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted))),
                    Expanded(flex: 2, child: Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted))),
                    Expanded(child: Text('Qty', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted), textAlign: TextAlign.right)),
                    Expanded(flex: 2, child: Text('Revenue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted), textAlign: TextAlign.right)),
                    Expanded(flex: 2, child: Text('Profit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted), textAlign: TextAlign.right)),
                    Expanded(child: Text('Margin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted), textAlign: TextAlign.right)),
                  ]),
                ),
                // Rows
                ...products.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: i.isEven ? kCard : kLight,
                      border: const Border(bottom: BorderSide(color: kBorder)),
                    ),
                    child: Row(children: [
                      Expanded(flex: 3, child: Row(children: [
                        if (i < 3) Container(
                          width: 18, height: 18,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: [kPrimary, kMuted, Color(0xFFCD7F32)][i].withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text('${i + 1}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: [kPrimary, kMuted, const Color(0xFFCD7F32)][i])),
                        )
                        else Text('${i + 1}', style: const TextStyle(fontSize: 11, color: kSub)),
                        const SizedBox(width: 6),
                        Flexible(child: Text(p.itemName, style: const TextStyle(fontSize: 12, color: kText, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      ])),
                      Expanded(flex: 2, child: Text(p.categoryName, style: const TextStyle(fontSize: 11, color: kMuted), overflow: TextOverflow.ellipsis)),
                      Expanded(child: Text(p.quantitySold.toString(), style: const TextStyle(fontSize: 12, color: kText), textAlign: TextAlign.right)),
                      Expanded(flex: 2, child: Text(formatCurrency(p.revenue), style: const TextStyle(fontSize: 12, color: kText, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
                      Expanded(flex: 2, child: Text(
                        formatCurrency(p.profit),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: p.profit >= 0 ? kGreen : kRed),
                        textAlign: TextAlign.right,
                      )),
                      Expanded(child: Text(
                        '${p.margin.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 11, color: p.margin >= 30 ? kGreen : p.margin >= 15 ? kPrimary : kRed),
                        textAlign: TextAlign.right,
                      )),
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

class _SortPicker extends StatelessWidget {
  final String value;
  final void Function(String) onChange;

  const _SortPicker({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(6)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            style: const TextStyle(fontSize: 12, color: kText),
            items: const [
              DropdownMenuItem(value: 'revenue', child: Text('By Revenue')),
              DropdownMenuItem(value: 'quantity', child: Text('By Quantity')),
              DropdownMenuItem(value: 'profit', child: Text('By Profit')),
            ],
            onChanged: (v) { if (v != null) onChange(v); },
          ),
        ),
      );
}
