import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../restaurant/cash/presentation/provider/cash_provider.dart';
import '../../data/datasource/inventory_datasource.dart';
import '../../data/model/inventory_model.dart';
import '../../data/repository/inventory_repository.dart';
import 'package:resturent_application/core/constants/currency.dart';

final _supabaseProvider = Provider<SupabaseClient>((_) => Supabase.instance.client);
final _dsProvider = Provider((ref) => InventoryRemoteDatasource(ref.watch(_supabaseProvider)));
final inventoryRepoProvider = Provider((ref) => InventoryRepository(ref.watch(_dsProvider)));

class InventoryState {
  final List<StockItem> stock;
  final List<Supplier> suppliers;
  final bool loading;
  final String? error;
  const InventoryState({this.stock = const [], this.suppliers = const [], this.loading = false, this.error});

  InventoryState copyWith({List<StockItem>? stock, List<Supplier>? suppliers, bool? loading, String? error}) =>
      InventoryState(
        stock: stock ?? this.stock,
        suppliers: suppliers ?? this.suppliers,
        loading: loading ?? this.loading,
        error: error,
      );
}

class InventoryNotifier extends StateNotifier<InventoryState> {
  final InventoryRepository _repo;
  final Ref _ref;
  final String branchId;

  InventoryNotifier(this._repo, this._ref, this.branchId) : super(const InventoryState()) { load(); }

  Future<void> load() async {
    state = state.copyWith(loading: true);
    try {
      final r = await Future.wait([_repo.getStock(branchId), _repo.getSuppliers(branchId)]);
      state = state.copyWith(loading: false, stock: r[0] as List<StockItem>, suppliers: r[1] as List<Supplier>);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  // ── STOCK ──────────────────────────────────────────────────────────────────

  // When stock is added with a supplier selected, the purchase amount
  // (qty * cost) is automatically added to that supplier's ledger (credit purchase).
  Future<void> addStock(StockItem item) async {
    try {
      final saved = await _repo.addStock(item);
      state = state.copyWith(stock: [...state.stock, saved]);

      if (saved.supplierId != null && saved.totalVal > 0) {
        final sup = state.suppliers.where((s) => s.id == saved.supplierId).firstOrNull;
        if (sup != null) {
          await addTx(sup, SupTx(
            id: 0, branchId: branchId, supplierId: sup.id,
            desc: 'Stock purchase: ${saved.name} (${saved.qty} ${saved.unit})',
            amount: saved.totalVal, isPay: false, date: DateTime.now(),
          ));
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateStock(StockItem item) async {
    try {
      final saved = await _repo.updateStock(item);
      state = state.copyWith(stock: state.stock.map((s) => s.id == saved.id ? saved : s).toList());
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> deleteStock(int id) async {
    try {
      await _repo.deleteStock(id, branchId);
      state = state.copyWith(stock: state.stock.where((s) => s.id != id).toList());
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> restock(int id, double qty) async {
    try {
      final saved = await _repo.restock(id, branchId, qty);
      state = state.copyWith(stock: state.stock.map((s) => s.id == saved.id ? saved : s).toList());
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  // ── SUPPLIERS ──────────────────────────────────────────────────────────────

  Future<void> addSupplier(Supplier s) async {
    try {
      final saved = await _repo.addSupplier(s);
      state = state.copyWith(suppliers: [...state.suppliers, saved]);
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      await _repo.deleteSupplier(id, branchId);
      state = state.copyWith(suppliers: state.suppliers.where((s) => s.id != id).toList());
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> loadTxs(Supplier sup) async {
    try {
      final txs = await _repo.getTxs(sup.id, branchId);
      state = state.copyWith(suppliers: state.suppliers.map((s) => s.id == sup.id ? s.copyWith(txs: txs) : s).toList());
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  // Payment (isPay) => cash is deducted. Purchase (!isPay) => only the supplier balance grows.
  Future<void> addTx(Supplier sup, SupTx tx) async {
    if (tx.isPay) {
      final cash = _ref.read(cashProvider(branchId)).balance;
      if (tx.amount > cash) {
        state = state.copyWith(error: 'Insufficient cash. Available: ${formatMoney(cash)}');
        return;
      }
    }
    try {
      final saved = await _repo.addTx(tx);
      state = state.copyWith(suppliers: state.suppliers.map((s) {
        if (s.id != sup.id) return s;
        return s.copyWith(
          txs: [saved, ...s.txs],
          totalBiz: tx.isPay ? s.totalBiz : s.totalBiz + tx.amount,
          totalPaid: tx.isPay ? s.totalPaid + tx.amount : s.totalPaid,
        );
      }).toList());

      if (tx.isPay) {
        await _ref.read(cashProvider(branchId).notifier).recordSupplierPayment(tx.amount, sup.id, sup.name);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final inventoryProvider = StateNotifierProvider.family<InventoryNotifier, InventoryState, String>(
      (ref, branchId) => InventoryNotifier(ref.watch(inventoryRepoProvider), ref, branchId),
);