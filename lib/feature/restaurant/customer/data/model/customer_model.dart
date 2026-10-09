enum CustomerType { walkIn, credit, online } // online = added from a website order
enum LoyaltyTier  { regular, silver, gold }

class CustomerModel {
  final String   id;
  final String   branchId;
  String         name;
  String         phone;
  CustomerType   type;
  int            orders;
  double         spent;
  double         balance;
  LoyaltyTier    loyalty;
  double         discount;
  final DateTime joinedAt;

  CustomerModel({
    required this.id,
    required this.branchId,
    required this.name,
    required this.phone,
    this.type     = CustomerType.walkIn,
    this.orders   = 0,
    this.spent    = 0,
    this.balance  = 0,
    this.loyalty  = LoyaltyTier.regular,
    this.discount = 0,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  // ── Supabase → Model ─────────────────────────────────────────────
  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id:       map['id']       as String,
      branchId: map['branch_id'] as String,
      name:     map['name']     as String,
      phone:    map['phone']    as String,
      type:     _parseType(map['type'] as String?),
      orders:   (map['orders']   as num).toInt(),
      spent:    (map['spent']    as num).toDouble(),
      balance:  (map['balance']  as num).toDouble(),
      loyalty:  _parseLoyalty(map['loyalty'] as String),
      discount: (map['discount'] as num).toDouble(),
      joinedAt: DateTime.parse(map['joined_at'] as String),
    );
  }

  // ── Model → Supabase ─────────────────────────────────────────────
  Map<String, dynamic> toInsertMap(String branchId) => {
    'branch_id': branchId,
    'name':      name,
    'phone':     phone,
    'type':      _typeValue(type),
    'orders':    orders,
    'spent':     spent,
    'balance':   balance,
    'loyalty':   loyalty.name,    // 'regular' | 'silver' | 'gold'
    'discount':  discount,
  };

  // orders/spent are kept up to date by a database trigger from the orders table,
  // so edits never write them back.
  Map<String, dynamic> toUpdateMap() => {
    'name':     name,
    'phone':    phone,
    'type':     _typeValue(type),
    'balance':  balance,
    'loyalty':  loyalty.name,
    'discount': discount,
  };

  static CustomerType _parseType(String? v) => switch (v) {
    'credit' => CustomerType.credit,
    'online' => CustomerType.online,
    _        => CustomerType.walkIn,
  };

  static String _typeValue(CustomerType t) => switch (t) {
    CustomerType.credit => 'credit',
    CustomerType.online => 'online',
    CustomerType.walkIn => 'walk_in',
  };

  String get typeLabel => switch (type) {
    CustomerType.credit => 'Credit',
    CustomerType.online => 'Online',
    CustomerType.walkIn => 'Walk-in',
  };

  static LoyaltyTier _parseLoyalty(String v) {
    switch (v) {
      case 'gold':   return LoyaltyTier.gold;
      case 'silver': return LoyaltyTier.silver;
      default:       return LoyaltyTier.regular;
    }
  }

  // ── Helpers (same as original Customer class) ─────────────────────
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String get loyaltyLabel {
    switch (loyalty) {
      case LoyaltyTier.gold:    return 'Gold';
      case LoyaltyTier.silver:  return 'Silver';
      case LoyaltyTier.regular: return 'Regular';
    }
  }
}