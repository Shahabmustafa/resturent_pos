import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/provider/branch_auth_provider.dart';
import '../../order/data/datasource/order_datasource.dart';
import '../../order/presentation/provider/order_provider.dart';
import '../data/dashboard_stats.dart';

enum DashboardPeriod { today, yesterday, last7, last30, thisMonth }

extension DashboardPeriodX on DashboardPeriod {
  String get label => switch (this) {
        DashboardPeriod.today => 'Today',
        DashboardPeriod.yesterday => 'Yesterday',
        DashboardPeriod.last7 => 'Last 7 days',
        DashboardPeriod.last30 => 'Last 30 days',
        DashboardPeriod.thisMonth => 'This month',
      };

  /// What the "vs previous" deltas compare against.
  String get previousLabel => switch (this) {
        DashboardPeriod.today => 'yesterday',
        DashboardPeriod.yesterday => 'the day before',
        DashboardPeriod.last7 => 'previous 7 days',
        DashboardPeriod.last30 => 'previous 30 days',
        DashboardPeriod.thisMonth => 'previous period',
      };

  /// Local-time window [from, to).
  (DateTime, DateTime) range(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      DashboardPeriod.today => (today, now),
      DashboardPeriod.yesterday => (today.subtract(const Duration(days: 1)), today),
      DashboardPeriod.last7 => (today.subtract(const Duration(days: 6)), now),
      DashboardPeriod.last30 => (today.subtract(const Duration(days: 29)), now),
      DashboardPeriod.thisMonth => (DateTime(now.year, now.month), now),
    };
  }
}

class SalesDashboardState {
  final DashboardPeriod period;
  final DashboardStats? stats;
  final bool refreshing; // a fetch is running; old numbers stay on screen
  final String? error;

  const SalesDashboardState({this.period = DashboardPeriod.today, this.stats, this.refreshing = true, this.error});

  SalesDashboardState copyWith({DashboardPeriod? period, DashboardStats? stats, bool? refreshing, String? error, bool clearError = false}) =>
      SalesDashboardState(
        period: period ?? this.period,
        stats: stats ?? this.stats,
        refreshing: refreshing ?? this.refreshing,
        error: clearError ? null : error ?? this.error,
      );
}

class SalesDashboardNotifier extends StateNotifier<SalesDashboardState> {
  final DashboardDatasource _ds;
  final OrderRemoteDatasource _orders;
  final String _branchId;
  RealtimeChannel? _channel;
  Timer? _debounce;
  Timer? _poll;
  int _request = 0;

  SalesDashboardNotifier(this._ds, this._orders, this._branchId) : super(const SalesDashboardState()) {
    load();
    if (_branchId.isEmpty) return;
    // New sales, payments and cancellations show up without a manual refresh.
    _channel = _orders.subscribeToOrders(_branchId, 'dashboard', (_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 1500), load);
    });
    _poll = Timer.periodic(const Duration(seconds: 60), (_) => load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _poll?.cancel();
    if (_channel != null) _orders.unsubscribe(_channel!);
    super.dispose();
  }

  void setPeriod(DashboardPeriod p) {
    if (p == state.period) return;
    state = state.copyWith(period: p);
    load();
  }

  Future<void> load() async {
    if (_branchId.isEmpty) return;
    final id = ++_request;
    final period = state.period;
    state = state.copyWith(refreshing: true, clearError: true);
    try {
      final (from, to) = period.range(DateTime.now());
      final stats = await _ds.fetch(_branchId, from, to);
      if (!mounted || id != _request) return; // a newer request (e.g. period change) wins
      state = state.copyWith(stats: stats, refreshing: false);
    } catch (e) {
      if (!mounted || id != _request) return;
      state = state.copyWith(
        refreshing: false,
        error: e is PostgrestException ? e.message : e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final dashboardDatasourceProvider = Provider<DashboardDatasource>((_) => DashboardDatasource(Supabase.instance.client));

final salesDashboardProvider = StateNotifierProvider.autoDispose<SalesDashboardNotifier, SalesDashboardState>((ref) {
  return SalesDashboardNotifier(
    ref.watch(dashboardDatasourceProvider),
    ref.watch(orderDatasourceProvider),
    ref.watch(branchAuthProvider).branch?.branchId ?? '',
  );
});
