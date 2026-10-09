// lib/feature/cash/data/model/cash_model.dart

class BranchCash {
  final String branchId;
  final double balance;
  final DateTime updatedAt;

  const BranchCash({
    required this.branchId,
    required this.balance,
    required this.updatedAt,
  });

  factory BranchCash.fromJson(Map<String, dynamic> j) => BranchCash(
    branchId:  j['branch_id'] as String,
    balance:   (j['balance'] as num).toDouble(),
    updatedAt: DateTime.parse(j['updated_at'] as String),
  );

  BranchCash copyWith({String? branchId, double? balance, DateTime? updatedAt}) =>
      BranchCash(
        branchId:  branchId  ?? this.branchId,
        balance:   balance   ?? this.balance,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class CashTx {
  final int id;
  final String branchId;
  final String type;       // sale_in | supplier_payment | expense | manual_in | manual_out
  final String direction;  // in | out
  final double amount;
  final String? refLabel;
  final String? note;
  final DateTime createdAt;

  const CashTx({
    required this.id,
    required this.branchId,
    required this.type,
    required this.direction,
    required this.amount,
    this.refLabel,
    this.note,
    required this.createdAt,
  });

  factory CashTx.fromJson(Map<String, dynamic> j) => CashTx(
    id:        j['id'] as int,
    branchId:  j['branch_id'] as String,
    type:      j['type'] as String,
    direction: j['direction'] as String,
    amount:    (j['amount'] as num).toDouble(),
    refLabel:  j['ref_label'] as String?,
    note:      j['note'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'branch_id': branchId,
    'type':      type,
    'direction': direction,
    'amount':    amount,
    'ref_label': refLabel,
    'note':      note,
  };
}

// ─── Type constants ───────────────────────────────────────────────────────────

class CashTxType {
  static const saleIn           = 'sale_in';
  static const supplierPayment  = 'supplier_payment';
  static const expense          = 'expense';
  static const manualIn         = 'manual_in';
  static const manualOut        = 'manual_out';

  static String label(String t) {
    switch (t) {
      case saleIn:          return 'Sale';
      case supplierPayment: return 'Supplier Payment';
      case expense:         return 'Expense';
      case manualIn:        return 'Manual In';
      case manualOut:       return 'Manual Out';
      default:              return t;
    }
  }
}