import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../auth/presentation/provider/branch_auth_provider.dart';
import '../../data/datasource/dashboard_datasource.dart';


final dashboardRefreshProvider = StateProvider<int>((ref) => 0);


final dashboardDatasourceProvider = Provider((_) => DashboardDatasource());

// KPI
final dashboardKpiProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(dashboardRefreshProvider);
  final branchId = ref.watch(branchAuthProvider).branch?.branchId ?? "";
  return ref.read(dashboardDatasourceProvider).fetchTodayKpis(branchId);
});

// Weekly Revenue
final weeklyRevenueProvider = FutureProvider<Map<String, List<double>>>((ref) async {
  ref.watch(dashboardRefreshProvider);
  final branchId = ref.watch(branchAuthProvider).branch?.branchId ?? "";
  return ref.read(dashboardDatasourceProvider).fetchWeeklyRevenue(branchId);
});

// Order Types
final orderTypeCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(dashboardRefreshProvider);
  final branchId = ref.watch(branchAuthProvider).branch?.branchId ?? "";
  return ref.read(dashboardDatasourceProvider).fetchOrderTypeCounts(branchId);
});

// Recent Orders
final recentOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dashboardRefreshProvider);
  final branchId = ref.watch(branchAuthProvider).branch?.branchId ?? "";
  return ref.read(dashboardDatasourceProvider).fetchRecentOrders(branchId);
});

// Top Selling
final topSellingProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dashboardRefreshProvider);
  final branchId = ref.watch(branchAuthProvider).branch?.branchId ?? "";
  return ref.read(dashboardDatasourceProvider).fetchTopSellingItems(branchId);
});

// Low Stock
final lowStockProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dashboardRefreshProvider);
  final branchId = ref.watch(branchAuthProvider).branch?.branchId ?? "";
  return ref.read(dashboardDatasourceProvider).fetchLowStockItems(branchId);
});

// Mini Stats
final miniStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(dashboardRefreshProvider);
  final branchId = ref.watch(branchAuthProvider).branch?.branchId ?? "";
  return ref.read(dashboardDatasourceProvider).fetchMiniStats(branchId);
});