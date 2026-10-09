import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasource/cash_datasource.dart';
import '../../data/model/cash_model.dart';
import '../../data/repository/cash_repository.dart';


// ─── Infrastructure ───────────────────────────────────────────────────────────

final _supabaseProvider = Provider<SupabaseClient>((_) => Supabase.instance.client);

final _cashDsProvider = Provider<CashRemoteDatasource>((ref) => CashRemoteDatasource(ref.watch(_supabaseProvider)),);

final cashRepoProvider = Provider<CashRepository>((ref) => CashRepository(ref.watch(_cashDsProvider)),);

// ─── State ────────────────────────────────────────────────────────────────────

class CashState {
  final BranchCash? cash;
  final List<CashTx> txs;
  final bool loading;
  final String? error;

  const CashState({
    this.cash,
    this.txs    = const [],
    this.loading = false,
    this.error,
  });

  double get balance => cash?.balance ?? 0.0;

  CashState copyWith({
    BranchCash?  cash,
    List<CashTx>? txs,
    bool?         loading,
    String?       error,
  }) => CashState(
    cash:    cash    ?? this.cash,
    txs:     txs     ?? this.txs,
    loading: loading ?? this.loading,
    error:   error,
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class CashNotifier extends StateNotifier<CashState> {
  final CashRepository _repo;
  final String branchId;

  CashNotifier(this._repo, this.branchId) : super(const CashState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true);
    try {
      final results = await Future.wait([
        _repo.getCash(branchId),
        _repo.getTxs(branchId),
      ]);
      state = state.copyWith(
        loading: false,
        cash:    results[0] as BranchCash,
        txs:     results[1] as List<CashTx>,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  // ── Manual Cash In ────────────────────────────────────────────────────────

  Future<void> manualIn(double amount, String note) async {
    try {
      final updated = await _repo.updateCash(
        branchId: branchId,
        amount:   amount,
        type:     CashTxType.manualIn,
        note:     note,
      );
      await _refreshTxs(updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Manual Cash Out ───────────────────────────────────────────────────────

  Future<void> manualOut(double amount, String note) async {
    if (amount > state.balance) {
      state = state.copyWith(error: 'Insufficient balance');
      return;
    }
    try {
      final updated = await _repo.updateCash(
        branchId: branchId,
        amount:   -amount,
        type:     CashTxType.manualOut,
        note:     note,
      );
      await _refreshTxs(updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Expense ───────────────────────────────────────────────────────────────

  Future<void> addExpense(double amount, String note) async {
    if (amount > state.balance) {
      state = state.copyWith(error: 'Not enough cash');
      return;
    }
    try {
      final updated = await _repo.updateCash(
        branchId: branchId,
        amount:   -amount,
        type:     CashTxType.expense,
        note:     note,
      );
      await _refreshTxs(updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Sale Cash In (called from Order flow) ─────────────────────────────────

  Future<void> recordSale(double amount, {int? orderId, String? orderLabel}) async {
    try {
      final updated = await _repo.updateCash(
        branchId: branchId,
        amount:   amount,
        type:     CashTxType.saleIn,
        refId:    orderId,
        refLabel: orderLabel,
      );
      await _refreshTxs(updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Supplier Payment Out (called from Inventory flow) ─────────────────────

  Future<void> recordSupplierPayment(
      double amount, int supplierId, String supplierName) async {
    if (amount > state.balance) {
      state = state.copyWith(error: 'Not enough cash — payment cannot be made');
      return;
    }
    try {
      final updated = await _repo.updateCash(
        branchId: branchId,
        amount:   -amount,
        type:     CashTxType.supplierPayment,
        refId:    supplierId,
        refLabel: 'Supplier: $supplierName',
      );
      await _refreshTxs(updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Set Opening Balance ───────────────────────────────────────────────────

  Future<void> setOpeningBalance(double amount) async {
    try {
      final updated = await _repo.setOpening(branchId, amount);
      await _refreshTxs(updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _refreshTxs(BranchCash updated) async {
    final txs = await _repo.getTxs(branchId);
    state = state.copyWith(cash: updated, txs: txs);
  }

  void clearError() => state = state.copyWith(error: null);
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final cashProvider = StateNotifierProvider.family<CashNotifier, CashState, String>(
      (ref, branchId) => CashNotifier(ref.watch(cashRepoProvider), branchId),
);

final cashBalanceProvider = Provider.family<double, String>(
      (ref, bid) => ref.watch(cashProvider(bid)).balance,
);