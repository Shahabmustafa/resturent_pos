// lib/feature/cash/data/repository/cash_repository.dart

import '../datasource/cash_datasource.dart';
import '../model/cash_model.dart';

class CashRepository {
  final CashRemoteDatasource _ds;
  const CashRepository(this._ds);

  Future<BranchCash>  getCash(String branchId) => _ds.fetchCash(branchId);
  Future<List<CashTx>> getTxs(String branchId, {int limit = 100})  => _ds.fetchTxs(branchId, limit: limit);
  Future<BranchCash>  updateCash({
    required String branchId,
    required double amount,
    required String type,
    int?    refId,
    String? refLabel,
    String? note,
  }) => _ds.updateCash(
    branchId: branchId, amount: amount, type: type,
    refId: refId, refLabel: refLabel, note: note,
  );
  Future<BranchCash>  setOpening(String branchId, double amount) => _ds.setOpeningBalance(branchId, amount);
}