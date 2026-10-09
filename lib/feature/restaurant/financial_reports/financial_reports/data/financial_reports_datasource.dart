import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/financial_reports_models.dart';

class FinancialReportsDatasource {
  final SupabaseClient _client;
  FinancialReportsDatasource(this._client);

  // ─── Summary ──────────────────────────────────────────────────────────────
  Future<FinancialSummary> fetchSummary({
    required String branchId,
    required DateTime start,
    required DateTime end,
  }) async {
    final startIso = start.toUtc().toIso8601String();
    final endIso   = end.toUtc().toIso8601String();

    // FIX: use payment_status, not status
    // In the orders table:
    //   status         = 'pending' | 'completed' | 'cancelled'
    //   payment_status = 'Paid' | 'Unpaid' | 'Partial'
    // Revenue = total of orders where payment_status == 'Paid'
    final ordersRes = await _client
        .from('orders')
        .select('id, total, payment_method, payment_status, status, created_at')
        .eq('branch_id', branchId)
        .neq('status', 'cancelled')          // cancelled orders ignore
        .gte('created_at', startIso)
        .lte('created_at', endIso);

    final orders      = List<Map<String, dynamic>>.from(ordersRes as List);
    // FIX: capital-P 'Paid' — the POS stores 'Paid'/'Unpaid'/'Partial'
    final paidOrders  = orders.where((o) => o['payment_status'] == 'Paid').toList();
    final unpaidOrders = orders.where((o) =>
    o['payment_status'] == 'Unpaid' || o['payment_status'] == 'Partial').toList();

    final totalRevenue = paidOrders.fold<double>(
        0, (s, o) => s + ((o['total'] as num?)?.toDouble() ?? 0));

    // Payment method breakdown — Paid orders only
    final cashRev = paidOrders
        .where((o) => o['payment_method'] == 'Cash')
        .fold<double>(0, (s, o) => s + ((o['total'] as num?)?.toDouble() ?? 0));
    final cardRev = paidOrders
        .where((o) => o['payment_method'] == 'Card')
        .fold<double>(0, (s, o) => s + ((o['total'] as num?)?.toDouble() ?? 0));
    final onlineRev = paidOrders
        .where((o) => o['payment_method'] == 'Online')
        .fold<double>(0, (s, o) => s + ((o['total'] as num?)?.toDouble() ?? 0));

    // Cost of goods — items of ALL non-cancelled orders (paid + unpaid)
    final orderIds = orders.map((o) => o['id']).toList();
    double totalCost = 0;
    if (orderIds.isNotEmpty) {
      try {
        final itemsRes = await _client
            .from('order_items')
            .select('qty, unit_cost')
            .inFilter('order_id', orderIds);
        final items = List<Map<String, dynamic>>.from(itemsRes as List);
        totalCost = items.fold<double>(0, (s, i) =>
        s + ((i['qty'] as num?)?.toDouble() ?? 0) *
            ((i['unit_cost'] as num?)?.toDouble() ?? 0));
      } catch (_) {}
    }

    // Expenses — supplier_transactions (payment type)
    double totalExpenses = 0;
    try {
      final expRes = await _client
          .from('supplier_transactions')
          .select('amount')
          .eq('branch_id', branchId)
          .eq('type', 'payment')             // payment entries only
          .gte('created_at', startIso)
          .lte('created_at', endIso);
      final expenses = List<Map<String, dynamic>>.from(expRes as List);
      totalExpenses = expenses.fold<double>(
          0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));
    } catch (_) {}

    final grossProfit = totalRevenue - totalCost;
    final netProfit   = grossProfit - totalExpenses;

