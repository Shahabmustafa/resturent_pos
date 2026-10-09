import 'dart:ui';

class OrderModel {
  final String  id;
  final String  branchId;
  final String  orderNumber;
  final String  orderType;
  final String  customerType;
  final String? customerId;
  final String  customerName;
  final String  customerPhone;
  final String  tableNumber;
  final String  status;
  final String  paymentMethod;
  final String  paymentStatus;
  final double  subtotal;
  final double  discountPct;
  final double  discountFlat;
  final double  discountAmt;
  final double  taxPct;
  final double  taxAmt;
  final double  total;
  final String  notes;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.branchId,
    required this.orderNumber,
    required this.orderType,
    required this.customerType,
    this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.tableNumber,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotal,
    required this.discountPct,
    required this.discountFlat,
    required this.discountAmt,
    required this.taxPct,
    required this.taxAmt,
    required this.total,
    required this.notes,
    required this.createdAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> j, {List<OrderItemModel>? items}) =>
      OrderModel(
        id:            j['id'],
        branchId:      j['branch_id'],
        orderNumber:   j['order_number'],
        orderType:     j['order_type']      ?? 'Dine-in',
        customerType:  j['customer_type']   ?? 'Walk-in',
        customerId:    j['customer_id'],
        customerName:  j['customer_name']   ?? '',
        customerPhone: j['customer_phone']  ?? '',
        tableNumber:   j['table_number']    ?? '',
        status:        j['status']          ?? 'pending',
        paymentMethod: j['payment_method']  ?? 'Cash',
        paymentStatus: j['payment_status']  ?? 'Paid',
        subtotal:      (j['subtotal']      as num).toDouble(),
        discountPct:   (j['discount_pct']  as num).toDouble(),
        discountFlat:  (j['discount_flat'] as num).toDouble(),
        discountAmt:   (j['discount_amt']  as num).toDouble(),
        taxPct:        (j['tax_pct']       as num).toDouble(),
        taxAmt:        (j['tax_amt']       as num).toDouble(),
        total:         (j['total']         as num).toDouble(),
        notes:         j['notes']          ?? '',
        createdAt:     DateTime.parse(j['created_at']),
        items:         items ?? [],
      );

  Map<String, dynamic> toJson() => {
    'branch_id':      branchId,
    'order_number':   orderNumber,
    'order_type':     orderType,
    'customer_type':  customerType,
    'customer_id':    customerId,
    'customer_name':  customerName,
    'customer_phone': customerPhone,
    'table_number':   tableNumber,
    'status':         status,
    'payment_method': paymentMethod,
    'payment_status': paymentStatus,
    'subtotal':       subtotal,
    'discount_pct':   discountPct,
    'discount_flat':  discountFlat,
    'discount_amt':   discountAmt,
    'tax_pct':        taxPct,
    'tax_amt':        taxAmt,
    'total':          total,
    'notes':          notes,
  };

  OrderModel copyWith({String? status, String? paymentStatus}) => OrderModel(
    id: id, branchId: branchId, orderNumber: orderNumber,
    orderType: orderType, customerType: customerType, customerId: customerId,
    customerName: customerName, customerPhone: customerPhone, tableNumber: tableNumber,
    status:        status        ?? this.status,
    paymentMethod: paymentMethod, paymentStatus: paymentStatus ?? this.paymentStatus,
    subtotal: subtotal, discountPct: discountPct, discountFlat: discountFlat,
    discountAmt: discountAmt, taxPct: taxPct, taxAmt: taxAmt, total: total,
    notes: notes, createdAt: createdAt, items: items,
  );
}

class OrderItemModel {
  final String  id;
  final String  orderId;
  final String  branchId;
  final String? menuItemId;
  final String  itemName;
  final String  itemEmoji;
  final String  size;
  final double  unitPrice;
  final int     qty;
  final double  totalPrice;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.branchId,
    required this.menuItemId,
    required this.itemName,
    required this.itemEmoji,
    required this.size,
    required this.unitPrice,
    required this.qty,
    required this.totalPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> j) => OrderItemModel(
    id:         j['id'],
    orderId:    j['order_id'],
    branchId:   j['branch_id'],
    menuItemId: j['menu_item_id'],
    itemName:   j['item_name'],
    itemEmoji:  j['item_emoji']  ?? '',
    size:       j['size']        ?? '',
    unitPrice:  (j['unit_price']  as num).toDouble(),
    qty:        j['qty'],
    totalPrice: (j['total_price'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'order_id':    orderId,
    'branch_id':   branchId,
    'menu_item_id': menuItemId,
    'item_name':   itemName,
    'item_emoji':  itemEmoji,
    'size':        size,
    'unit_price':  unitPrice,
    'qty':         qty,
    'total_price': totalPrice,
  };
}


// ── Category (from Supabase) ──────────────────────────────────────────────────
class Category {
  final String id;
  final String name;
  final Color  color;
  const Category(this.id, this.name, this.color);
}

// ── MenuProduct (from Supabase) ───────────────────────────────────────────────
class MenuProduct {
  final String  id;
  final String  name;
  final double  price;
  final String  categoryId;
  final String? imageUrl;
  final bool    isAvailable;
  final List<ProductSize> sizes;
  final bool    isDeal;

  const MenuProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.imageUrl,
    this.isAvailable = true,
    this.sizes = const [],
    this.isDeal = false,
  });

  factory MenuProduct.fromMenuItemJson(Map<String, dynamic> j,
      {List<ProductSize> sizes = const []}) =>
      MenuProduct(
        id:          j['id'],
        name:        j['name'],
        price:       (j['price'] as num).toDouble(),
        categoryId:  j['category_id'] ?? '',
        imageUrl:    j['image_url'],
        isAvailable: j['is_available'] ?? true,
        sizes:       sizes,
        isDeal:      false,
      );

  factory MenuProduct.fromDealJson(Map<String, dynamic> j,
      {List<ProductSize> sizes = const []}) =>
      MenuProduct(
        id:          j['id'],
        name:        j['name'],
        price:       (j['deal_price'] as num).toDouble(),
        categoryId:  'deals',
        imageUrl:    null,
        isAvailable: j['is_available'] ?? true,
        sizes:       sizes,
        isDeal:      true,
      );
}

