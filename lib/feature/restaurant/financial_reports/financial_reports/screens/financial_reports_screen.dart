import 'package:resturent_application/core/widget/page_skeleton.dart';
import 'package:resturent_application/core/widget/app_tab_bar.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/financial_reports_models.dart';
import '../providers/financial_reports_provider.dart';
import '../widgets/date_filter_bar.dart';
import '../widgets/report_helpers.dart';
import 'sales_report_tab.dart';
import 'profit_report_tab.dart';
import 'product_report_tab.dart';
import 'expense_report_tab.dart';
import 'financial_reports_export.dart';

class FinancialReportsScreen extends ConsumerStatefulWidget {
  /// Name printed at the top of exported reports.
  final String reportName;

  const FinancialReportsScreen({
    super.key,
    this.reportName = 'Financial Report',
  });

  @override
  ConsumerState<FinancialReportsScreen> createState() =>
      _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends ConsumerState<FinancialReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  static const _tabs = [
    AppTabItem('Sales', icon: AppIcons.barChartRounded),
    AppTabItem('Profit & Loss', icon: AppIcons.trendingUpRounded),
    AppTabItem('Products', icon: AppIcons.fastfoodRounded),
    AppTabItem('Expenses', icon: AppIcons.receiptLongRounded),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financialReportsProvider);
    final notifier = ref.read(financialReportsProvider.notifier);

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            color: kCard,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Financial Reports',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                      ),
                    ),
                    if (state.isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kPrimary,
                        ),
                      )
                    else
                      IconButton(
                        onPressed: notifier.loadAll,
                        icon: const SvgIcon(
                          AppIcons.refresh,
                          color: kMuted,
                          size: 20,
                        ),
                        tooltip: 'Refresh',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const SizedBox(width: 12),
                    // Export button
                    _ExportButton(
                      state: state,
                      products: notifier.sortedProducts,
                      reportName: widget.reportName,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatFullDate(state.startDate)}  →  ${formatFullDate(state.endDate)}',
                  style: const TextStyle(fontSize: 12, color: kMuted),
                ),
                const SizedBox(height: 16),
                // Date filter bar
                DateFilterBar(
                  selected: state.selectedFilter,
                  startDate: state.startDate,
                  endDate: state.endDate,
                  onFilter: notifier.applyFilter,
                  onCustomRange: notifier.applyCustomRange,
                ),
                const SizedBox(height: 16),
                // Tab bar
                AppTabBar(controller: _tab, items: _tabs, expand: false),
                const SizedBox(height: 14),
              ],
            ),
          ),

          // ── Error banner ─────────────────────────────────────────────────────
          if (state.error != null)
            Container(
              color: kRed.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  const SvgIcon(AppIcons.errorOutline, color: kRed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: kRed, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    onPressed: notifier.loadAll,
                    icon: const SvgIcon(
                      AppIcons.refresh,
                      color: kRed,
                      size: 16,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // ── Tab content ──────────────────────────────────────────────────────
          Expanded(
            child: state.isLoading && state.summary.totalOrders == 0
                ? const ReportSkeleton()
                : TabBarView(
                    controller: _tab,
                    children: [
                      SalesReportTab(
                        summary: state.summary,
                        dailySales: state.dailySales,
                      ),
                      ProfitReportTab(
                        summary: state.summary,
                        dailySales: state.dailySales,
                      ),
                      ProductReportTab(
                        products: notifier.sortedProducts,
                        sortBy: state.sortProductBy,
                        onSortChange: notifier.setSortProductBy,
                      ),
                      ExpenseReportTab(
                        expenses: state.expenseReports,
                        totalExpenses: state.summary.totalExpenses,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Export Button ────────────────────────────────────────────────────────────
class _ExportButton extends StatelessWidget {
  final FinancialReportsState state;
  final List<ProductReport> products;
  final String reportName;
  const _ExportButton({
    required this.state,
    required this.products,
    required this.reportName,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) => _export(context, v),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              SvgIcon(AppIcons.pictureAsPdf, size: 16, color: kRed),
              SizedBox(width: 8),
              Text('Export PDF'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'csv',
          child: Row(
            children: [
              SvgIcon(AppIcons.tableChart, size: 16, color: kGreen),
              SizedBox(width: 8),
              Text('Export CSV'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: kPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgIcon(AppIcons.download, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'Export',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, String format) async {
    final messenger = ScaffoldMessenger.of(context);
    void snack(String text, {bool error = false}) => messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? kRed : kPrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    try {
      if (format == 'pdf') {
        await exportReportPdf(
          context: context,
          summary: state.summary,
          products: products,
          expenses: state.expenseReports,
          startDate: state.startDate,
          endDate: state.endDate,
          restaurantName: reportName,
        );
        return;
      }
      final csv = buildReportCsv(
        summary: state.summary,
        products: products,
        expenses: state.expenseReports,
        startDate: state.startDate,
        endDate: state.endDate,
      );
      final name =
          'financial_report_${DateFormat('yyyy-MM-dd').format(state.startDate)}.csv';
      final file = XFile.fromData(
        utf8.encode(csv),
        mimeType: 'text/csv',
        name: name,
      );
      if (kIsWeb) {
        await file.saveTo(name); // the browser downloads it
      } else {
        final location = await getSaveLocation(
          suggestedName: name,
          acceptedTypeGroups: const [
            XTypeGroup(label: 'CSV', extensions: ['csv']),
          ],
        );
        if (location == null) return; // save dialog cancelled
        await file.saveTo(location.path);
      }
      snack('Saved $name');
    } catch (e) {
      snack('Export failed: $e', error: true);
    }
  }
}