    return FinancialSummary(
      totalRevenue:      totalRevenue,
      totalCost:         totalCost,
      grossProfit:       grossProfit,
      totalExpenses:     totalExpenses,
      netProfit:         netProfit,
      totalOrders:       orders.length,
      paidOrders:        paidOrders.length,
      unpaidOrders:      unpaidOrders.length,
      cashRevenue:       cashRev,
      cardRevenue:       cardRev,
      onlineRevenue:     onlineRev,
      averageOrderValue: paidOrders.isEmpty ? 0 : totalRevenue / paidOrders.length,
    );
  }

  // ─── Product Report ───────────────────────────────────────────────────────
  Future<List<ProductReport>> fetchProductReports({
    required String branchId,
    required DateTime start,
    required DateTime end,
  }) async {
    final startIso = start.toUtc().toIso8601String();
    final endIso   = end.toUtc().toIso8601String();

    // FIX: orders where payment_status == 'Paid'
    final ordersRes = await _client
        .from('orders')
        .select('id')
        .eq('branch_id', branchId)
        .eq('payment_status', 'Paid')       // FIX: 'Paid' capital P
        .gte('created_at', startIso)
        .lte('created_at', endIso);

    final orderIds = (ordersRes as List).map((o) => o['id']).toList();
    if (orderIds.isEmpty) return [];

    final itemsRes = await _client
        .from('order_items')
        .select('menu_item_id, item_name, qty, unit_price, unit_cost')
        .inFilter('order_id', orderIds);

    final items = List<Map<String, dynamic>>.from(itemsRes as List);

    // Group by menu_item_id (or item_name for deals)
    final Map<String, Map<String, dynamic>> grouped = {};
    for (final item in items) {
      final key = item['menu_item_id']?.toString().isNotEmpty == true
          ? item['menu_item_id'].toString()
          : (item['item_name']?.toString() ?? 'unknown');

      if (!grouped.containsKey(key)) {
        grouped[key] = {
          'item_id':       key,
          'item_name':     item['item_name'] ?? 'Unknown',
          'category_name': '—',
          'quantity_sold': 0,
          'revenue':       0.0,
          'cost':          0.0,
          'profit':        0.0,
        };
      }
      final qty   = (item['qty']        as num?)?.toInt()    ?? 0;
      final price = (item['unit_price'] as num?)?.toDouble() ?? 0;
      final cost  = (item['unit_cost']  as num?)?.toDouble() ?? 0;

      grouped[key]!['quantity_sold'] = (grouped[key]!['quantity_sold'] as int) + qty;
      grouped[key]!['revenue']       = (grouped[key]!['revenue'] as double) + (qty * price);
      grouped[key]!['cost']          = (grouped[key]!['cost']    as double) + (qty * cost);
      grouped[key]!['profit']        = (grouped[key]!['revenue'] as double) - (grouped[key]!['cost'] as double);
    }

    // Category names fetch — FIX: join syntax
    try {
      final menuIds = grouped.keys
          .where((k) => k.length > 10 && !k.contains(' ')) // UUID-like keys
          .toList();
      if (menuIds.isNotEmpty) {
        final menuRes = await _client
            .from('menu_items')
            .select('id, category_id, categories!inner(name)')
            .inFilter('id', menuIds);
        for (final m in menuRes as List) {
          final id = m['id']?.toString() ?? '';
          if (grouped.containsKey(id)) {
            // FIX: the categories join result can be a List or a Map
            final cats = m['categories'];
            String catName = '—';
            if (cats is Map) {
              catName = cats['name']?.toString() ?? '—';
            } else if (cats is List && cats.isNotEmpty) {
              catName = cats.first['name']?.toString() ?? '—';
            }
            grouped[id]!['category_name'] = catName;
          }
        }
      }
    } catch (_) {}

    // Sort by revenue descending
    final list = grouped.values.map(ProductReport.fromMap).toList();
    list.sort((a, b) => b.revenue.compareTo(a.revenue));
    return list;
  }

  // ─── Daily Sales ──────────────────────────────────────────────────────────
  Future<List<DailySales>> fetchDailySales({
    required String branchId,
    required DateTime start,
    required DateTime end,
  }) async {
    // FIX: payment_status == 'Paid'
    final res = await _client
        .from('orders')
        .select('created_at, total')
        .eq('branch_id', branchId)
        .eq('payment_status', 'Paid')       // FIX
        .neq('status', 'cancelled')
        .gte('created_at', start.toUtc().toIso8601String())
        .lte('created_at', end.toUtc().toIso8601String())
        .order('created_at');

    final orders = List<Map<String, dynamic>>.from(res as List);
    final Map<String, Map<String, dynamic>> daily = {};

    for (final o in orders) {
      final date = DateTime.parse(o['created_at'].toString()).toLocal();
      final key  = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (!daily.containsKey(key)) {
        daily[key] = {'date': key, 'revenue': 0.0, 'orders': 0};
      }
      daily[key]!['revenue'] = (daily[key]!['revenue'] as double) +
          ((o['total'] as num?)?.toDouble() ?? 0);
      daily[key]!['orders'] = (daily[key]!['orders'] as int) + 1;
    }

    return daily.values.map(DailySales.fromMap).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // ─── Expense Report ───────────────────────────────────────────────────────
  Future<List<ExpenseReport>> fetchExpenseReports({
    required String branchId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      // FIX: filter supplier_transactions by branch_id + type = 'payment'
      final res = await _client
          .from('supplier_transactions')
          .select('amount, supplier_id, suppliers(name)')
          .eq('branch_id', branchId)
          .eq('type', 'payment')
          .gte('created_at', start.toUtc().toIso8601String())
          .lte('created_at', end.toUtc().toIso8601String());

      final transactions = List<Map<String, dynamic>>.from(res as List);
      final Map<String, Map<String, dynamic>> grouped = {};

      for (final t in transactions) {
        // FIX: suppliers join — List or Map
        final suppliersData = t['suppliers'];
        String category = 'Other';
        if (suppliersData is Map) {
          category = suppliersData['name']?.toString() ?? 'Other';
        } else if (suppliersData is List && suppliersData.isNotEmpty) {
          category = suppliersData.first['name']?.toString() ?? 'Other';
        }

        if (!grouped.containsKey(category)) {
          grouped[category] = {'category': category, 'amount': 0.0, 'count': 0};
        }
        grouped[category]!['amount'] = (grouped[category]!['amount'] as double) +
            ((t['amount'] as num?)?.toDouble() ?? 0);
        grouped[category]!['count'] = (grouped[category]!['count'] as int) + 1;
      }

      return grouped.values.map(ExpenseReport.fromMap).toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
    } catch (_) {
      return [];
    }
  }
}