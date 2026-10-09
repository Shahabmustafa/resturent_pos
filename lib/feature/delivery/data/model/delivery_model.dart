enum DeliveryOrderStatus { pending, assigned, onTheWay, delivered, cancelled }
enum RiderStatus          { available, busy, offline }

class Rider {
  final String id;
  String name, phone, vehicle;
  RiderStatus status;
  double chargePerDelivery;
  int    totalDeliveries;
  double totalEarnings;
  String? currentOrderId;
  bool   hasLogin; // can sign in to the Rider mobile app

  Rider({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.status,
    required this.chargePerDelivery,
    required this.totalDeliveries,
    required this.totalEarnings,
    this.currentOrderId,
    this.hasLogin = false,
  });

  factory Rider.fromJson(Map<String, dynamic> j) => Rider(
    id:                 j['id'],
    name:               j['name'],
    phone:              j['phone']               ?? '',
    vehicle:            j['vehicle']             ?? '',
    status:             _parseRiderStatus(j['status'] as String? ?? 'available'),
    chargePerDelivery:  (j['charge_per_delivery'] as num).toDouble(),
    totalDeliveries:    (j['total_deliveries']    as num).toInt(),
    totalEarnings:      (j['total_earnings']      as num).toDouble(),
    hasLogin:           j['auth_user_id'] != null,
  );

  Map<String, dynamic> toInsert(String branchId) => {
    'branch_id':          branchId,
    'name':               name,
    'phone':              phone,
    'vehicle':            vehicle,
    'status':             status.toJson(),
    'charge_per_delivery': chargePerDelivery,
    'total_deliveries':   totalDeliveries,
    'total_earnings':     totalEarnings,
  };

  static RiderStatus _parseRiderStatus(String v) {
    switch (v) {
      case 'busy':    return RiderStatus.busy;
      case 'offline': return RiderStatus.offline;
      default:        return RiderStatus.available;
    }
  }
}

extension RiderStatusX on RiderStatus {
  String toJson() {
    switch (this) {
      case RiderStatus.available: return 'available';
      case RiderStatus.busy:      return 'busy';
      case RiderStatus.offline:   return 'offline';
    }
  }
}

class DeliveryOrder {
  final String  id;
  final String? orderId;
  String orderNum, customerName, phone, address, items, notes;
  double amount;
  DeliveryOrderStatus status;
  String? riderId;
  DateTime  createdAt;
  DateTime? assignedAt;
  DateTime? deliveredAt;

  DeliveryOrder({
    required this.id,
    this.orderId,
    required this.orderNum,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.items,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.riderId,
    this.assignedAt,
    this.deliveredAt,
    this.notes = '',
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> j) => DeliveryOrder(
    id:           j['id'],
    orderId:      j['order_id'],
    orderNum:     j['order_num']      ?? '',
    customerName: j['customer_name']  ?? '',
    phone:        j['phone']          ?? '',
    address:      j['address']        ?? '',
    items:        j['items']          ?? '',
    amount:       (j['amount']        as num).toDouble(),
    notes:        j['notes']          ?? '',
    status:       _parseStatus(j['status'] as String? ?? 'pending'),
    riderId:      j['rider_id'],
    createdAt:    DateTime.parse(j['created_at']),
    assignedAt:   j['assigned_at']  != null ? DateTime.parse(j['assigned_at'])  : null,
    deliveredAt:  j['delivered_at'] != null ? DateTime.parse(j['delivered_at']) : null,
  );

  static DeliveryOrderStatus _parseStatus(String v) {
    switch (v) {
      case 'assigned':    return DeliveryOrderStatus.assigned;
      case 'on_the_way':  return DeliveryOrderStatus.onTheWay;
      case 'delivered':   return DeliveryOrderStatus.delivered;
      case 'cancelled':   return DeliveryOrderStatus.cancelled;
      default:            return DeliveryOrderStatus.pending;
    }
  }

  String get statusJson {
    switch (status) {
      case DeliveryOrderStatus.pending:   return 'pending';
      case DeliveryOrderStatus.assigned:  return 'assigned';
      case DeliveryOrderStatus.onTheWay:  return 'on_the_way';
      case DeliveryOrderStatus.delivered: return 'delivered';
      case DeliveryOrderStatus.cancelled: return 'cancelled';
    }
  }
}