import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/widget/admin_sidebar.dart';
import '../../../../../core/widget/svg_icon.dart';
import '../../../auth/presentation/provider/company_provider.dart';
import '../../../branches/data/datasource/branches_datasource.dart';
import '../../../branches/data/model/branches_model.dart';
import '../../../branches/presentation/screen/branches_page.dart';
import '../../../dashboard/presentation/screen/branch_detail_report_page.dart';
import '../../../dashboard/presentation/screen/dashboard_page.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _page = 0;
  List<Branch> _branches = const [];

  /// Branch the Detailed Reports page opens on (set by tapping a branch row).
  String? _detailBranchId;

  late final BranchDatasource _datasource = BranchDatasource(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    final companyId = ref.read(companyAuthProvider).company?.id;
    if (companyId == null) return;
    try {
      final branches = await _datasource.fetchBranches(companyId);
      if (mounted) setState(() => _branches = branches);
    } catch (_) {
      // The dashboard shows the error and retries; the sidebar just keeps 0.
    }
  }

  void _select(int i, {bool closeDrawer = false}) {
    if (closeDrawer) Navigator.of(context).pop();
    setState(() => _page = i);
  }

  @override
  Widget build(BuildContext context) {
    final company = ref.watch(companyAuthProvider).company;
    final companyId = company?.id ?? '';
    final wide = MediaQuery.sizeOf(context).width >= 900;

    Widget sidebar({bool inDrawer = false}) => AdminSidebar(
      selected: _page,
      onSelect: (i) => _select(i, closeDrawer: inDrawer),
      companyName: company?.name ?? '',
      accountName: company?.username ?? '',
      branchCount: _branches.length,
      openCount: _branches.where((b) => b.isOpen).length,
      onLogout: () => ref.read(companyAuthProvider.notifier).logout(),
    );

    // The dashboard reloads (and so picks up branch changes) each time it is opened.
    final content = switch (_page) {
      0 => DashboardPage(
          companyId: companyId,
          datasource: _datasource,
          onBranchesLoaded: (b) => setState(() => _branches = b),
          onBranchTap: (id) => setState(() {
            _detailBranchId = id;
            _page = 2;
          }),
        ),
      2 => BranchDetailReportPage(branches: _branches, initialBranchId: _detailBranchId),
      _ => BranchesPage(companyId: companyId, datasource: _datasource),
    };

    if (wide) {
      return Scaffold(body: Row(children: [sidebar(), Expanded(child: content)]));
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.sidebar,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const SvgIcon(AppIcons.menuRounded, size: 22, color: Colors.white),
          ),
        ),
        title: Text(company?.name ?? 'Admin Panel',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      drawer: Drawer(width: 210, child: sidebar(inDrawer: true)),
      body: content,
    );
  }
}
