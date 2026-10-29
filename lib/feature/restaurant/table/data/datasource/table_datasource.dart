// feature/branch/tables/data/datasource/table_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/table_model.dart';

class TableDatasource {
  final SupabaseClient _supabase;
  TableDatasource(this._supabase);

  // ── Fetch all tables ───────────────────────────────────────────────
  Future<List<TableModel>> fetchTables() async {
    final res = await _supabase
        .from('tables')
        .select()
        .isFilter('deleted_at', null)
        .order('table_number');
    return (res as List).map((e) => TableModel.fromJson(e)).toList();
  }

  // ── Add new table ──────────────────────────────────────────────────
  Future<TableModel> addTable(String tableNumber) async {
    final res = await _supabase
        .from('tables')
        .insert({'table_number': tableNumber})
        .select()
        .single();
    return TableModel.fromJson(res);
  }

  // ── Soft delete (deleted_at = now) ─────────────────────────────────
  Future<void> deleteTable(String tableId) async {
    await _supabase
        .from('tables')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', tableId);
  }

  // ── Table numbers that currently have an open dine-in order ───────
  static const _closedStatuses = '(completed,cancelled,delivered)';

  Future<Set<String>> fetchBusyTableNumbers(String branchId) async {
    final res = await _supabase
        .from('orders')
        .select('table_number')
        .eq('order_type', 'Dine-in')
        .not('status', 'in', _closedStatuses);
    return {
      for (final r in res as List)
        if ((r['table_number'] as String?)?.isNotEmpty ?? false)
          r['table_number'] as String,
    };
  }

  Future<void> _moveOrders(String branchId, String from, String to) => _supabase
      .from('orders')
      .update({'table_number': to})
      .eq('order_type', 'Dine-in')
      .eq('table_number', from)
      .not('status', 'in', _closedStatuses);

  // ── Swap: the open orders of two tables trade places ──────────────
  Future<void> swapTables(String branchId, String a, String b) async {
    const temp = '__swap__';
    await _moveOrders(branchId, a, temp);
    await _moveOrders(branchId, b, a);
    await _moveOrders(branchId, temp, b);
  }

  // ── Merge: all open orders of [from] move onto [to] ─
  Future<void> mergeTables(String branchId, String from, String to) async {
    await _moveOrders(branchId, from, to);
  }
}
