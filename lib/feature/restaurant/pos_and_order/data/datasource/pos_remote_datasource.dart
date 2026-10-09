import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/order_model.dart';

class PosRemoteDatasource {
  final SupabaseClient _db;
  const PosRemoteDatasource(this._db);

  Future<List<MenuProduct>> fetchMenuItems(String branchId) async {
    final res = await _db
        .from('menu_items')
        .select('*, menu_item_sizes(*)')
        .eq('branch_id', branchId)
        .eq('is_available', true)
        .order('created_at', ascending: true); // printed-menu order
    return (res as List).map((e) {
      final sizes = ((e['menu_item_sizes'] as List? ?? []).map((s) => ProductSize.fromJson(s)).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));
      return MenuProduct.fromMenuItemJson(e, sizes: sizes);
    }).toList();
  }

  Future<List<MenuProduct>> fetchDeals(String branchId) async {
    final res = await _db
        .from('deals')
        .select('*, deal_sizes(*)')
        .eq('branch_id', branchId)
        .eq('is_available', true)
        .order('name');
    return (res as List).map((e) {
      final sizes = ((e['deal_sizes'] as List? ?? []).map((s) => ProductSize.fromJson(s)).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));
      return MenuProduct.fromDealJson(e, sizes: sizes);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> fetchCategories(String branchId) async =>
      ((await _db.from('categories').select().eq('branch_id', branchId).order('created_at', ascending: true)) as List)
          .cast();

  Future<List<PosTableModel>> fetchAvailableTables(String branchId) async =>
      ((await _db
                  .from('tables')
                  .select()
                  .eq('branch_id', branchId)
                  .eq('is_active', true)
                  .eq('status', 'available')
                  .order('table_number'))
              as List)
          .map((e) => PosTableModel.fromJson(e))
          .toList();

  Future<List<PosCustomerModel>> fetchCustomers(String branchId) async =>
      ((await _db.from('customers').select().eq('branch_id', branchId).order('name')) as List)
          .map((e) => PosCustomerModel.fromJson(e))
          .toList();

  /// Saves a walk-in as a regular customer and returns the new record.
  Future<PosCustomerModel> addCustomer(String branchId, String name, String phone) async => PosCustomerModel.fromJson(
    await _db
        .from('customers')
        .insert({
          'branch_id': branchId,
          'name': name,
          'phone': phone,
          'type': 'walk_in',
          'orders': 0,
          'spent': 0,
          'balance': 0,
          'loyalty': 'regular',
          'discount': 0,
        })
        .select()
        .single(),
  );

  // ── Riders fetch (available only) ─────────────────────────────────────────
  Future<List<PosRiderModel>> fetchAvailableRiders(String branchId) async =>
      ((await _db.from('riders').select().eq('branch_id', branchId).eq('status', 'available').order('name')) as List)
          .map((e) => PosRiderModel.fromJson(e))
          .toList();

  Future<String> _nextOrderNumber(String branchId) async {
    final res = await _db
        .from('orders')
        .select('order_number')
        .eq('branch_id', branchId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return '#${(int.tryParse(res?['order_number']?.toString().replaceAll('#', '') ?? '1000') ?? 1000) + 1}';
  }

  Future<OrderModel> placeOrder({
    required String branchId,
    required String orderType,
    required String customerType,
    required String customerName,
    required String customerPhone,
    required String tableNumber,
    required String paymentMethod,
    required String paymentStatus,
    required double subtotal,
    required double discountPct,
    required double discountFlat,
    required double discountAmt,
    required double taxAmt,
    required double total,
    required String notes,
    required List<Map<String, dynamic>> items,
    String? customerId,
    String? deliveryAddress,
    String? riderId, // ── NEW
    String? riderName, // ── NEW (for delivery_orders record)
  }) async {
    final orderNumber = await _nextOrderNumber(branchId);

    final orderRes = await _db
        .from('orders')
        .insert({
          'branch_id': branchId,
          'order_number': orderNumber,
          'order_type': orderType,
          'customer_type': customerType,
          'customer_id': customerId,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'table_number': tableNumber,
          'status': 'pending',
          'payment_method': paymentMethod,
          'payment_status': paymentStatus,
          'subtotal': subtotal,
          'discount_pct': discountPct,
          'discount_flat': discountFlat,
          'discount_amt': discountAmt,
          'tax_pct': 5.0,
          'tax_amt': taxAmt,
          'total': total,
          'notes': notes,
        })
        .select()
        .single();

    final orderId = orderRes['id'] as String;

    // Dine-in → table reserve
    if (orderType == 'Dine-in' && tableNumber.isNotEmpty) {
      await _db.from('tables').update({'status': 'reserved'}).eq('branch_id', branchId).eq('table_number', tableNumber);
    }

    final itemsRes = await _db
        .from('order_items')
        .insert(items.map((i) => {...i, 'order_id': orderId, 'branch_id': branchId}).toList())
        .select();

    // ── Delivery order auto-create + rider assign ──────────────────────────
    if (orderType == 'Delivery') {
      final itemsSummary = items.map((i) => '${i['item_name']} × ${i['qty']}').join(', ');

      await _db.from('delivery_orders').insert({
        'branch_id': branchId,
        'order_id': orderId,
        'order_num': orderNumber,
        'customer_name': customerName.isNotEmpty ? customerName : 'Walk-in',
        'phone': customerPhone,
        'address': deliveryAddress ?? '',
        'items': itemsSummary,
        'amount': total,
        'notes': notes,
        // Rider already assigned from POS
        'rider_id': riderId,
        'status': riderId != null ? 'assigned' : 'pending',
        'assigned_at': riderId != null ? DateTime.now().toIso8601String() : null,
      });

      // Mark rider as busy immediately
      if (riderId != null) {
        await _db.from('riders').update({'status': 'busy'}).eq('id', riderId);
      }
    }

    return OrderModel.fromJson(orderRes, items: (itemsRes as List).map((e) => OrderItemModel.fromJson(e)).toList());
  }

  Future<List<OrderModel>> fetchOrders(String branchId, {int limit = 50}) async {
    final res = await _db
        .from('orders')
        .select('*, order_items(*)')
        .eq('branch_id', branchId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (res as List)
        .map(
          (e) => OrderModel.fromJson(
            e,
            items: ((e['order_items'] as List? ?? []).map((i) => OrderItemModel.fromJson(i)).toList()),
          ),
        )
        .toList();
  }

  Future<void> updateStatus(String orderId, String status) =>
      _db.from('orders').update({'status': status}).eq('id', orderId);

  Future<void> freeTable(String branchId, String tableNumber) =>
      _db.from('tables').update({'status': 'available'}).eq('branch_id', branchId).eq('table_number', tableNumber);

  Future<void> cancelOrder(String orderId) => _db.from('orders').update({'status': 'cancelled'}).eq('id', orderId);

  Future<void> updatePaymentStatus(String orderId, String paymentStatus) =>
      _db.from('orders').update({'payment_status': paymentStatus}).eq('id', orderId);

  Stream<List<Map<String, dynamic>>> ordersStream(String branchId) =>
      _db.from('orders').stream(primaryKey: ['id']).eq('branch_id', branchId).order('created_at', ascending: false);
}
