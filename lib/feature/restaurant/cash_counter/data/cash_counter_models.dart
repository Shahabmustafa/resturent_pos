double _num(Object? v) => v == null ? 0 : double.tryParse('$v') ?? 0;

/// One shift of the cash counter (table `cash_counters`).
class CashCounter {
  final String id;
  final bool isOpen;
  final DateTime openedAt;
  final String openedByName;
  final double openingCash;
  final DateTime? closedAt;
  final String closedByName;
  final String notes;

  /// Closing report — only set once the counter is closed.
  final CounterSummary? report;
  final double? countedCash;
  final double? difference;

  const CashCounter({
    required this.id,
    required this.isOpen,
    required this.openedAt,
    required this.openedByName,
    required this.openingCash,
    this.closedAt,
    this.closedByName = '',
    this.notes = '',
    this.report,
    this.countedCash,
    this.difference,
  });

  factory CashCounter.fromJson(Map<String, dynamic> j) {
    final closed = j['status'] == 'closed';
    return CashCounter(
      id:           j['id'] as String,
      isOpen:       !closed,
      openedAt:     DateTime.parse(j['opened_at'] as String).toLocal(),
      openedByName: (j['opened_by_name'] as String?) ?? '',
      openingCash:  _num(j['opening_cash']),
      closedAt:     j['closed_at'] == null ? null : DateTime.parse(j['closed_at'] as String).toLocal(),
      closedByName: (j['closed_by_name'] as String?) ?? '',
      notes:        (j['notes'] as String?) ?? '',
      report:       closed ? CounterSummary.fromJson(j) : null,
      countedCash:  closed ? _num(j['counted_cash']) : null,
      difference:   closed ? _num(j['difference']) : null,
    );
  }
}

/// Sales and cash movement for a shift (live from `cash_counter_summary`, or the
/// stored closing report).
class CounterSummary {
  final double cashSales;
  final double cardSales;
  final double onlineSales;
  final double totalSales;
  final int orderCount;
  final double discountTotal;
  final double taxTotal;
  final int unpaidCount;
  final double unpaidAmount;
  final double cashIn;
  final double cashOut;
  final double expectedCash;

  const CounterSummary({
    this.cashSales = 0,
    this.cardSales = 0,
    this.onlineSales = 0,
    this.totalSales = 0,
    this.orderCount = 0,
    this.discountTotal = 0,
    this.taxTotal = 0,
    this.unpaidCount = 0,
    this.unpaidAmount = 0,
    this.cashIn = 0,
    this.cashOut = 0,
    this.expectedCash = 0,
  });

  factory CounterSummary.fromJson(Map<String, dynamic> j) => CounterSummary(
        cashSales:     _num(j['cash_sales']),
        cardSales:     _num(j['card_sales']),
        onlineSales:   _num(j['online_sales']),
        totalSales:    _num(j['total_sales']),
        orderCount:    _num(j['order_count']).toInt(),
        discountTotal: _num(j['discount_total']),
        taxTotal:      _num(j['tax_total']),
        unpaidCount:   _num(j['unpaid_count']).toInt(),
        unpaidAmount:  _num(j['unpaid_amount']),
        cashIn:        _num(j['cash_in']),
        cashOut:       _num(j['cash_out']),
        expectedCash:  _num(j['expected_cash']),
      );
}

/// Cash added to (in) or taken from (out) the drawer during a shift.
class CounterEntry {
  final String id;
  final bool isIn;
  final double amount;
  final String reason;
  final String byName;
  final DateTime at;

  const CounterEntry({
    required this.id,
    required this.isIn,
    required this.amount,
    required this.reason,
    required this.byName,
    required this.at,
  });

  factory CounterEntry.fromJson(Map<String, dynamic> j) => CounterEntry(
        id:     j['id'] as String,
        isIn:   j['kind'] == 'in',
        amount: _num(j['amount']),
        reason: (j['reason'] as String?) ?? '',
        byName: (j['created_by_name'] as String?) ?? '',
        at:     DateTime.parse(j['created_at'] as String).toLocal(),
      );
}
