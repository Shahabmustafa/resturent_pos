import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/provider/branch_auth_provider.dart';
import '../../../cash/data/datasource/cash_datasource.dart';
import '../../../cash/presentation/provider/cash_provider.dart';
import '../../../dashboard/presentation/provider/dashboard_provider.dart';
import '../../../pos_and_order/data/model/order_model.dart';
import '../../data/datasource/order_datasource.dart';

final orderDatasourceProvider = Provider<OrderRemoteDatasource>(
        (_) => OrderRemoteDatasource(Supabase.instance.client));

final _cashDsProvider = Provider<CashRemoteDatasource>(
        (_) => CashRemoteDatasource(Supabase.instance.client));

// ── State ─────────────────────────────────────────────────────────────────────
class OrderState {
  final List<OrderModel> orders;
  final bool loading;
  final bool updating;
  final String? error;

  final String statusFilter;
  final String typeFilter;
  final String paymentFilter;
  final String search;
  final DateTime? from;
  final DateTime? to;

  final int    totalOrders;
  final int    pendingCount;
  final int    completedCount;
  final double totalRevenue;
  final double totalPaid;

  final OrderModel? selected;

  const OrderState({
    this.orders         = const [],
    this.loading        = false,
    this.updating       = false,
    this.error,
    this.statusFilter   = 'All',
    this.typeFilter     = 'All',
    this.paymentFilter  = 'All',
    this.search         = '',
    this.from,
    this.to,
    this.totalOrders    = 0,
    this.pendingCount   = 0,
    this.completedCount = 0,
    this.totalRevenue   = 0,
    this.totalPaid      = 0,
    this.selected,
  });

  OrderState copyWith({
    List<OrderModel>? orders,
    bool?             loading,
    bool?             updating,
    String?           error,
    bool              clearError     = false,
    String?           statusFilter,
    String?           typeFilter,
    String?           paymentFilter,
    String?           search,
    Object?           from           = _sentinel,
    Object?           to             = _sentinel,
    int?              totalOrders,
    int?              pendingCount,
    int?              completedCount,
    double?           totalRevenue,
    double?           totalPaid,
    Object?           selected       = _sentinel,
  }) =>
      OrderState(
        orders:         orders         ?? this.orders,
        loading:        loading        ?? this.loading,
        updating:       updating       ?? this.updating,
        error:          clearError ? null : error ?? this.error,
        statusFilter:   statusFilter   ?? this.statusFilter,
        typeFilter:     typeFilter     ?? this.typeFilter,
        paymentFilter:  paymentFilter  ?? this.paymentFilter,
        search:         search         ?? this.search,
        from:           identical(from, _sentinel) ? this.from : from as DateTime?,
        to:             identical(to,   _sentinel) ? this.to   : to   as DateTime?,
        totalOrders:    totalOrders    ?? this.totalOrders,
        pendingCount:   pendingCount   ?? this.pendingCount,
        completedCount: completedCount ?? this.completedCount,
        totalRevenue:   totalRevenue   ?? this.totalRevenue,
        totalPaid:      totalPaid      ?? this.totalPaid,
        selected:       identical(selected, _sentinel)
            ? this.selected
            : selected as OrderModel?,
      );
}

const _sentinel = Object();

// ── Notifier ──────────────────────────────────────────────────────────────────
class OrderNotifier extends StateNotifier<OrderState> {
  final OrderRemoteDatasource _ds;
  final CashRemoteDatasource  _cash;
  final String                _branchId;
  final Ref                   _ref;

  RealtimeChannel? _channel;
  Timer? _reloadDebounce;
  Timer? _fallbackPoll;

  OrderNotifier(this._ds, this._cash, this._branchId, this._ref)
      : super(const OrderState()) {
    load();
    // Website orders and changes from other devices show up without a refresh.
    if (_branchId.isNotEmpty) {
      _channel = _ds.subscribeToOrders(
        _branchId,
        'list',
        (_) => _reloadSoon(),
        onSubscribed: _reloadSoon, // catch up after a (re)connect
      );
      // Safety net in case the realtime connection drops unnoticed.
      _fallbackPoll = Timer.periodic(const Duration(seconds: 30), (_) => load(silent: true));
    }
  }

