// lib/feature/cash/data/datasource/cash_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/cash_model.dart';

class CashRemoteDatasource {
  final SupabaseClient _db;
  const CashRemoteDatasource(this._db);

  // ── Cash Balance ──────────────────────────────────────────────────────────

  Future<BranchCash> fetchCash(String branchId) async {
    final res = await _db
        .from('branch_cash')
        .select()
        .eq('branch_id', branchId)
        .maybeSingle();

    if (res == null) {
      // First time — insert zero balance
      final inserted = await _db
          .from('branch_cash')
          .insert({
        'branch_id': branchId,
        'balance':   0.0,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .select()
          .single();
      return BranchCash.fromJson(inserted);
    }
    return BranchCash.fromJson(res);
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  Future<List<CashTx>> fetchTxs(String branchId, {int limit = 100}) async {
    final res = await _db
        .from('cash_transactions')
        .select()
        .eq('branch_id', branchId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (res as List).map((e) => CashTx.fromJson(e)).toList();
  }

  // ── Core update via RPC ───────────────────────────────────────────────────
  // RPC handles: balance update + transaction log atomically

  Future<BranchCash> updateCash({
    required String branchId,
    required double amount,      // positive = in, negative = out
    required String type,
    int?    refId,
    String? refLabel,
    String? note,
  }) async {
    await _db.rpc('update_branch_cash', params: {
      'p_branch_id':  branchId,
      'p_amount':     amount,
      'p_type':       type,
      'p_ref_id':     refId,
      'p_ref_label':  refLabel,
      'p_note':       note,
    });
    return fetchCash(branchId);
  }

  // ── Set Opening Balance ───────────────────────────────────────────────────

  Future<BranchCash> setOpeningBalance(String branchId, double amount) async {
    // Fetch current, calculate diff
    final current = await fetchCash(branchId);
    final diff    = amount - current.balance;
    if (diff == 0) return current;

    return updateCash(
      branchId: branchId,
      amount:   diff,
      type:     diff > 0 ? CashTxType.manualIn : CashTxType.manualOut,
      note:     'Opening balance set',
    );
  }
}