// ── ProductSize ───────────────────────────────────────────────────────────────
class ProductSize {
  final String id;
  final String name;
  final double price;
  final int    sortOrder;
  const ProductSize({
    required this.id,
    required this.name,
    required this.price,
    required this.sortOrder,
  });

  factory ProductSize.fromJson(Map<String, dynamic> j) => ProductSize(
    id:        j['id'],
    name:      j['name'],
    price:     (j['price'] as num).toDouble(),
    sortOrder: j['sort_order'] ?? 0,
  );
}

// ── CartItem ──────────────────────────────────────────────────────────────────
class CartItem {
  final MenuProduct product;
  final ProductSize? size;
  int qty;

  CartItem(this.product, {this.qty = 1, this.size});

  double get unitPrice => size?.price ?? product.price;
  double get total     => unitPrice * qty;

  String get displayName =>
      size != null ? '${product.name} (${size!.name})' : product.name;
}

// ── PosTableModel ─────────────────────────────────────────────────────────────
class PosTableModel {
  final String id;
  final String tableNumber;
  final int    capacity;
  final String floor;
  final String section;
  final String status;

  const PosTableModel({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    required this.floor,
    required this.section,
    required this.status,
  });

  factory PosTableModel.fromJson(Map<String, dynamic> j) => PosTableModel(
    id:          j['id'],
    tableNumber: j['table_number'],
    capacity:    j['capacity'] ?? 0,
    floor:       j['floor']   ?? '',
    section:     j['section'] ?? '',
    status:      j['status']  ?? 'available',
  );

  String get label => '$tableNumber (${section.isNotEmpty ? section : floor}) — Cap: $capacity';
}

// ── PosCustomerModel ──────────────────────────────────────────────────────────
class PosCustomerModel {
  final String id;
  final String name;
  final String phone;
  final String type;
  final double balance;
  final double discount; // % applied automatically when picked at checkout
  final int    orders;
  final double spent;
  final String loyalty;  // regular | silver | gold

  const PosCustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    required this.balance,
    this.discount = 0,
    this.orders   = 0,
    this.spent    = 0,
    this.loyalty  = 'regular',
  });

  factory PosCustomerModel.fromJson(Map<String, dynamic> j) => PosCustomerModel(
    id:       j['id'],
    name:     j['name'],
    phone:    j['phone']   ?? '',
    type:     j['type']    ?? 'walk_in',
    balance:  (j['balance']  as num?)?.toDouble() ?? 0.0,
    discount: (j['discount'] as num?)?.toDouble() ?? 0.0,
    orders:   (j['orders']   as num?)?.toInt()    ?? 0,
    spent:    (j['spent']    as num?)?.toDouble() ?? 0.0,
    loyalty:  j['loyalty']  as String? ?? 'regular',
  );

  String get phoneDigits => phone.replaceAll(RegExp(r'\D'), '');

  String get label => '$name — ${phone.isNotEmpty ? phone : "No phone"}';
}
// ── PosRiderModel (for POS dropdown) ─────────────────────────────────────────
class PosRiderModel {
  final String id;
  final String name;
  final String phone;
  final String vehicle;
  final double chargePerDelivery;

  const PosRiderModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.chargePerDelivery,
  });

  factory PosRiderModel.fromJson(Map<String, dynamic> j) => PosRiderModel(
    id:                 j['id'],
    name:               j['name'],
    phone:              j['phone']               ?? '',
    vehicle:            j['vehicle']             ?? '',
    chargePerDelivery:  (j['charge_per_delivery'] as num).toDouble(),
  );

  String get label => '$name — ${vehicle.isNotEmpty ? vehicle : phone}';
}
