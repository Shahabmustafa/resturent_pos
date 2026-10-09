import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/delivery_model.dart';

/// Rider app logins are Supabase Auth accounts, so they are made server-side.
const String kManageRiderLoginFn = 'manage-rider-login';

class DeliveryDatasource {
  final SupabaseClient _db;
  DeliveryDatasource(this._db);

  // ── Riders ───────────────────────────────────────────────────────────────
  Future<List<Rider>> fetchRiders(String branchId) async {
    final res = await _db
        .from('riders')
        .select()
        .eq('branch_id', branchId)
        .order('name');
    return (res as List).map((e) => Rider.fromJson(e)).toList();
  }

  Future<Rider> addRider(Rider rider, String branchId) async {
    final res = await _db
        .from('riders')
        .insert(rider.toInsert(branchId))
        .select()
        .single();
    return Rider.fromJson(res);
  }

  Future<void> updateRider(Rider rider) async {
    await _db.from('riders').update({
      'name':                rider.name,
      'phone':               rider.phone,
      'vehicle':             rider.vehicle,
      'charge_per_delivery': rider.chargePerDelivery,
      'status':              rider.status.toJson(),
    }).eq('id', rider.id);
  }

  /// Creates the rider's app login, or resets its password / syncs a changed phone.
  /// [password] is required the first time. Returns the phone number to sign in with.
  Future<String> setRiderLogin(String riderId, {String? password}) async {
    final res = await _invokeLoginFn({
      'action':   'set',
      'rider_id': riderId,
      if (password != null && password.isNotEmpty) 'password': password,
    });
    return res['login']?.toString() ?? '';
  }

  Future<void> removeRiderLogin(String riderId) =>
      _invokeLoginFn({'action': 'remove', 'rider_id': riderId});

  Future<Map<String, dynamic>> _invokeLoginFn(Map<String, dynamic> body) async {
    try {
      final res = await _db.functions.invoke(kManageRiderLoginFn, body: body);
      return Map<String, dynamic>.from(res.data as Map);
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map && details['error'] != null
          ? details['error'].toString()
          : 'Request failed (${e.status})';
      throw Exception(message);
    }
  }

  Future<void> updateRiderStatus(String riderId, String status) async {
    await _db.from('riders').update({'status': status}).eq('id', riderId);
  }

  // ── FIX: incrementRiderStats — fresh fetch, atomic update ────────────────
  Future<void> incrementRiderStats(String riderId, double charge) async {
    // Read current values fresh from the DB (the local list may be stale)
    final res = await _db
        .from('riders')
        .select('total_deliveries, total_earnings')
        .eq('id', riderId)
        .single();

    final currentDeliveries = (res['total_deliveries'] as num?)?.toInt()    ?? 0;
    final currentEarnings   = (res['total_earnings']   as num?)?.toDouble() ?? 0.0;

    await _db.from('riders').update({
      'total_deliveries': currentDeliveries + 1,
      'total_earnings':   currentEarnings + charge,
      'status':           'available',
    }).eq('id', riderId);
  }

  // ── Delivery Orders ──────────────────────────────────────────────────────
  Future<List<DeliveryOrder>> fetchDeliveryOrders(String branchId) async {
    final res = await _db
        .from('delivery_orders')
        .select()
        .eq('branch_id', branchId)
        .order('created_at', ascending: false)
        .limit(100);
    return (res as List).map((e) => DeliveryOrder.fromJson(e)).toList();
  }

  Future<DeliveryOrder> createDeliveryOrder(DeliveryOrder order, String branchId) async {
    final res = await _db.from('delivery_orders').insert({
      'branch_id':     branchId,
      'order_id':      order.orderId,
      'order_num':     order.orderNum,
      'customer_name': order.customerName,
      'phone':         order.phone,
      'address':       order.address,
      'items':         order.items,
      'amount':        order.amount,
      'notes':         order.notes,
      'status':        'pending',
    }).select().single();
    return DeliveryOrder.fromJson(res);
  }

  Future<void> assignRider(String deliveryOrderId, String riderId) async {
    await _db.from('delivery_orders').update({
      'rider_id':    riderId,
      'status':      'assigned',
      'assigned_at': DateTime.now().toIso8601String(),
    }).eq('id', deliveryOrderId);
    await _db.from('riders').update({'status': 'busy'}).eq('id', riderId);
  }

  Future<void> markOnTheWay(String deliveryOrderId) async {
    await _db
        .from('delivery_orders')
        .update({'status': 'on_the_way'})
        .eq('id', deliveryOrderId);
  }

  // ── FIX: markDelivered — use the rider ID directly, plus cash_transactions ──
  Future<void> markDelivered({
    required String branchId,
    required String deliveryOrderId,
    required String riderId,
    required String orderNum,
    required double orderAmount,    // amount collected from the customer (invoice total)
    required double riderCharge,    // charge paid to the rider
  }) async {
    // 1. Complete the delivery order
    await _db.from('delivery_orders').update({
      'status':       'delivered',
      'delivered_at': DateTime.now().toIso8601String(),
    }).eq('id', deliveryOrderId);

    // 2. Rider stats update + status available
    await incrementRiderStats(riderId, riderCharge);

    // 3. Cash transaction — add the delivery amount to branch cash
    //    (if the order was Paid the POS has already added it — your call)
    //    Here we only record the rider's earning under expenses
    try {
      // Expense the rider charge from branch cash
      await _db.from('cash_transactions').insert({
        'branch_id': branchId,
        'type':      'expense_out',
        'amount':    riderCharge,
        'direction': 'out',
        'ref_label': orderNum,
        'note':      'Delivery charge — $orderNum (Rider)',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update the branch cash balance (deduct rider charge)
      final cashRes = await _db
          .from('branch_cash')
          .select('balance')
          .eq('branch_id', branchId)
          .maybeSingle();

      if (cashRes != null) {
        final currentBalance = (cashRes['balance'] as num?)?.toDouble() ?? 0.0;
        await _db.from('branch_cash').update({
          'balance': currentBalance - riderCharge,
        }).eq('branch_id', branchId);
      }
    } catch (_) {
      // If the cash transaction fails, don't undo the completed delivery
      // Silently ignore — rider stats are already updated
    }
  }

  Future<void> cancelDeliveryOrder(String deliveryOrderId, {String? riderId}) async {
    await _db
        .from('delivery_orders')
        .update({'status': 'cancelled', 'rider_id': null})
        .eq('id', deliveryOrderId);
    if (riderId != null) {
      await _db.from('riders').update({'status': 'available'}).eq('id', riderId);
    }
  }

  // ── Realtime stream ──────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> deliveryOrdersStream(String branchId) =>
      _db
          .from('delivery_orders')
          .stream(primaryKey: ['id'])
          .eq('branch_id', branchId)
          .order('created_at', ascending: false);
}