  void _reloadSoon() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 400), () => load(silent: true));
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    _fallbackPoll?.cancel();
    if (_channel != null) _ds.unsubscribe(_channel!);
    super.dispose();
  }

  /// [silent] reloads in the background (live updates) without the loading skeleton.
  Future<void> load({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) state = state.copyWith(loading: true, clearError: true);
    try {
      final results = await Future.wait([
        _ds.fetchOrders(
          branchId:      _branchId,
          status:        state.statusFilter  == 'All' ? null : state.statusFilter,
          orderType:     state.typeFilter    == 'All' ? null : state.typeFilter,
          paymentStatus: state.paymentFilter == 'All' ? null : state.paymentFilter,
          from:          state.from,
          to:            state.to,
          search:        state.search.isEmpty ? null : state.search,
        ),
        _ds.fetchSummary(branchId: _branchId, from: state.from, to: state.to),
      ]);
      if (!mounted) return;

      final orders  = results[0] as List<OrderModel>;
      final summary = results[1] as Map<String, dynamic>;
      final selectedId = state.selected?.id;

      state = state.copyWith(
        loading:        false,
        orders:         orders,
        // Keep the open detail panel in sync with the fresh data.
        selected:       selectedId == null
            ? null
            : orders.where((o) => o.id == selectedId).firstOrNull ?? state.selected,
        totalOrders:    summary['total_orders']    as int,
        pendingCount:   summary['pending_count']   as int,
        completedCount: summary['completed_count'] as int,
        totalRevenue:   (summary['total_revenue']  as num).toDouble(),
        totalPaid:      (summary['total_paid']     as num).toDouble(),
      );
    } catch (e) {
      if (!mounted) return;
      // A failed background refresh shouldn't interrupt the cashier.
      if (silent) return;
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setStatusFilter(String v)  { state = state.copyWith(statusFilter: v,  selected: null); load(); }
  void setTypeFilter(String v)    { state = state.copyWith(typeFilter: v,    selected: null); load(); }
  void setPaymentFilter(String v) { state = state.copyWith(paymentFilter: v, selected: null); load(); }
  void setSearch(String v)        { state = state.copyWith(search: v,        selected: null); load(); }

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(from: from, to: to, selected: null);
    load();
  }

  void clearFilters() {
    state = state.copyWith(
      statusFilter: 'All', typeFilter: 'All', paymentFilter: 'All',
      search: '', selected: null, from: null, to: null,
    );
    load();
  }

  void select(OrderModel? o) => state = state.copyWith(selected: o);

  // ── Update Order Status ───────────────────────────────────────────────────
  Future<void> updateStatus(String orderId, String status) async {
    if (!mounted) return;
    state = state.copyWith(updating: true, clearError: true);
    try {
      await _ds.updateStatus(orderId, status);
      if (!mounted) return;

      final order = state.orders.firstWhere(
            (o) => o.id == orderId,
        orElse: () => state.selected!,
      );

      if (order.tableNumber.isNotEmpty &&
          (status == 'completed' || status == 'cancelled')) {
        await _ds.freeTable(
          _branchId,
          order.tableNumber,
          status: status == 'cancelled' ? 'available' : 'cleaning',
        );
        if (!mounted) return;
      }

      final updated = order.copyWith(status: status);
      state = state.copyWith(
        updating:       false,
        orders:         state.orders.map((o) => o.id == orderId ? updated : o).toList(),
        selected:       state.selected?.id == orderId ? updated : state.selected,
        pendingCount:   order.status == 'pending' ? state.pendingCount - 1 : state.pendingCount,
        completedCount: status == 'completed' ? state.completedCount + 1 : state.completedCount,
      );

      // 👇 Dashboard refresh
      _ref.read(dashboardRefreshProvider.notifier).state++;
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(updating: false, error: e.toString());
    }
  }

  // ── Update Payment Status ─────────────────────────────────────────────────
  Future<void> updatePaymentStatus(String orderId, String paymentStatus) async {
    if (!mounted) return;
    state = state.copyWith(updating: true, clearError: true);
    try {
      await _ds.updatePaymentStatus(orderId, paymentStatus);
      if (!mounted) return;

      final order = state.orders.firstWhere(
            (o) => o.id == orderId,
        orElse: () => state.selected!,
      );

      if (paymentStatus == 'Paid' && order.paymentStatus != 'Paid') {
        if (order.paymentMethod == 'Cash') {
          await _cash.updateCash(
            branchId: _branchId,
            amount:   order.total,
            type:     'sale_in',
            refLabel: order.orderNumber,
            note:     'POS Sale — ${order.orderNumber}',
          );
          if (!mounted) return;
        }
        _ref.read(cashProvider(_branchId).notifier).load();
      }

      if (paymentStatus == 'Paid' &&
          order.orderType == 'Dine-in' &&
          order.tableNumber.isNotEmpty) {
        await _ds.freeTable(_branchId, order.tableNumber);
        if (!mounted) return;
      }

      final updated = order.copyWith(paymentStatus: paymentStatus);
      state = state.copyWith(
        updating: false,
        orders:   state.orders.map((o) => o.id == orderId ? updated : o).toList(),
        selected: state.selected?.id == orderId ? updated : state.selected,
        totalPaid: paymentStatus == 'Paid' && order.paymentStatus != 'Paid'
            ? state.totalPaid + order.total
            : state.totalPaid,
      );

      // 👇 Refresh the dashboard so revenue/cash balance update
      _ref.read(dashboardRefreshProvider.notifier).state++;
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(updating: false, error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ── Provider ──────────────────────────────────────────────────────────────────
final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final ds       = ref.watch(orderDatasourceProvider);
  final cash     = ref.watch(_cashDsProvider);
  final branchId = ref.watch(branchAuthProvider).branch?.branchId ?? '';
  return OrderNotifier(ds, cash, branchId, ref);
});

/// Emits each new website order for this branch as it arrives, so the POS can
/// alert staff on any screen.
final onlineOrderAlertsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final branchId = ref.watch(branchAuthProvider).branch?.branchId ?? '';
  if (branchId.isEmpty) return const Stream.empty();
  final ds = ref.watch(orderDatasourceProvider);
  final controller = StreamController<Map<String, dynamic>>();
  final channel = ds.subscribeToOrders(branchId, 'alerts', (payload) {
    if (payload.eventType == PostgresChangeEvent.insert &&
        payload.newRecord['customer_type'] == 'Online') {
      controller.add(payload.newRecord);
    }
  });
  ref.onDispose(() {
    ds.unsubscribe(channel);
    controller.close();
  });
  return controller.stream;
});
