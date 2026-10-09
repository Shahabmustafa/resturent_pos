import 'package:supabase_flutter/supabase_flutter.dart';

double _d(Object? v) => v == null ? 0 : double.tryParse('$v') ?? 0;
int _i(Object? v) => _d(v).round();
DateTime _t(Object? v) => DateTime.parse(v as String).toLocal();

/// Everything the dashboard shows for one period, from `dashboard_stats()`.
class DashboardStats {
  final double revenue, avgOrder, discounts, unpaidAmount;
  final int paidOrders, itemsSold, ordersPlaced, cancelled;
  final double prevRevenue, prevAvgOrder;
  final int prevPaidOrders;
  final bool hourly; // trend buckets are hours (single day) or days
  final List<TrendPoint> trend;
  final List<HourPoint> hours;
  final double cash, card, online;
  final List<TypeRow> byType;
  final int websiteOrders, posOrders;
  final double websiteRevenue, posRevenue;
  final List<TopItem> topItems;
  final List<TopCustomer> topCustomers;
  final LiveStatus live;

  const DashboardStats({
    required this.revenue,
    required this.avgOrder,
    required this.discounts,
    required this.unpaidAmount,
    required this.paidOrders,
    required this.itemsSold,
    required this.ordersPlaced,
    required this.cancelled,
    required this.prevRevenue,
    required this.prevAvgOrder,
    required this.prevPaidOrders,
    required this.hourly,
    required this.trend,
    required this.hours,
    required this.cash,
    required this.card,
    required this.online,
    required this.byType,
    required this.websiteOrders,
    required this.posOrders,
    required this.websiteRevenue,
    required this.posRevenue,
    required this.topItems,
    required this.topCustomers,
    required this.live,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) {
    final cur = Map<String, dynamic>.from(j['current'] as Map);
    final prev = Map<String, dynamic>.from(j['previous'] as Map);
    final method = Map<String, dynamic>.from(j['by_method'] as Map);
    final channel = Map<String, dynamic>.from(j['channel'] as Map);
    List<Map<String, dynamic>> list(String k) =>
        [for (final e in (j[k] as List? ?? const [])) Map<String, dynamic>.from(e as Map)];
    return DashboardStats(
      revenue:        _d(cur['revenue']),
      avgOrder:       _d(cur['avg_order']),
      discounts:      _d(cur['discounts']),
      unpaidAmount:   _d(cur['unpaid_amount']),
      paidOrders:     _i(cur['paid_orders']),
      itemsSold:      _i(cur['items_sold']),
      ordersPlaced:   _i(cur['orders_placed']),
      cancelled:      _i(cur['cancelled']),
      prevRevenue:    _d(prev['revenue']),
      prevAvgOrder:   _d(prev['avg_order']),
      prevPaidOrders: _i(prev['paid_orders']),
      hourly:         j['bucket'] == 'hour',
      // Bucket times are already local wall-clock times (shifted by the offset).
      trend: [
        for (final e in list('trend'))
          TrendPoint(DateTime.parse((e['t'] as String).substring(0, 19)), _d(e['cur']), _d(e['prev'])),
      ],
      hours: [for (final e in list('hours')) HourPoint(_i(e['h']), _d(e['revenue']), _i(e['orders']))],
      cash:   _d(method['cash']),
      card:   _d(method['card']),
      online: _d(method['online']),
      byType: [for (final e in list('by_type')) TypeRow('${e['type']}', _i(e['orders']), _d(e['revenue']))],
      websiteOrders:  _i(channel['website_orders']),
      posOrders:      _i(channel['pos_orders']),
      websiteRevenue: _d(channel['website_revenue']),
      posRevenue:     _d(channel['pos_revenue']),
      topItems: [for (final e in list('top_items')) TopItem('${e['name']}', _i(e['qty']), _d(e['revenue']))],
      topCustomers: [
        for (final e in list('top_customers'))
          TopCustomer('${e['name']}', '${e['phone'] ?? ''}', _i(e['orders']), _d(e['spent'])),
      ],
      live: LiveStatus.fromJson(Map<String, dynamic>.from(j['live'] as Map)),
    );
  }
}

class TrendPoint {
  final DateTime at;
  final double current, previous;
  const TrendPoint(this.at, this.current, this.previous);
}

class HourPoint {
  final int hour;
  final double revenue;
  final int orders;
  const HourPoint(this.hour, this.revenue, this.orders);
}

class TypeRow {
  final String type;
  final int orders;
  final double revenue;
  const TypeRow(this.type, this.orders, this.revenue);
}

class TopItem {
  final String name;
  final int qty;
  final double revenue;
  const TopItem(this.name, this.qty, this.revenue);
}

class TopCustomer {
  final String name, phone;
  final int orders;
  final double spent;
  const TopCustomer(this.name, this.phone, this.orders, this.spent);
}

class RecentOrder {
  final String number, customer, customerType, type, status, paymentStatus;
  final double total;
  final DateTime createdAt;
  const RecentOrder(this.number, this.customer, this.customerType, this.type, this.status, this.paymentStatus,
      this.total, this.createdAt);
}

class LiveStatus {
  final int pendingOrders, activeDeliveries;
  final DateTime? counterOpenedAt;
  final String counterOpenedBy;
  final double counterExpectedCash;
  final List<RecentOrder> recent;

  const LiveStatus({
    required this.pendingOrders,
    required this.activeDeliveries,
    required this.counterOpenedAt,
    required this.counterOpenedBy,
    required this.counterExpectedCash,
    required this.recent,
  });

  bool get counterOpen => counterOpenedAt != null;

  factory LiveStatus.fromJson(Map<String, dynamic> j) {
    final counter = j['counter'] == null ? null : Map<String, dynamic>.from(j['counter'] as Map);
    return LiveStatus(
      pendingOrders:       _i(j['pending_orders']),
      activeDeliveries:    _i(j['active_deliveries']),
      counterOpenedAt:     counter == null ? null : _t(counter['opened_at']),
      counterOpenedBy:     counter == null ? '' : '${counter['opened_by'] ?? ''}',
      counterExpectedCash: counter == null ? 0 : _d(counter['expected_cash']),
      recent: [
        for (final e in (j['recent'] as List? ?? const []))
          RecentOrder(
            '${e['order_number'] ?? ''}',
            '${e['customer_name'] ?? ''}',
            '${e['customer_type'] ?? ''}',
            '${e['order_type'] ?? ''}',
            '${e['status'] ?? ''}',
            '${e['payment_status'] ?? ''}',
            _d(e['total']),
            _t(e['created_at']),
          ),
      ],
    );
  }
}

class DashboardDatasource {
  final SupabaseClient _db;
  const DashboardDatasource(this._db);

  Future<DashboardStats> fetch(String branchId, DateTime from, DateTime to) async {
    final res = await _db.rpc('dashboard_stats', params: {
      'p_branch_id': branchId,
      'p_from': from.toUtc().toIso8601String(),
      'p_to': to.toUtc().toIso8601String(),
      'p_utc_offset_min': DateTime.now().timeZoneOffset.inMinutes,
    });
    return DashboardStats.fromJson(Map<String, dynamic>.from(res as Map));
  }
}
