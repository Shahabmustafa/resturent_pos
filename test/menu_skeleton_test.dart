import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:resturent_application/feature/restaurant/menu_and_category/presentation/provider/menu_provider.dart';
import 'package:resturent_application/feature/restaurant/menu_and_category/presentation/screen/menu_and_category_screen.dart';
import 'package:resturent_application/feature/restaurant/menu_and_category/presentation/widget/menu_skeleton.dart';

/// Stays in the loading state forever, without touching Supabase.
class _LoadingMenuNotifier extends MenuNotifier {
  _LoadingMenuNotifier() : super(branchId: 'branch');

  @override
  Future<void> loadAll() async {
    state = state.copyWith(status: MenuStatus.loading);
  }
}

Future<void> _pumpMenuPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: [menuProvider.overrideWith((ref) => _LoadingMenuNotifier())],
    child: const MaterialApp(home: MenuManagementPage()),
  ));
  await tester.pump(const Duration(milliseconds: 700));
}

int _skeletonTab(WidgetTester tester) =>
    tester.widget<MenuBodySkeleton>(find.byType(MenuBodySkeleton)).tabIndex;

void main() {
  setUpAll(() async {
    // MenuNotifier builds a datasource that reads Supabase.instance. A dummy
    // client is enough: nothing here ever makes a request.
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-key',
      authOptions: FlutterAuthClientOptions(localStorage: const EmptyLocalStorage()),
    );
  });

  testWidgets('shows skeletons instead of a spinner and follows the selected tab', (tester) async {
    await _pumpMenuPage(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(MenuStatsStripSkeleton), findsOneWidget);
    expect(_skeletonTab(tester), 0);

    await tester.tap(find.text('Menu Items'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_skeletonTab(tester), 1);

    await tester.tap(find.text('Deals'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_skeletonTab(tester), 2);

    expect(tester.takeException(), isNull);
  });

  testWidgets('does not flash misleading zero counts while loading', (tester) async {
    await _pumpMenuPage(tester);

    expect(find.text('0'), findsNothing);
    expect(find.textContaining('Categories'), findsWidgets); // tab label, no count badge
    expect(tester.takeException(), isNull);
  });
}
