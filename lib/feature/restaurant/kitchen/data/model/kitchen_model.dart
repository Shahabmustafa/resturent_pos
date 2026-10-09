enum OrderStatus { pending, preparing, ready }

class KitchenOrderItem {
  final String name;
  final int    qty;
  final String emoji;
  bool isDone;
  KitchenOrderItem(this.name, this.qty, this.emoji, {this.isDone = false});
}

class KitchenOrder {
  final String id;          // UUID String (was int)
  final String orderNum;
  final String table;
  final String customerName;
  final String orderType;
  final String notes;
  final List<KitchenOrderItem> items;
  OrderStatus status;
  final DateTime createdAt;
  DateTime? startedAt;
  DateTime? readyAt;

  KitchenOrder({
    required this.id,
    required this.orderNum,
    required this.table,
    required this.customerName,
    required this.orderType,
    required this.notes,
    required this.items,
    required this.createdAt,
    this.status = OrderStatus.pending,
  });

  int  get totalItems  => items.fold(0, (s, i) => s + i.qty);
  int  get doneItems   => items.where((i) => i.isDone).length;
  bool get allItemsDone => items.isEmpty ? false : doneItems == items.length;

  Duration get elapsed  => DateTime.now().difference(startedAt ?? createdAt);
  Duration get waitTime => DateTime.now().difference(createdAt);
}