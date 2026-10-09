class ReceiptSettings {
  final String branchId;
  final String? logoUrl;
  final int fontIndex;
  final bool showLogo;
  final bool showTaxBreakdown;
  final bool showCashierName;
  final bool showFbrQr;
  final bool autoPrintKitchenToken;
  final String footerText;
  final String headerNote;

  const ReceiptSettings({
    required this.branchId,
    this.logoUrl,
    this.fontIndex = 0,
    this.showLogo = true,
    this.showTaxBreakdown = true,
    this.showCashierName = false,
    this.showFbrQr = true,
    this.autoPrintKitchenToken = true,
    this.footerText = 'Thank you for dining with us!',
    this.headerNote = 'Fresh • Halal • Hygienic',
  });

  factory ReceiptSettings.fromMap(Map<String, dynamic> m) => ReceiptSettings(
    branchId: m['branch_id'] as String,
    fontIndex: (m['font_index'] as int?) ?? 0,
    logoUrl: m['logo_url'] as String?,
    showLogo: (m['show_logo'] as bool?) ?? true,
    showTaxBreakdown: (m['show_tax_breakdown'] as bool?) ?? true,
    showCashierName: (m['show_cashier_name'] as bool?) ?? false,
    showFbrQr: (m['show_fbr_qr'] as bool?) ?? true,
    autoPrintKitchenToken: (m['auto_print_kitchen_token'] as bool?) ?? true,
    footerText: (m['footer_text'] as String?) ?? 'Thank you for dining with us!',
    headerNote: (m['header_note'] as String?) ?? 'Fresh • Halal • Hygienic',
  );

  Map<String, dynamic> toMap() => {
    'branch_id': branchId,
    'font_index': fontIndex,
    'logo_url': logoUrl,
    'show_logo': showLogo,
    'show_tax_breakdown': showTaxBreakdown,
    'show_cashier_name': showCashierName,
    'show_fbr_qr': showFbrQr,
    'auto_print_kitchen_token': autoPrintKitchenToken,
    'footer_text': footerText,
    'header_note': headerNote,
    'updated_at': DateTime.now().toIso8601String(),
  };

  ReceiptSettings copyWith({
    int? fontIndex,
    String? logoUrl,
    bool? showLogo,
    bool? showTaxBreakdown,
    bool? showCashierName,
    bool? showFbrQr,
    bool? autoPrintKitchenToken,
    String? footerText,
    String? headerNote,
  }) =>
      ReceiptSettings(
        branchId: branchId,
        fontIndex: fontIndex ?? this.fontIndex,
        logoUrl: logoUrl ?? this.logoUrl,
        showLogo: showLogo ?? this.showLogo,
        showTaxBreakdown: showTaxBreakdown ?? this.showTaxBreakdown,
        showCashierName: showCashierName ?? this.showCashierName,
        showFbrQr: showFbrQr ?? this.showFbrQr,
        autoPrintKitchenToken: autoPrintKitchenToken ?? this.autoPrintKitchenToken,
        footerText: footerText ?? this.footerText,
        headerNote: headerNote ?? this.headerNote,
      );
}