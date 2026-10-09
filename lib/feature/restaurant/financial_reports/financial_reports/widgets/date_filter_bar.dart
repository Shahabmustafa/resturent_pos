import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../models/financial_reports_models.dart';
import 'report_helpers.dart';

class DateFilterBar extends StatelessWidget {
  final DateFilter selected;
  final DateTime startDate;
  final DateTime endDate;
  final void Function(DateFilter) onFilter;
  final void Function(DateTime, DateTime) onCustomRange;

  const DateFilterBar({
    super.key,
    required this.selected,
    required this.startDate,
    required this.endDate,
    required this.onFilter,
    required this.onCustomRange,
  });

  Future<void> _pickRange(BuildContext ctx) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: ctx,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: kPrimary, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) onCustomRange(picked.start, picked.end);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DateFilter.values.where((f) => f != DateFilter.custom).map((f) {
                final isSelected = selected == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onFilter(f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimary : kCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? kPrimary : kBorder),
                      ),
                      child: Text(
                        f.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? Colors.white : kText,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Custom range button
        GestureDetector(
          onTap: () => _pickRange(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: selected == DateFilter.custom ? kPrimary : kCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected == DateFilter.custom ? kPrimary : kBorder),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              SvgIcon(AppIcons.dateRange, size: 14,
                  color: selected == DateFilter.custom ? Colors.white : kMuted),
              const SizedBox(width: 4),
              Text(
                selected == DateFilter.custom
                    ? '${formatDate(startDate)} – ${formatDate(endDate)}'
                    : 'Custom',
                style: TextStyle(
                  fontSize: 12,
                  color: selected == DateFilter.custom ? Colors.white : kText,
                  fontWeight: selected == DateFilter.custom ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
