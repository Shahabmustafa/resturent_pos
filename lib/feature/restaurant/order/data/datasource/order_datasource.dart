import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../pos_and_order/data/model/order_model.dart';

class OrderRemoteDatasource {
  final SupabaseClient _db;
  const OrderRemoteDatasource(this._db);

  Future<List<OrderModel>> fetchOrders({
    required String branchId,
    String? status,
    String? orderType,
    String? paymentStatus,
    DateTime? from,
    DateTime? to,
    String? search,
    int limit = 100,
  }) async {
    var query = _db
        .from('orders')
        .select('*, order_items(*)')
        .eq('branch_id', branchId);

    if (status != null && status != 'All')
      query = query.eq('status', status);
    if (orderType != null && orderType != 'All')
      query = query.eq('order_type', orderType);
    if (paymentStatus != null && paymentStatus != 'All')
      query = query.eq('payment_status', paymentStatus);
    if (from != null)
      query = query.gte('created_at', from.toIso8601String());
    if (to != null)
      query = query.lte('created_at',
          to.add(const Duration(days: 1)).toIso8601String());

    final res =
    await query.order('created_at', ascending: false).limit(limit);

    var orders = (res as List)
        .map((e) => OrderModel.fromJson(e,
        items: ((e['order_items'] as List? ?? [])
            .map((i) => OrderItemModel.fromJson(i))
            .toList())))
        .toList();

    if (search != null && search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      orders = orders
          .where((o) =>
      o.orderNumber.toLowerCase().contains(q) ||
          o.customerName.toLowerCase().contains(q) ||
          o.customerPhone.toLowerCase().contains(q) ||
          o.tableNumber.toLowerCase().contains(q))
          .toList();
    }

    return orders;
  }

  Future<OrderModel> fetchOrderById(String orderId) async {
    final res = await _db
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', orderId)
        .single();
    return OrderModel.fromJson(res,
        items: ((res['order_items'] as List? ?? [])
            .map((i) => OrderItemModel.fromJson(i))
            .toList()));
  }

  Future<void> updateStatus(String orderId, String status) async =>
      _db.from('orders').update({'status': status}).eq('id', orderId);

  Future<void> updatePaymentStatus(String orderId, String paymentStatus) async =>
      _db.from('orders').update({'payment_status': paymentStatus}).eq('id', orderId);

  // FIX: freeTable now part of order datasource as well
  // (called by order_provider when payment marked Paid or order cancelled)
  Future<void> freeTable(String branchId, String tableNumber, {String status = 'cleaning'}) async => _db.from('tables').update({'status': status}).eq('branch_id', branchId).eq('table_number', tableNumber);

  Future<Map<String, dynamic>> fetchSummary({
    required String branchId,
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _db.from('orders').select('total, payment_status, status').eq('branch_id', branchId).neq('status', 'cancelled');

    if (from != null)
      query = query.gte('created_at', from.toIso8601String());
    if (to != null)
      query = query.lte('created_at', to.add(const Duration(days: 1)).toIso8601String());

    final res  = await query;
    final list = res as List;

    double totalRevenue = 0, totalPaid = 0;
    int pending = 0, completed = 0;

    for (final r in list) {
      final t = (r['total'] as num).toDouble();
      totalRevenue += t;
      if (r['payment_status'] == 'Paid') totalPaid += t;
      if (r['status'] == 'pending')      pending++;
      if (r['status'] == 'completed')    completed++;
    }

    return {
      'total_orders':    list.length,
      'total_revenue':   totalRevenue,
      'total_paid':      totalPaid,
      'pending_count':   pending,
      'completed_count': completed,
    };
  }

  /// Calls [onChange] for every insert/update/delete on the branch's orders,
  /// and [onSubscribed] each time the channel (re)connects so callers can catch
  /// up on anything missed. Pass the returned channel to [unsubscribe] when done.
  RealtimeChannel subscribeToOrders(
    String branchId,
    String name,
    void Function(PostgresChangePayload payload) onChange, {
    void Function()? onSubscribed,
  }) {
    // Unique topic: a provider rebuild subscribes again before the old channel
    // has left, and two joins on one topic make the server drop one of them.
    final topic = 'orders-$name-$branchId-${DateTime.now().microsecondsSinceEpoch}';
    return _db
        .channel(topic)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'branch_id',
            value: branchId,
          ),
          callback: onChange,
        )
        .subscribe((status, error) {
          debugPrint('Realtime [$topic]: $status${error != null ? ' — $error' : ''}');
          if (status == RealtimeSubscribeStatus.subscribed) onSubscribed?.call();
        });
  }

  Future<void> unsubscribe(RealtimeChannel channel) => _db.removeChannel(channel);

  Stream<List<Map<String, dynamic>>> ordersStream(String branchId) => _db.from('orders').stream(primaryKey: ['id']).eq('branch_id', branchId).order('created_at', ascending: false);
}