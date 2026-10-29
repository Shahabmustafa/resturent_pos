import 'package:supabase_flutter/supabase_flutter.dart';

String _digits(String v) => v.replaceAll(RegExp(r'\D'), '');

/// A customer as shown on the collection lookup screens.
class CustomerProfile {
  final String? id; // null until saved
  String phone;
  String phone2;
  String phone3;
  String firstName;
  String lastName;
  String email;
  String address;
  String city;
  String postcode;
  String comments;
  final int orders;
  bool blacklisted;

  CustomerProfile({
    this.id,
    this.phone = '',
    this.phone2 = '',
    this.phone3 = '',
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.address = '',
    this.city = '',
    this.postcode = '',
    this.comments = '',
    this.orders = 0,
    this.blacklisted = false,
  });

  /// `customers.name` holds the full name; the first word is the first name.
  factory CustomerProfile.fromMap(Map<String, dynamic> m) {
    final name = ((m['name'] as String?) ?? '').trim();
    final space = name.indexOf(' ');
    return CustomerProfile(
      id: m['id'] as String,
      phone: (m['phone'] as String?) ?? '',
      phone2: (m['phone2'] as String?) ?? '',
      phone3: (m['phone3'] as String?) ?? '',
      firstName: space < 0 ? name : name.substring(0, space),
      lastName: space < 0 ? '' : name.substring(space + 1).trim(),
      email: (m['email'] as String?) ?? '',
      address: (m['address'] as String?) ?? '',
      city: (m['city'] as String?) ?? '',
      postcode: (m['postcode'] as String?) ?? '',
      comments: (m['comments'] as String?) ?? '',
      orders: (m['orders'] as num?)?.toInt() ?? 0,
      blacklisted: (m['blacklisted'] as bool?) ?? false,
    );
  }

  String get fullName => '${firstName.trim()} ${lastName.trim()}'.trim();

  bool hasPhone(String digits) =>
      digits.isNotEmpty &&
      [phone, phone2, phone3].any((p) => _digits(p) == digits);

  Map<String, dynamic> toMap() => {
    'name': fullName.isEmpty ? 'Customer' : fullName,
    'phone': phone.trim(),
    'phone2': phone2.trim(),
    'phone3': phone3.trim(),
    'email': email.trim(),
    'address': address.trim(),
    'city': city.trim(),
    'postcode': postcode.trim().toUpperCase(),
    'comments': comments.trim(),
  };
}

/// One item of a past order, used to put the same items back in the cart.
class OrderLine {
  final String? menuItemId;
  final String name;
  final String size;
  final int qty;
  const OrderLine({
    required this.menuItemId,
    required this.name,
    required this.size,
    required this.qty,
  });
}

/// A past order on the customer's Orders tab.
class CustomerOrderSummary {
  final String number;
  final String type;
  final String status;
  final double total;
  final DateTime? createdAt;
  final List<OrderLine> lines;

  const CustomerOrderSummary({
    required this.number,
    required this.type,
    required this.status,
    required this.total,
    this.createdAt,
    this.lines = const [],
  });
}

class CustomerLookupDatasource {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<CustomerProfile>> fetchAll(String branchId) async {
    final rows = await _db.from('customers').select().order('name');
    return (rows as List).map((e) => CustomerProfile.fromMap(e)).toList();
  }

  /// Matches any of the customer's three phone numbers, ignoring spaces and symbols.
  Future<CustomerProfile?> findByPhone(String branchId, String phone) async {
    final digits = _digits(phone);
    if (digits.isEmpty) return null;
    final all = await fetchAll(branchId);
    return all.where((c) => c.hasPhone(digits)).firstOrNull;
  }

  /// Inserts or updates the customer and returns their id.
  Future<String> save(String branchId, CustomerProfile c) async {
    if (c.id != null) {
      await _db.from('customers').update(c.toMap()).eq('id', c.id!);
      return c.id!;
    }
    final row = await _db
        .from('customers')
        .insert({...c.toMap(), 'type': 'walk_in'})
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> setBlacklisted(String customerId, bool value) =>
      _db.from('customers').update({'blacklisted': value}).eq('id', customerId);

  Future<List<CustomerOrderSummary>> fetchOrders(String customerId) async {
    final rows = await _db
        .from('orders')
        .select(
          'order_number, order_type, status, total, created_at, order_items(menu_item_id, item_name, size, qty)',
        )
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List)
        .map(
          (r) => CustomerOrderSummary(
            number: (r['order_number'] as String?) ?? '',
            type: (r['order_type'] as String?) ?? '',
            status: (r['status'] as String?) ?? '',
            total:
                double.tryParse('${r['total'] ?? 0}') ??
                0, // numeric may arrive as text
            createdAt: DateTime.tryParse(
              (r['created_at'] as String?) ?? '',
            )?.toLocal(),
            lines: [
              for (final i in (r['order_items'] as List? ?? []))
                OrderLine(
                  menuItemId: i['menu_item_id'] as String?,
                  name: (i['item_name'] as String?) ?? '',
                  size: (i['size'] as String?) ?? '',
                  qty: (i['qty'] as num?)?.toInt() ?? 1,
                ),
            ],
          ),
        )
        .toList();
  }
}
