// lib/feature/inventory/data/model/inventory_model.dart

class StockItem {
  final int id;
  final String branchId;
  final int? supplierId;
  final String name;
  final String category;
  final String unit;
  double qty;
  final double minQty;
  final double cost;
  DateTime updatedAt;

  StockItem({
    required this.id,
    required this.branchId,
    this.supplierId,
    required this.name,
    required this.category,
    required this.unit,
    required this.qty,
    required this.minQty,
    required this.cost,
    required this.updatedAt,
  });

  bool get isLow      => qty <= minQty;
  bool get isCritical => qty <= minQty * 0.5;
  double get totalVal => qty * cost;

  factory StockItem.fromJson(Map<String, dynamic> j) => StockItem(
    id:          j['id'] as int,
    branchId:    j['branch_id'] as String,
    supplierId:  j['supplier_id'] as int?,
    name:        j['name'] as String,
    category:    j['category'] as String,
    unit:        j['unit'] as String,
    qty:         (j['qty'] as num).toDouble(),
    minQty:      (j['min_qty'] as num).toDouble(),
    cost:        (j['cost'] as num).toDouble(),
    updatedAt:   DateTime.parse(j['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'branch_id':   branchId,
    'supplier_id': supplierId,
    'name':        name,
    'category':    category,
    'unit':        unit,
    'qty':         qty,
    'min_qty':     minQty,
    'cost':        cost,
    'updated_at':  updatedAt.toIso8601String(),
  };

  StockItem copyWith({
    int? id, String? branchId, int? supplierId, String? name,
    String? category, String? unit, double? qty, double? minQty,
    double? cost, DateTime? updatedAt,
  }) => StockItem(
    id:          id ?? this.id,
    branchId:    branchId ?? this.branchId,
    supplierId:  supplierId ?? this.supplierId,
    name:        name ?? this.name,
    category:    category ?? this.category,
    unit:        unit ?? this.unit,
    qty:         qty ?? this.qty,
    minQty:      minQty ?? this.minQty,
    cost:        cost ?? this.cost,
    updatedAt:   updatedAt ?? this.updatedAt,
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class Supplier {
  final int id;
  final String branchId;
  final String name;
  final String phone;
  final String address;
  double totalBiz;
  double totalPaid;
  List<SupTx> txs;

  Supplier({
    required this.id,
    required this.branchId,
    required this.name,
    required this.phone,
    required this.address,
    required this.totalBiz,
    required this.totalPaid,
    this.txs = const [],
  });

  double get balance => totalBiz - totalPaid;

  factory Supplier.fromJson(Map<String, dynamic> j) => Supplier(
    id:        j['id'] as int,
    branchId:  j['branch_id'] as String,
    name:      j['name'] as String,
    phone:     j['phone'] as String? ?? '',
    address:   j['address'] as String? ?? '',
    totalBiz:  (j['total_biz'] as num).toDouble(),
    totalPaid: (j['total_paid'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'branch_id':  branchId,
    'name':       name,
    'phone':      phone,
    'address':    address,
    'total_biz':  totalBiz,
    'total_paid': totalPaid,
  };

  Supplier copyWith({
    int? id, String? branchId, String? name, String? phone,
    String? address, double? totalBiz, double? totalPaid, List<SupTx>? txs,
  }) => Supplier(
    id:        id ?? this.id,
    branchId:  branchId ?? this.branchId,
    name:      name ?? this.name,
    phone:     phone ?? this.phone,
    address:   address ?? this.address,
    totalBiz:  totalBiz ?? this.totalBiz,
    totalPaid: totalPaid ?? this.totalPaid,
    txs:       txs ?? this.txs,
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class SupTx {
  final int id;
  final String branchId;
  final int supplierId;
  final String desc;
  final double amount;
  final bool isPay;
  final DateTime date;

  const SupTx({
    required this.id,
    required this.branchId,
    required this.supplierId,
    required this.desc,
    required this.amount,
    required this.isPay,
    required this.date,
  });

  factory SupTx.fromJson(Map<String, dynamic> j) => SupTx(
    id:         j['id'] as int,
    branchId:   j['branch_id'] as String,
    supplierId: j['supplier_id'] as int,
    desc:       j['description'] as String,
    amount:     (j['amount'] as num).toDouble(),
    isPay:      j['is_payment'] as bool,
    date:       DateTime.parse(j['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'branch_id':   branchId,
    'supplier_id': supplierId,
    'description': desc,
    'amount':      amount,
    'is_payment':  isPay,
  };

  SupTx copyWith({
    int? id, String? branchId, int? supplierId, String? desc,
    double? amount, bool? isPay, DateTime? date,
  }) => SupTx(
    id:         id         ?? this.id,
    branchId:   branchId   ?? this.branchId,
    supplierId: supplierId ?? this.supplierId,
    desc:       desc       ?? this.desc,
    amount:     amount     ?? this.amount,
    isPay:      isPay      ?? this.isPay,
    date:       date       ?? this.date,
  );
}