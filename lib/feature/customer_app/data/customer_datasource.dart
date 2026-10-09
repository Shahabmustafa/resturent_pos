import 'package:supabase_flutter/supabase_flutter.dart';
import 'menu_data.dart';
import 'model/dish_model.dart';

class CustomerMenu {
  final List<MenuCategory> categories;
  final List<Dish> dishes;

  const CustomerMenu({required this.categories, required this.dishes});

  List<Dish> byCategory(String id) => dishes.where((d) => d.categoryId == id).toList();

  MenuCategory? category(String? id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// Details the customer enters at checkout.
class CheckoutDetails {
  final bool delivery;
  final String name;
  final String phone;
  final String address;
  final String notes;

  const CheckoutDetails({
    required this.delivery,
    required this.name,
    required this.phone,
    this.address = '',
    this.notes = '',
  });
}

/// One line of a customer's past order.
class CustomerOrderLine {
  final String name;
  final int qty;
  final double total;

  const CustomerOrderLine({required this.name, required this.qty, required this.total});
}

/// An order as the customer sees it on "My Orders".
class CustomerOrder {
  final String id;
  final String number;
  final String type; // Delivery | Takeaway
  final String status; // pending | completed | cancelled (| legacy kitchen statuses)
  final String paymentStatus;
  final double total;
  final DateTime createdAt;
  final List<CustomerOrderLine> lines;
  final int? myRating; // stars the customer gave this order, null if not rated yet

  const CustomerOrder({
    required this.id,
    required this.number,
    required this.type,
    required this.status,
    required this.paymentStatus,
    required this.total,
    required this.createdAt,
    this.lines = const [],
    this.myRating,
  });

  bool get isOpen => status != 'completed' && status != 'cancelled' && status != 'delivered';

  bool get canRate => myRating == null && (status == 'completed' || status == 'delivered' || status == 'served');

  factory CustomerOrder.fromJson(Map<String, dynamic> j, List<CustomerOrderLine> lines, int? myRating) => CustomerOrder(
    id: j['id'] as String,
    number: (j['order_number'] as String?) ?? '',
    type: (j['order_type'] as String?) ?? 'Takeaway',
    status: ((j['status'] as String?) ?? 'pending').toLowerCase(),
    paymentStatus: (j['payment_status'] as String?) ?? 'Unpaid',
    total: (j['total'] as num?)?.toDouble() ?? 0,
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
    lines: lines,
    myRating: myRating,
  );
}

/// A customer's rating of a completed order, shown publicly on the home page.
class PublicFeedback {
  final String name; // first name + last initial
  final int rating;
  final String comment;
  final DateTime createdAt;

  const PublicFeedback({required this.name, required this.rating, required this.comment, required this.createdAt});

  factory PublicFeedback.fromJson(Map<String, dynamic> j) => PublicFeedback(
    name: (j['display_name'] as String?) ?? 'Customer',
    rating: (j['rating'] as num).toInt(),
    comment: (j['comment'] as String?) ?? '',
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
  );
}

/// Opening hours from the POS branch settings.
class OpeningHoursInfo {
  final String opening; // as typed in the POS, e.g. "11:00 AM"
  final String closing;
  final bool is24Hours;

  const OpeningHoursInfo({required this.opening, required this.closing, required this.is24Hours});

  /// "11:00 AM – 11:30 PM", or "Open 24 hours".
  String get range => is24Hours ? 'Open 24 hours' : '$opening – $closing';
}

/// Every rating plus the newest ones with a written comment.
class FeedbackSummary {
  final double average;
  final int count;
  final List<PublicFeedback> latest;

  const FeedbackSummary({required this.average, required this.count, required this.latest});
}

class CustomerDatasource {
  final SupabaseClient _db;

  CustomerDatasource(this._db);

  /// Same tables the POS "Menu & Categories" screen edits; only available items.
  Future<CustomerMenu> fetchMenu() async {
    final results = await Future.wait([
      // Oldest first = printed-menu order (postgrest orders descending by default).
      _db.from('categories').select().eq('branch_id', kWebsiteBranchId).order('created_at', ascending: true),
      _db
          .from('menu_items')
          .select('*, menu_item_sizes(*)')
          .eq('branch_id', kWebsiteBranchId)
          .eq('is_available', true)
          .order('created_at', ascending: true), // printed-menu order
    ]);

    final dishes = [for (final j in results[1] as List) Dish.fromMenuItemJson(j)];
    final categories = <MenuCategory>[];
    for (final j in results[0] as List) {
      final items = dishes.where((d) => d.categoryId == j['id']).toList();
      if (items.isEmpty) continue; // don't show empty categories on the site
      categories.add(
        MenuCategory(
          id: j['id'] as String,
          name: j['name'] as String,
          tagline: (j['description'] as String?)?.trim() ?? '',
          image: items.firstWhere((d) => d.image.isNotEmpty, orElse: () => items.first).image,
          dishCount: items.length,
        ),
      );
    }
    return CustomerMenu(categories: categories, dishes: dishes);
  }

  /// Places the order through the `place_website_order` database function, which
  /// prices every line from the menu, assigns the next order number and links the
  /// order to the signed-in customer. It then shows up on the desktop Orders screen.
  Future<String> placeOrder({
    required CheckoutDetails details,
    required List<({Dish dish, DishOption option, int qty})> lines,
  }) async {
    final number = await _db.rpc(
      'place_website_order',
      params: {
        'p_delivery': details.delivery,
        'p_customer_name': details.name,
        'p_customer_phone': details.phone,
        'p_address': details.delivery ? details.address : '',
        'p_notes': details.notes,
        'p_items': [
          for (final l in lines)
            {'menu_item_id': l.dish.id, 'size': l.option.isSize ? l.option.label : '', 'qty': l.qty},
        ],
      },
    );
    return number as String;
  }

  /// Table number behind a table QR code, or null if the code isn't valid.
  Future<String?> tableForQr(String token) async =>
      await _db.rpc('table_for_qr', params: {'p_token': token}) as String?;

  /// Sends a dine-in order for the table behind [token] through the
  /// `place_table_order` database function. No login needed; prices come from
  /// the menu. It shows up on the desktop as an unpaid order for that table.
  Future<String> placeTableOrder({
    required String token,
    required String name,
    required String notes,
    required List<({Dish dish, DishOption option, int qty})> lines,
  }) async {
    final number = await _db.rpc(
      'place_table_order',
      params: {
        'p_token': token,
        'p_customer_name': name,
        'p_notes': notes,
        'p_items': [
          for (final l in lines)
            {'menu_item_id': l.dish.id, 'size': l.option.isSize ? l.option.label : '', 'qty': l.qty},
        ],
      },
    );
    return number as String;
  }

  /// The signed-in customer's orders, newest first, re-emitted whenever the
  /// restaurant changes one (e.g. marks it completed). RLS limits rows to the
  /// customer's own orders.
  Stream<List<CustomerOrder>> watchMyOrders(String userId) {
    return _db.from('orders').stream(primaryKey: ['id']).eq('customer_user_id', userId).order('created_at').asyncMap((
      rows,
    ) async {
      final ids = [for (final r in rows) r['id'] as String];
      final linesByOrder = <String, List<CustomerOrderLine>>{};
      final ratingByOrder = <String, int>{};
      if (ids.isNotEmpty) {
        final results = await Future.wait([
          _db.from('order_items').select('order_id, item_name, qty, total_price').inFilter('order_id', ids),
          _db.from('order_feedback').select('order_id, rating').inFilter('order_id', ids),
        ]);
        final items = results[0];
        for (final f in results[1]) {
          ratingByOrder[f['order_id'] as String] = (f['rating'] as num).toInt();
        }
        for (final i in items) {
          linesByOrder
              .putIfAbsent(i['order_id'] as String, () => [])
              .add(
                CustomerOrderLine(
                  name: i['item_name'] as String,
                  qty: (i['qty'] as num).toInt(),
                  total: (i['total_price'] as num).toDouble(),
                ),
              );
        }
      }
      return [
        for (final r in rows) CustomerOrder.fromJson(r, linesByOrder[r['id']] ?? const [], ratingByOrder[r['id']]),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// Rates one of the customer's own completed orders (once). The database
  /// function checks ownership and status and stores only a short public name.
  Future<void> submitFeedback({required String orderId, required int rating, required String comment}) async {
    await _db.rpc(
      'submit_order_feedback',
      params: {'p_order_id': orderId, 'p_rating': rating, 'p_comment': comment.trim()},
    );
  }

  /// Hours from the website branch, read through `website_hours()` so the rest of
  /// the branch row stays private.
  Future<OpeningHoursInfo> fetchOpeningHours() async {
    final rows = await _db.rpc('website_hours') as List;
    final j = rows.isEmpty ? const <String, dynamic>{} : rows.first as Map<String, dynamic>;
    String clean(Object? v, String fallback) {
      final s = (v as String?)?.trim() ?? '';
      return s.isEmpty ? fallback : s;
    }

    return OpeningHoursInfo(
      opening: clean(j['opening_time'], '11:00 AM'),
      closing: clean(j['closing_time'], '11:30 PM'),
      is24Hours: j['is_24_hours'] as bool? ?? false,
    );
  }

  /// Website feedback for the home page: overall average and the newest
  /// reviews that have a comment.
  Future<FeedbackSummary> fetchFeedback({int limit = 6}) async {
    final rows = await _db
        .from('order_feedback')
        .select('display_name, rating, comment, created_at')
        .eq('branch_id', kWebsiteBranchId)
        .order('created_at', ascending: false)
        .limit(500);
    final all = [for (final r in rows) PublicFeedback.fromJson(r)];
    final average = all.isEmpty ? 0.0 : all.fold<int>(0, (sum, f) => sum + f.rating) / all.length;
    return FeedbackSummary(
      average: average,
      count: all.length,
      latest: all.where((f) => f.comment.isNotEmpty).take(limit).toList(),
    );
  }
}
