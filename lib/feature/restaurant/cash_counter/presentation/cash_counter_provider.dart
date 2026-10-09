import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/provider/branch_auth_provider.dart';
import '../../order/data/datasource/order_datasource.dart';
import '../../order/presentation/provider/order_provider.dart';
import '../data/cash_counter_datasource.dart';
import '../data/cash_counter_models.dart';

final cashCounterDatasourceProvider =
    Provider<CashCounterDatasource>((_) => CashCounterDatasource(Supabase.instance.client));

class CashCounterState {
  final bool loading;
  final bool busy; // an open / entry / close request is running
  final String? error;
  final CashCounter? open;
  final CounterSummary summary;
  final List<CounterEntry> entries;
  final List<CashCounter> history;

  const CashCounterState({
    this.loading = true,
    this.busy = false,
    this.error,
    this.open,
    this.summary = const CounterSummary(),
    this.entries = const [],
    this.history = const [],
  });

  CashCounterState copyWith({
    bool? loading,
    bool? busy,
    String? error,
    bool clearError = false,
    Object? open = _keep,
    CounterSummary? summary,
    List<CounterEntry>? entries,
    List<CashCounter>? history,
  }) =>
      CashCounterState(
        loading: loading ?? this.loading,
        busy:    busy ?? this.busy,
        error:   clearError ? null : error ?? this.error,
        open:    identical(open, _keep) ? this.open : open as CashCounter?,
        summary: summary ?? this.summary,
        entries: entries ?? this.entries,
        history: history ?? this.history,
      );
}

const _keep = Object();

class CashCounterNotifier extends StateNotifier<CashCounterState> {
  final CashCounterDatasource _ds;
  final OrderRemoteDatasource _orders;
  final String _branchId;
  RealtimeChannel? _channel;
  Timer? _debounce;
  Timer? _poll;

  CashCounterNotifier(this._ds, this._orders, this._branchId) : super(const CashCounterState()) {
    load();
    if (_branchId.isEmpty) return;
    // Sales totals follow orders live (new sales, payments, cancellations).
    _channel = _orders.subscribeToOrders(_branchId, 'counter', (_) => _refreshSoon());
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _refreshLive());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _poll?.cancel();
    if (_channel != null) _orders.unsubscribe(_channel!);
    super.dispose();
  }

  void _refreshSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _refreshLive);
  }

  Future<void> load() async {
    if (_branchId.isEmpty) return;
    try {
      final results = await Future.wait([_ds.fetchOpen(_branchId), _ds.fetchHistory(_branchId)]);
      final open = results[0] as CashCounter?;
      var summary = const CounterSummary();
      var entries = const <CounterEntry>[];
      if (open != null) {
        final live = await Future.wait([_ds.fetchSummary(open.id), _ds.fetchEntries(open.id)]);
        summary = live[0] as CounterSummary;
        entries = live[1] as List<CounterEntry>;
      }
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        open: open,
        summary: summary,
        entries: entries,
        history: results[1] as List<CashCounter>,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(loading: false, error: _message(e));
    }
  }

  /// Background refresh of the open counter's totals (no spinner, errors ignored).
  Future<void> _refreshLive() async {
    final open = state.open;
    if (open == null || state.busy) return;
    try {
      final summary = await _ds.fetchSummary(open.id);
      if (mounted && state.open?.id == open.id) state = state.copyWith(summary: summary);
    } catch (_) {}
  }

  Future<bool> openCounter(double openingCash) =>
      _run(() => _ds.open(_branchId, openingCash));

  Future<bool> addEntry({required bool isIn, required double amount, required String reason}) =>
      _run(() => _ds.addEntry(state.open!.id, isIn: isIn, amount: amount, reason: reason));

  /// Closes the open counter and returns its stored report.
  Future<CashCounter?> closeCounter({required double countedCash, required String notes}) async {
    final id = state.open?.id;
    if (id == null) return null;
    final ok = await _run(() => _ds.close(id, countedCash: countedCash, notes: notes));
    if (!ok) return null;
    return state.history.where((c) => c.id == id).firstOrNull;
  }

  void clearError() => state = state.copyWith(clearError: true);

  Future<bool> _run(Future<void> Function() action) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await action();
      await load();
      if (mounted) state = state.copyWith(busy: false);
      return true;
    } catch (e) {
      if (mounted) state = state.copyWith(busy: false, error: _message(e));
      return false;
    }
  }

  static String _message(Object e) =>
      e is PostgrestException ? e.message : e.toString().replaceFirst('Exception: ', '');
}

final cashCounterProvider = StateNotifierProvider.autoDispose<CashCounterNotifier, CashCounterState>((ref) {
  final branchId = ref.watch(branchAuthProvider).branch?.branchId ?? '';
  return CashCounterNotifier(
    ref.watch(cashCounterDatasourceProvider),
    ref.watch(orderDatasourceProvider),
    branchId,
  );
});
