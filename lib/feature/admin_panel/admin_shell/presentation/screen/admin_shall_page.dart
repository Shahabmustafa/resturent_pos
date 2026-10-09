import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:resturent_application/feature/admin_panel/auth/presentation/screen/company_auth_screen.dart';
import '../../../../../core/widget/admin_sidebar.dart';
import '../../../auth/presentation/provider/company_provider.dart';
import '../../../branches/data/datasource/branches_datasource.dart';
import '../../../branches/presentation/screen/branches_page.dart';
import '../../../dashboard/presentation/screen/dashboard_page.dart';


class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {

  int _page = 0;

  late final BranchDatasource _datasource = BranchDatasource(Supabase.instance.client);

  @override
  Widget build(BuildContext context) {
    final company = ref.watch(companyAuthProvider).company;
    final companyId = company?.id.toString() ?? '';

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AdminSidebar(
            selected: _page,
            onSelect: (i) => setState(() => _page = i),
            branchCount: 10,
            openCount: 10,
            onLogout: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => CompanyLoginScreen()),
              );
            },
          ),

          // Main Content
          Expanded(
            child: _page == 0 ?
            DashboardPage(
              onBranchTap: (id) => setState(() => _page = 1),
              branches: [],
            )
                : BranchesPage(
              companyId: companyId,
              datasource: _datasource,
            ),
          ),
        ],
      ),
    );
  }
}