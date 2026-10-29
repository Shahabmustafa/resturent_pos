import 'package:resturent_application/core/widget/old_dialog_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import 'admin_shell/presentation/screen/admin_shall_page.dart';
import 'auth/presentation/provider/company_provider.dart';
import 'auth/presentation/screen/company_auth_screen.dart';

/// True when the website was opened at `/admin-panel` (or `#/admin-panel`).
bool isAdminPanelUrl(Uri uri) =>
    uri.pathSegments.contains('admin-panel') ||
    uri.fragment.split('/').contains('admin-panel');

/// Company owner's panel, served on the web at `/admin-panel`: owner email +
/// password login, then reports for all branches.
class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.primary,
          surface: AppColors.white,
        ),
        fontFamily: 'Roboto',
        dialogTheme: kOldStyleDialogTheme,
        useMaterial3: true,
      ),
      home: const _AdminGate(),
    );
  }
}

/// Login screen until a company owner is signed in, then the panel.
class _AdminGate extends ConsumerWidget {
  const _AdminGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(companyAuthProvider);
    if (auth.restoring) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return auth.isLoggedIn ? const AdminShell() : const CompanyLoginScreen();
  }
}
