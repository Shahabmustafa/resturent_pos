import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:resturent_application/feature/admin_panel/admin_shell/presentation/screen/admin_shall_page.dart';
import 'package:resturent_application/feature/admin_panel/auth/data/model/company_model.dart';
import 'package:resturent_application/feature/admin_panel/auth/data/datasource/company_datasource.dart';
import 'package:resturent_application/feature/admin_panel/auth/presentation/provider/company_provider.dart';
import 'package:resturent_application/feature/admin_panel/admin_panel_app.dart';
import 'package:resturent_application/feature/admin_panel/branches/data/model/branches_model.dart';
import 'package:resturent_application/feature/admin_panel/dashboard/data/branch_report_datasource.dart';
import 'package:resturent_application/feature/admin_panel/dashboard/presentation/screen/branch_detail_report_page.dart';

/// Signed in as a company without touching Supabase.
class _SignedInNotifier extends CompanyAuthNotifier {
  _SignedInNotifier() : super(CompanyAuthDatasource(Supabase.instance.client)) {
    final now = DateTime(2026);
    state = CompanyAuthState(
      company: CompanyModel(
        id: 'c1', name: 'Pak Afghan Group', slug: 'pak-afghan', username: 'owner',
        plan: 'pro', isActive: true, createdAt: now, updatedAt: now,
      ),
    );
  }
}

Future<void> _pump(WidgetTester tester, Size size, Widget app) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-key',
      authOptions: FlutterAuthClientOptions(localStorage: const EmptyLocalStorage()),
    );
  });

  for (final size in const [Size(360, 740), Size(1400, 900)]) {
    testWidgets('login screen lays out at $size', (tester) async {
      await _pump(tester, size, const ProviderScope(child: AdminPanelApp()));
      expect(find.text('Company Login'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('signed-in panel lays out at $size', (tester) async {
      await _pump(
        tester,
        size,
        ProviderScope(
          overrides: [companyAuthProvider.overrideWith((ref) => _SignedInNotifier())],
          child: const MaterialApp(home: AdminShell()),
        ),
      );
      expect(find.text('Branch Reports'), findsWidgets);
      expect(find.text('Today'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in const [Size(360, 740), Size(1400, 900)]) {
    testWidgets('detailed reports switch between the two report screens at $size', (tester) async {
      final branches = [
        Branch.fromJson({'id': 'b1', 'company_id': 'c1', 'name': 'Woking', 'city': 'Surrey'}, color: Colors.red),
        Branch.fromJson({'id': 'b2', 'company_id': 'c1', 'name': 'Guildford'}, color: Colors.blue),
      ];
      await _pump(
        tester,
        size,
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: BranchDetailReportPage(branches: branches, initialBranchId: 'b2'))),
        ),
      );
      expect(find.text('Woking · Surrey'), findsNothing);
      expect(find.text('Guildford'), findsWidgets);

      await tester.tap(find.text('Financial reports'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Financial Reports'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Leave the tree so the report providers cancel their timers.
      await tester.pumpWidget(const SizedBox());
    });
  }

  test('admin panel opens only at /admin-panel', () {
    expect(isAdminPanelUrl(Uri.parse('https://site.com/admin-panel')), isTrue);
    expect(isAdminPanelUrl(Uri.parse('https://site.com/admin-panel/')), isTrue);
    expect(isAdminPanelUrl(Uri.parse('https://site.com/#/admin-panel')), isTrue);
    expect(isAdminPanelUrl(Uri.parse('https://site.com/')), isFalse);
    expect(isAdminPanelUrl(Uri.parse('https://site.com/?table=abc')), isFalse);
  });

  test('branch report reads dashboard_stats figures', () {
    final branch = Branch.fromJson({'id': 'b1', 'company_id': 'c1', 'name': 'Woking'}, color: Colors.red);
    final r = BranchReport.fromStats(branch, {
      'current': {'revenue': 120.5, 'paid_orders': 4, 'avg_order': 30.13, 'orders_placed': 5, 'cancelled': 1, 'unpaid_amount': 12},
      'previous': {'revenue': 100},
      'channel': {'website_revenue': 20.5, 'pos_revenue': 100},
      'by_method': {'cash': 80, 'card': 40.5, 'online': 0},
      'live': {
        'pending_orders': 2,
        'active_deliveries': 1,
        'counter': {'expected_cash': 250},
      },
    });
    expect(r.revenue, 120.5);
    expect(r.previousRevenue, 100);
    expect(r.paidOrders, 4);
    expect(r.cancelled, 1);
    expect(r.websiteRevenue, 20.5);
    expect(r.card, 40.5);
    expect(r.pendingOrders, 2);
    expect(r.counterOpen, isTrue);
    expect(r.expectedCash, 250);

    final closed = BranchReport.fromStats(branch, {'current': {}, 'previous': {}, 'live': {'counter': null}});
    expect(closed.revenue, 0);
    expect(closed.counterOpen, isFalse);
  });
}
