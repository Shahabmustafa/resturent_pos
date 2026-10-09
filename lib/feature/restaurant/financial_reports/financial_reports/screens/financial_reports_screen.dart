import 'package:resturent_application/core/widget/page_skeleton.dart';
import 'package:resturent_application/core/widget/app_tab_bar.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/financial_reports_models.dart';
import '../providers/financial_reports_notifier.dart';
import '../providers/financial_reports_provider.dart';
import '../widgets/date_filter_bar.dart';
import '../widgets/report_helpers.dart';
import 'sales_report_tab.dart';
import 'profit_report_tab.dart';
import 'product_report_tab.dart';
import 'expense_report_tab.dart';

class FinancialReportsScreen extends ConsumerStatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  ConsumerState<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
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
                Row(children: [
                  const Text('Financial Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kText)),
                  const Spacer(),
                  if (state.isLoading)
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary))
                  else
                    IconButton(
                      onPressed: notifier.loadAll,
                      icon: const SvgIcon(AppIcons.refresh, color: kMuted, size: 20),
                      tooltip: 'Refresh',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 12),
                  // Export button
                  _ExportButton(state: state),
                ]),
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
              child: Row(children: [
                const SvgIcon(AppIcons.errorOutline, color: kRed, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(state.error!, style: const TextStyle(color: kRed, fontSize: 12))),
                IconButton(
                  onPressed: notifier.loadAll,
                  icon: const SvgIcon(AppIcons.refresh, color: kRed, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
            ),

          // ── Tab content ──────────────────────────────────────────────────────
          Expanded(
            child: state.isLoading && state.summary.totalOrders == 0
                ? const ReportSkeleton()
                : TabBarView(
                    controller: _tab,
                    children: [
                      SalesReportTab(summary: state.summary, dailySales: state.dailySales),
                      ProfitReportTab(summary: state.summary, dailySales: state.dailySales),
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
  const _ExportButton({required this.state});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) => _export(context, v),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'pdf', child: Row(children: [SvgIcon(AppIcons.pictureAsPdf, size: 16, color: kRed), SizedBox(width: 8), Text('Export PDF')])),
        PopupMenuItem(value: 'csv', child: Row(children: [SvgIcon(AppIcons.tableChart, size: 16, color: kGreen), SizedBox(width: 8), Text('Export CSV')])),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: kPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          SvgIcon(AppIcons.download, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text('Export', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  void _export(BuildContext context, String format) {
    // TODO: Implement PDF/CSV export
    // For PDF: use 'pdf' + 'printing' packages (same as receipt_print_dialog.dart)
    // For CSV: build CSV string, use file_selector to save
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting as ${format.toUpperCase()}...'),
        backgroundColor: kPrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
