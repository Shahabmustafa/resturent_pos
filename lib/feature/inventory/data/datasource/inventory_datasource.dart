// lib/feature/inventory/data/datasource/inventory_remote_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/inventory_model.dart';

class InventoryRemoteDatasource {
  final SupabaseClient _db;
  const InventoryRemoteDatasource(this._db);

  // ── STOCK ─────────────────────────────────────────────────────────────────

  Future<List<StockItem>> fetchStock(String branchId) async {
    final res = await _db
        .from('stock_items')
        .select()
        .eq('branch_id', branchId)
        .order('name');
    return (res as List).map((e) => StockItem.fromJson(e)).toList();
  }

  Future<StockItem> addStock(StockItem item) async {
    final res = await _db
        .from('stock_items')
        .insert(item.toJson())
        .select()
        .single();
    return StockItem.fromJson(res);
  }

  Future<StockItem> updateStock(StockItem item) async {
    final res = await _db
        .from('stock_items')
        .update(item.toJson())
        .eq('id', item.id)
        .eq('branch_id', item.branchId)
        .select()
        .single();
    return StockItem.fromJson(res);
  }

  Future<void> deleteStock(int id, String branchId) async {
    await _db
        .from('stock_items')
        .delete()
        .eq('id', id)
        .eq('branch_id', branchId);
  }

  Future<StockItem> restockItem(int id, String branchId, double addQty) async {
    // Read current qty, then update
    final current = await _db
        .from('stock_items')
        .select('qty')
        .eq('id', id)
        .eq('branch_id', branchId)
        .single();
    final newQty = (current['qty'] as num).toDouble() + addQty;
    final res = await _db
        .from('stock_items')
        .update({'qty': newQty, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .eq('branch_id', branchId)
        .select()
        .single();
    return StockItem.fromJson(res);
  }

  // ── SUPPLIERS ─────────────────────────────────────────────────────────────

  Future<List<Supplier>> fetchSuppliers(String branchId) async {
    final res = await _db
        .from('suppliers')
        .select()
        .eq('branch_id', branchId)
        .order('name');
    return (res as List).map((e) => Supplier.fromJson(e)).toList();
  }

  Future<Supplier> addSupplier(Supplier supplier) async {
    final res = await _db
        .from('suppliers')
        .insert(supplier.toJson())
        .select()
        .single();
    return Supplier.fromJson(res);
  }

  Future<void> deleteSupplier(int id, String branchId) async {
    await _db
        .from('suppliers')
        .delete()
        .eq('id', id)
        .eq('branch_id', branchId);
  }

  // ── SUPPLIER TRANSACTIONS ─────────────────────────────────────────────────

  Future<List<SupTx>> fetchTxs(int supplierId, String branchId) async {
    final res = await _db
        .from('supplier_transactions')
        .select()
        .eq('supplier_id', supplierId)
        .eq('branch_id', branchId)
        .order('created_at', ascending: false);
    return (res as List).map((e) => SupTx.fromJson(e)).toList();
  }

  Future<SupTx> addTx(SupTx tx) async {
    final res = await _db
        .from('supplier_transactions')
        .insert(tx.toJson())
        .select()
        .single();

    // Update supplier totals
    final col = tx.isPay ? 'total_paid' : 'total_biz';
    final current = await _db
        .from('suppliers')
        .select(col)
        .eq('id', tx.supplierId)
        .single();
    final newVal = (current[col] as num).toDouble() + tx.amount;
    await _db
        .from('suppliers')
        .update({col: newVal})
        .eq('id', tx.supplierId)
        .eq('branch_id', tx.branchId);

    return SupTx.fromJson(res);
  }
}