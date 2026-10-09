import 'package:supabase_flutter/supabase_flutter.dart';
import 'cash_counter_models.dart';

/// Reads `cash_counters` / `cash_counter_entries`; every change goes through the
/// database functions, which check the branch and record who did it.
class CashCounterDatasource {
  final SupabaseClient _db;
  const CashCounterDatasource(this._db);

  Future<CashCounter?> fetchOpen(String branchId) async {
    final row = await _db
        .from('cash_counters')
        .select()
        .eq('branch_id', branchId)
        .eq('status', 'open')
        .maybeSingle();
    return row == null ? null : CashCounter.fromJson(row);
  }

  Future<List<CashCounter>> fetchHistory(String branchId, {int limit = 30}) async {
    final rows = await _db
        .from('cash_counters')
        .select()
        .eq('branch_id', branchId)
        .eq('status', 'closed')
        .order('opened_at', ascending: false)
        .limit(limit);
    return [for (final r in rows) CashCounter.fromJson(r)];
  }

  Future<List<CounterEntry>> fetchEntries(String counterId) async {
    final rows = await _db
        .from('cash_counter_entries')
        .select()
        .eq('counter_id', counterId)
        .order('created_at', ascending: false);
    return [for (final r in rows) CounterEntry.fromJson(r)];
  }

  Future<CounterSummary> fetchSummary(String counterId) async {
    final res = await _db.rpc('cash_counter_summary', params: {'p_counter_id': counterId});
    return CounterSummary.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<void> open(String branchId, double openingCash) =>
      _db.rpc('open_cash_counter', params: {'p_branch_id': branchId, 'p_opening_cash': openingCash});

  Future<void> addEntry(String counterId, {required bool isIn, required double amount, required String reason}) =>
      _db.rpc('add_cash_counter_entry', params: {
        'p_counter_id': counterId,
        'p_kind': isIn ? 'in' : 'out',
        'p_amount': amount,
        'p_reason': reason,
      });

  Future<void> close(String counterId, {required double countedCash, required String notes}) =>
      _db.rpc('close_cash_counter', params: {
        'p_counter_id': counterId,
        'p_counted_cash': countedCash,
        'p_notes': notes,
      });
}
