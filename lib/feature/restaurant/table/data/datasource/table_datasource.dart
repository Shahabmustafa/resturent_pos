// feature/branch/tables/data/datasource/table_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/table_model.dart';

class TableDatasource {
  final SupabaseClient _supabase;
  TableDatasource(this._supabase);

  // ── Fetch all tables for a branch ─────────────────────────────────
  Future<List<TableModel>> fetchTables(String branchId) async {
    final res = await _supabase
        .from('tables')
        .select()
        .eq('branch_id', branchId)
        .eq('is_active', true)
        .order('table_number');
    return (res as List).map((e) => TableModel.fromJson(e)).toList();
  }

  // ── Add new table ──────────────────────────────────────────────────
  Future<TableModel> addTable(TableModel table, String branchId) async {
    final res = await _supabase
        .from('tables')
        .insert(table.toInsertJson(branchId))
        .select()
        .single();
    return TableModel.fromJson(res);
  }

  // ── Update status only ─────────────────────────────────────────────
  Future<void> updateStatus(String tableId, TableStatus status) async {
    await _supabase
        .from('tables')
        .update({'status': status.toJson()})
        .eq('id', tableId);
  }

  // ── Soft delete (is_active = false) ───────────────────────────────
  Future<void> deleteTable(String tableId) async {
    await _supabase
        .from('tables')
        .update({'is_active': false})
        .eq('id', tableId);
  }
}