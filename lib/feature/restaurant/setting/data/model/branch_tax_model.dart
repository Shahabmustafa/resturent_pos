class BranchTaxSettings {
  final String id;
  final String branchId;
  final bool   enableTax;
  final bool   taxInclusive;
  final bool   showOnReceipt;
  final bool   fbrEnabled;
  final String fbrToken;
  final String fbrUrl;
  final List<TaxSlab> slabs;

  const BranchTaxSettings({
    required this.id,
    required this.branchId,
    this.enableTax     = true,
    this.taxInclusive  = false,
    this.showOnReceipt = true,
    this.fbrEnabled    = false,
    this.fbrToken      = '',
    this.fbrUrl        = '',
    this.slabs         = const [],
  });

  /// Total tax rate from the active slabs
  double get activeTaxRate => slabs
      .where((s) => s.isActive)
      .fold(0.0, (sum, s) => sum + s.rate);

  factory BranchTaxSettings.fromMap(Map<String, dynamic> m, {List<TaxSlab> slabs = const []}) =>
      BranchTaxSettings(
        id:            m['id'] as String,
        branchId:      m['branch_id'] as String,
        enableTax:     (m['enable_tax']     as bool?) ?? true,
        taxInclusive:  (m['tax_inclusive']  as bool?) ?? false,
        showOnReceipt: (m['show_on_receipt'] as bool?) ?? true,
        fbrEnabled:    (m['fbr_enabled']    as bool?) ?? false,
        fbrToken:      (m['fbr_token']      as String?) ?? '',
        fbrUrl:        (m['fbr_url']        as String?) ?? '',
        slabs:         slabs,
      );

  Map<String, dynamic> toMap() => {
    'branch_id':      branchId,
    'enable_tax':     enableTax,
    'tax_inclusive':  taxInclusive,
    'show_on_receipt': showOnReceipt,
    'fbr_enabled':    fbrEnabled,
    'fbr_token':      fbrToken,
    'fbr_url':        fbrUrl,
    'updated_at':     DateTime.now().toIso8601String(),
  };

  BranchTaxSettings copyWith({
    bool?         enableTax,
    bool?         taxInclusive,
    bool?         showOnReceipt,
    bool?         fbrEnabled,
    String?       fbrToken,
    String?       fbrUrl,
    List<TaxSlab>? slabs,
  }) => BranchTaxSettings(
    id:            id,
    branchId:      branchId,
    enableTax:     enableTax     ?? this.enableTax,
    taxInclusive:  taxInclusive  ?? this.taxInclusive,
    showOnReceipt: showOnReceipt ?? this.showOnReceipt,
    fbrEnabled:    fbrEnabled    ?? this.fbrEnabled,
    fbrToken:      fbrToken      ?? this.fbrToken,
    fbrUrl:        fbrUrl        ?? this.fbrUrl,
    slabs:         slabs         ?? this.slabs,
  );
}

class TaxSlab {
  final String? id;       // null = new slab (not in the DB yet)
  final String  branchId;
  final String  name;
  final double  rate;
  final bool    isActive;
  final int     sortOrder;

  const TaxSlab({
    this.id,
    required this.branchId,
    required this.name,
    required this.rate,
    this.isActive  = true,
    this.sortOrder = 0,
  });

  factory TaxSlab.fromMap(Map<String, dynamic> m) => TaxSlab(
    id:        m['id'] as String?,
    branchId:  m['branch_id'] as String,
    name:      m['name'] as String,
    rate:      (m['rate'] as num).toDouble(),
    isActive:  (m['is_active'] as bool?) ?? true,
    sortOrder: (m['sort_order'] as int?) ?? 0,
  );

  Map<String, dynamic> toInsertMap(String branchId, int order) => {
    'branch_id':  branchId,
    'name':       name,
    'rate':       rate,
    'is_active':  isActive,
    'sort_order': order,
  };

  TaxSlab copyWith({
    String? name,
    double? rate,
    bool?   isActive,
  }) => TaxSlab(
    id:        id,
    branchId:  branchId,
    name:      name     ?? this.name,
    rate:      rate     ?? this.rate,
    isActive:  isActive ?? this.isActive,
    sortOrder: sortOrder,
  );
}
