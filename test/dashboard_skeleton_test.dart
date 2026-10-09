import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resturent_application/feature/restaurant/dashboard/presentation/provider/dashboard_provider.dart';
import 'package:resturent_application/feature/restaurant/dashboard/presentation/screen/daashboard_screen.dart';
import 'package:resturent_application/feature/restaurant/dashboard/presentation/widget/dashboard_skeleton.dart';

/// A future that never completes, i.e. the "still loading" state.
Future<T> _pending<T>() => Completer<T>().future;

Widget _dashboard() => ProviderScope(
      overrides: [
        dashboardKpiProvider.overrideWith((ref) => _pending()),
        weeklyRevenueProvider.overrideWith((ref) => _pending()),
        orderTypeCountsProvider.overrideWith((ref) => _pending()),
        recentOrdersProvider.overrideWith((ref) => _pending()),
        topSellingProvider.overrideWith((ref) => _pending()),
        lowStockProvider.overrideWith((ref) => _pending()),
        miniStatsProvider.overrideWith((ref) => _pending()),
      ],
      child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
    );

void _desktopView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('shows shimmer skeletons instead of spinners while loading', (tester) async {
    _desktopView(tester);
    await tester.pumpWidget(_dashboard());
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(KpiRowSkeleton), findsOneWidget);
    expect(find.byType(RevenueChartSkeleton), findsOneWidget);
    expect(find.byType(OrderTypeSkeleton), findsOneWidget);
    expect(find.byType(RecentOrdersSkeleton), findsOneWidget);
    expect(find.byType(TopSellingSkeleton), findsOneWidget);
    expect(find.byType(LowStockSkeleton), findsOneWidget);
    expect(find.byType(MiniStatsRowSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stops animating when the platform asks to reduce motion', (tester) async {
    _desktopView(tester);
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: _dashboard(),
    ));
    // Would time out if a shimmer controller were still repeating.
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
