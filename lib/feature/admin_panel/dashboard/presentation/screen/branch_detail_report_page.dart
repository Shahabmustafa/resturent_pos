import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/widget/app_tab_bar.dart';
import '../../../../restaurant/financial_reports/financial_reports/providers/financial_reports_notifier.dart';
import '../../../../restaurant/financial_reports/financial_reports/providers/financial_reports_provider.dart';
import '../../../../restaurant/financial_reports/financial_reports/screens/financial_reports_screen.dart';
import '../../../../restaurant/order/presentation/provider/order_provider.dart';
import '../../../../restaurant/sales_dashboard/presentation/sales_dashboard_provider.dart';
import '../../../../restaurant/sales_dashboard/presentation/sales_dashboard_screen.dart';
import '../../../branches/data/model/branches_model.dart';
import '../../../widget/shared_widget.dart';

/// Every report a branch has on its own POS — the sales dashboard (trend, busy
/// hours, top items and customers, recent orders) and the financial reports
/// (sales, profit & loss, products, expenses) — for any branch the owner picks.
class BranchDetailReportPage extends StatefulWidget {
  final List<Branch> branches;
  final String? initialBranchId;

  const BranchDetailReportPage({super.key, required this.branches, this.initialBranchId});

  @override
  State<BranchDetailReportPage> createState() => _BranchDetailReportPageState();
}

class _BranchDetailReportPageState extends State<BranchDetailReportPage> with SingleTickerProviderStateMixin {
  late final _tab = TabController(length: 2, vsync: this);
  String? _branchId;

  static const _tabs = [
    AppTabItem('Sales dashboard', icon: AppIcons.dashboardRounded),
    AppTabItem('Financial reports', icon: AppIcons.barChartRounded),
  ];

  @override
  void initState() {
    super.initState();
    _branchId = widget.initialBranchId ?? widget.branches.firstOrNull?.id;
  }

  @override
  void didUpdateWidget(BranchDetailReportPage old) {
    super.didUpdateWidget(old);
    if (widget.initialBranchId != null && widget.initialBranchId != old.initialBranchId) {
      _branchId = widget.initialBranchId;
    }
    if (!widget.branches.any((b) => b.id == _branchId)) _branchId = widget.branches.firstOrNull?.id;
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branch = widget.branches.where((b) => b.id == _branchId).firstOrNull;

    return Column(children: [
      AdminTopBar(
        title: 'Detailed Reports',
        subtitle: branch == null ? 'Pick a branch' : '${branch.name}${branch.city.isEmpty ? '' : ' · ${branch.city}'}',
      ),
      Container(
        color: AppColors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Wrap(
          spacing: 16,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
              child: DropdownButtonFormField<String>(
                initialValue: _branchId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Branch',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: [
                  for (final b in widget.branches)
                    DropdownMenuItem(value: b.id, child: Text(b.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (id) => setState(() => _branchId = id),
              ),
            ),
            SizedBox(width: 380, child: AppTabBar(controller: _tab, items: _tabs)),
          ],
        ),
      ),
      const Divider(height: 1, color: AppColors.border),
      Expanded(
        child: branch == null
            ? const Center(
                child: Text('No branches yet. Add one from the Branches page.',
                    style: TextStyle(fontSize: 13, color: AppColors.grey)),
              )
            // The branch POS screens read their branch from these two providers,
            // so pointing them at the picked branch shows exactly that branch's
            // reports. The key starts them fresh when the branch changes.
            : ProviderScope(
                key: ValueKey(branch.id),
                overrides: [
                  salesDashboardProvider.overrideWith((ref) => SalesDashboardNotifier(
                        ref.watch(dashboardDatasourceProvider),
                        ref.watch(orderDatasourceProvider),
                        branch.id,
                      )),
                  financialReportsProvider.overrideWith(
                    (ref) => FinancialReportsNotifier(ref.watch(financialReportsDatasourceProvider), branch.id),
                  ),
                ],
                child: TabBarView(
                  controller: _tab,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [SalesDashboardScreen(), FinancialReportsScreen()],
                ),
              ),
      ),
    ]);
  }
}
