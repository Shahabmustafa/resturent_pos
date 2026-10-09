import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resturent_application/feature/restaurant/table/data/datasource/table_datasource.dart';
import 'package:resturent_application/feature/restaurant/table/presentation/provider/table_provider.dart';
import 'package:resturent_application/feature/restaurant/table/presentation/screen/table_screen.dart';
import 'package:resturent_application/feature/restaurant/table/presentation/widget/table_skeleton.dart';

class _NoDatasource implements TableDatasource {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Sits in the loading state forever, without touching Supabase.
class _LoadingNotifier extends TableNotifier {
  _LoadingNotifier(Ref ref) : super(_NoDatasource(), 'branch', ref) {
    state = const TableState(isLoading: true);
  }

  @override
  Future<void> fetchTables() async {}
}

Future<void> _pumpTablePage(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: [tableProvider.overrideWith((ref) => _LoadingNotifier(ref))],
    child: const MaterialApp(home: TablePage()),
  ));
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  testWidgets('shows a shimmer skeleton instead of a spinner while tables load', (tester) async {
    await _pumpTablePage(tester, 1440);

    expect(find.byType(TableBodySkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('skeleton lays out on a tablet-width window too', (tester) async {
    await _pumpTablePage(tester, 900);

    expect(find.byType(TableBodySkeleton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
