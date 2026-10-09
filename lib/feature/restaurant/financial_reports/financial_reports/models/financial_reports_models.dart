// ─── Date Filter Enum ───────────────────────────────────────────────────────
enum DateFilter { today, yesterday, thisWeek, thisMonth, lastMonth, custom }

extension DateFilterLabel on DateFilter {
  String get label {
    switch (this) {
      case DateFilter.today: return 'Today';
      case DateFilter.yesterday: return 'Yesterday';
      case DateFilter.thisWeek: return 'This Week';
      case DateFilter.thisMonth: return 'This Month';
      case DateFilter.lastMonth: return 'Last Month';
      case DateFilter.custom: return 'Custom Range';
    }
  }

  (DateTime, DateTime) get range {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    switch (this) {
      case DateFilter.today:
        return (todayStart, now);
      case DateFilter.yesterday:
        final y = todayStart.subtract(const Duration(days: 1));
        return (y, todayStart.subtract(const Duration(seconds: 1)));
      case DateFilter.thisWeek:
        final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
        return (weekStart, now);
      case DateFilter.thisMonth:
        return (DateTime(now.year, now.month, 1), now);
      case DateFilter.lastMonth:
        final lmStart = DateTime(now.year, now.month - 1, 1);
        final lmEnd = DateTime(now.year, now.month, 1).subtract(const Duration(seconds: 1));
        return (lmStart, lmEnd);
      case DateFilter.custom:
        return (todayStart, now);
    }
  }
}

// ─── Summary Card Model ──────────────────────────────────────────────────────
class FinancialSummary {
  final double totalRevenue;
  final double totalCost;
  final double grossProfit;
  final double totalExpenses;
  final double netProfit;
  final int totalOrders;
  final int paidOrders;
  final int unpaidOrders;
  final double cashRevenue;
  final double cardRevenue;
  final double onlineRevenue;
  final double averageOrderValue;

  const FinancialSummary({
    required this.totalRevenue,
    required this.totalCost,
    required this.grossProfit,
    required this.totalExpenses,
    required this.netProfit,
    required this.totalOrders,
    required this.paidOrders,
    required this.unpaidOrders,
    required this.cashRevenue,
    required this.cardRevenue,
    required this.onlineRevenue,
    required this.averageOrderValue,
  });

  double get grossMargin => totalRevenue == 0 ? 0 : (grossProfit / totalRevenue) * 100;
  double get netMargin => totalRevenue == 0 ? 0 : (netProfit / totalRevenue) * 100;

  factory FinancialSummary.empty() => const FinancialSummary(
        totalRevenue: 0, totalCost: 0, grossProfit: 0,
        totalExpenses: 0, netProfit: 0, totalOrders: 0,
        paidOrders: 0, unpaidOrders: 0, cashRevenue: 0,
        cardRevenue: 0, onlineRevenue: 0, averageOrderValue: 0,
      );
}

// ─── Product Report Model ────────────────────────────────────────────────────
class ProductReport {
  final String itemId;
  final String itemName;
  final String categoryName;
  final int quantitySold;
  final double revenue;
  final double cost;
  final double profit;

  const ProductReport({
    required this.itemId,
    required this.itemName,
    required this.categoryName,
    required this.quantitySold,
    required this.revenue,
    required this.cost,
    required this.profit,
  });

  double get margin => revenue == 0 ? 0 : (profit / revenue) * 100;

  factory ProductReport.fromMap(Map<String, dynamic> m) => ProductReport(
        itemId: m['item_id']?.toString() ?? '',
        itemName: m['item_name']?.toString() ?? 'Unknown',
        categoryName: m['category_name']?.toString() ?? '—',
        quantitySold: (m['quantity_sold'] as num?)?.toInt() ?? 0,
        revenue: (m['revenue'] as num?)?.toDouble() ?? 0,
        cost: (m['cost'] as num?)?.toDouble() ?? 0,
        profit: (m['profit'] as num?)?.toDouble() ?? 0,
      );
}

// ─── Daily Sales Model ───────────────────────────────────────────────────────
class DailySales {
  final DateTime date;
  final double revenue;
  final int orders;

  const DailySales({required this.date, required this.revenue, required this.orders});

  factory DailySales.fromMap(Map<String, dynamic> m) => DailySales(
        date: DateTime.parse(m['date'].toString()),
        revenue: (m['revenue'] as num?)?.toDouble() ?? 0,
        orders: (m['orders'] as num?)?.toInt() ?? 0,
      );
}

// ─── Expense Model ───────────────────────────────────────────────────────────
class ExpenseReport {
  final String category;
  final double amount;
  final int count;

  const ExpenseReport({required this.category, required this.amount, required this.count});

  factory ExpenseReport.fromMap(Map<String, dynamic> m) => ExpenseReport(
        category: m['category']?.toString() ?? 'Other',
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        count: (m['count'] as num?)?.toInt() ?? 0,
      );
}

// ─── Payment Breakdown ───────────────────────────────────────────────────────
class PaymentBreakdown {
  final String method;
  final double amount;
  final int count;

  const PaymentBreakdown({required this.method, required this.amount, required this.count});
}

// ─── Full State ──────────────────────────────────────────────────────────────
class FinancialReportsState {
  final bool isLoading;
  final String? error;
  final FinancialSummary summary;
  final List<ProductReport> productReports;
  final List<DailySales> dailySales;
  final List<ExpenseReport> expenseReports;
  final DateFilter selectedFilter;
  final DateTime startDate;
  final DateTime endDate;
  final String sortProductBy; // 'revenue' | 'quantity' | 'profit'

  const FinancialReportsState({
    this.isLoading = false,
    this.error,
    this.summary = const FinancialSummary(
      totalRevenue: 0, totalCost: 0, grossProfit: 0,
      totalExpenses: 0, netProfit: 0, totalOrders: 0,
      paidOrders: 0, unpaidOrders: 0, cashRevenue: 0,
      cardRevenue: 0, onlineRevenue: 0, averageOrderValue: 0,
    ),
    this.productReports = const [],
    this.dailySales = const [],
    this.expenseReports = const [],
    this.selectedFilter = DateFilter.today,
    required this.startDate,
    required this.endDate,
    this.sortProductBy = 'revenue',
  });

  FinancialReportsState copyWith({
    bool? isLoading, String? error, FinancialSummary? summary,
    List<ProductReport>? productReports, List<DailySales>? dailySales,
    List<ExpenseReport>? expenseReports, DateFilter? selectedFilter,
    DateTime? startDate, DateTime? endDate, String? sortProductBy,
    bool clearError = false,
  }) => FinancialReportsState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        summary: summary ?? this.summary,
        productReports: productReports ?? this.productReports,
        dailySales: dailySales ?? this.dailySales,
        expenseReports: expenseReports ?? this.expenseReports,
        selectedFilter: selectedFilter ?? this.selectedFilter,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        sortProductBy: sortProductBy ?? this.sortProductBy,
      );
}
