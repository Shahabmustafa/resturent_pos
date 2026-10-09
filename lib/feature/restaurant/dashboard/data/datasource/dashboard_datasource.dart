// lib/features/dashboard/datasource/dashboard_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardDatasource {
  final _db = Supabase.instance.client;

  // ─── KPI: Today's Revenue, Orders, Customers, Avg Order ───
  Future<Map<String, dynamic>> fetchTodayKpis(String branchId) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).toIso8601String();
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

    final orders = await _db
        .from('orders')
        .select('total, customer_name, payment_status')
        .eq('branch_id', branchId)
        .gte('created_at', start)
        .lte('created_at', end);

    final totalRevenue = orders.fold<double>(0, (sum, o) => sum + (o['total'] ?? 0));
    final totalOrders = orders.length;
    final uniqueCustomers = orders
        .map((o) => o['customer_name'] ?? '')
        .where((n) => n.toString().isNotEmpty)
        .toSet()
        .length;
    final avgOrder = totalOrders > 0 ? totalRevenue / totalOrders : 0;

    return {
      'revenue': totalRevenue,
      'orders': totalOrders,
      'customers': uniqueCustomers,
      'avg_order': avgOrder,
    };
  }

  // ─── Revenue: This Week vs Last Week (by day) ───
  Future<Map<String, List<double>>> fetchWeeklyRevenue(String branchId) async {
    final now = DateTime.now();
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));
    final lastMonday = thisMonday.subtract(const Duration(days: 7));

    final thisWeekStart = DateTime(thisMonday.year, thisMonday.month, thisMonday.day).toIso8601String();
    final lastWeekStart = DateTime(lastMonday.year, lastMonday.month, lastMonday.day).toIso8601String();
    final lastWeekEnd = DateTime(thisMonday.year, thisMonday.month, thisMonday.day)
        .subtract(const Duration(seconds: 1))
        .toIso8601String();

    final thisWeekOrders = await _db
        .from('orders')
        .select('total, created_at')
        .eq('branch_id', branchId)
        .gte('created_at', thisWeekStart);

    final lastWeekOrders = await _db
        .from('orders')
        .select('total, created_at')
        .eq('branch_id', branchId)
        .gte('created_at', lastWeekStart)
        .lte('created_at', lastWeekEnd);

    List<double> groupByDay(List orders) {
      final days = List<double>.filled(7, 0);
      for (final o in orders) {
        final dt = DateTime.parse(o['created_at']).toLocal();
        final day = dt.weekday - 1; // 0=Mon ... 6=Sun
        if (day >= 0 && day < 7) days[day] += (o['total'] ?? 0);
      }
      return days;
    }

    return {
      'this_week': groupByDay(thisWeekOrders),
      'last_week': groupByDay(lastWeekOrders),
    };
  }

  // ─── Order Type Donut: Dine-in / Takeaway / Delivery ───
  Future<Map<String, int>> fetchOrderTypeCounts(String branchId) async {
    final orders = await _db
        .from('orders')
        .select('order_type')
        .eq('branch_id', branchId);

    final Map<String, int> counts = {'Dine-in': 0, 'Takeaway': 0, 'Delivery': 0};
    for (final o in orders) {
      final type = o['order_type'] ?? '';
      if (counts.containsKey(type)) counts[type] = counts[type]! + 1;
    }
    return counts;
  }

  // ─── Recent Orders (last 5) ───
  Future<List<Map<String, dynamic>>> fetchRecentOrders(String branchId) async {
    final data = await _db
        .from('orders')
        .select('order_number, customer_name, order_type, total, payment_status, table_number, created_at')
        .eq('branch_id', branchId)
        .order('created_at', ascending: false)
        .limit(5);

    return List<Map<String, dynamic>>.from(data);
  }

  // ─── Top Selling Items ───
  Future<List<Map<String, dynamic>>> fetchTopSellingItems(String branchId) async {
    final data = await _db
        .from('order_items')
        .select('item_name, total_price, qty')
        .eq('branch_id', branchId);

    final Map<String, Map<String, dynamic>> grouped = {};
    for (final item in data) {
      final name = item['item_name'] as String;
      final cleanName = name.contains('(') ? name.substring(0, name.indexOf('(')).trim() : name;
      if (!grouped.containsKey(cleanName)) {
        grouped[cleanName] = {'name': cleanName, 'revenue': 0.0, 'qty': 0};
      }
      grouped[cleanName]!['revenue'] += (item['total_price'] ?? 0);
      grouped[cleanName]!['qty'] += (item['qty'] ?? 0);
    }

    final sorted = grouped.values.toList()
      ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

    final top5 = sorted.take(5).toList();
    final maxRevenue = top5.isNotEmpty ? (top5.first['revenue'] as double) : 1.0;

    for (final item in top5) {
      item['ratio'] = (item['revenue'] as double) / maxRevenue;
    }

    return top5;
  }

  // ─── Low Stock Items ───
  Future<List<Map<String, dynamic>>> fetchLowStockItems(String branchId) async {
    // Supabase doesn't support column-to-column comparison,
    // so fetch everything and filter in Dart
    final all = await _db
        .from('stock_items')
        .select('name, qty, min_qty, unit')
        .eq('branch_id', branchId);

    return all
        .where((item) {
      final qty    = (item['qty']     as num?)?.toDouble() ?? 0.0;
      final minQty = (item['min_qty'] as num?)?.toDouble() ?? 0.0;
      return qty <= minQty;
    })
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ─── Mini Stats ───
  Future<Map<String, dynamic>> fetchMiniStats(String branchId) async {
    // Tables
    final tables = await _db
        .from('tables')
        .select('status')
        .eq('branch_id', branchId)
        .eq('is_active', true);

    final totalTables = tables.length;
    final occupiedTables = tables.where((t) => t['status'] == 'reserved').length;

    // Kitchen (pending/preparing orders)
    final kitchenOrders = await _db
        .from('orders')
        .select('id')
        .eq('branch_id', branchId)
        .inFilter('status', ['pending', 'preparing']);

    // Active deliveries
    final deliveries = await _db
        .from('delivery_orders')
        .select('id')
        .eq('branch_id', branchId)
        .inFilter('status', ['assigned', 'on_the_way']);

    // Cash balance (branch_cash singleton row per branch)
    double cashBalance = 0;
    try {
      final cash = await _db
          .from('branch_cash')
          .select('balance')
          .eq('branch_id', branchId)
          .maybeSingle();
      cashBalance = (cash?['balance'] as num?)?.toDouble() ?? 0;
    } catch (_) {
      cashBalance = 0;
    }

    return {
      'tables_occupied': occupiedTables,
      'tables_total': totalTables,
      'kitchen_orders': kitchenOrders.length,
      'active_deliveries': deliveries.length,
      'cash_balance': cashBalance,
    };
  }
}