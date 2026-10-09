import 'package:supabase_flutter/supabase_flutter.dart';
import '../../delivery/data/model/delivery_model.dart';

/// Everything the Rider mobile app reads or changes. Riders can only see their
/// own row and the deliveries assigned to them (see the rider_app migration);
/// status changes go through security-definer RPCs.
class RiderDatasource {
  final SupabaseClient _db;
  RiderDatasource(this._db);

  /// Riders sign in with their phone; the auth account behind it is
  /// `<digits>@rider.pos` (made by the manage-rider-login Edge Function — keep in sync).
  static String? emailForPhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('92') && digits.length == 12) digits = '0${digits.substring(2)}';
    if (digits.length == 10 && digits.startsWith('3')) digits = '0$digits';
    return digits.length >= 7 ? '$digits@rider.pos' : null;
  }

  Future<Rider> signIn(String phone, String password) async {
    final email = emailForPhone(phone);
    if (email == null) throw Exception('Enter a valid phone number');
    try {
      await _db.auth.signInWithPassword(email: email, password: password);
    } on AuthException {
      throw Exception('Wrong phone number or password');
    }
    final me = await fetchMe();
    if (me == null) {
      await _db.auth.signOut();
      throw Exception('This account is not a rider account');
    }
    return me;
  }

  Future<void> signOut() => _db.auth.signOut();

  /// The signed-in rider, or null when the session doesn't belong to a rider.
  Future<Rider?> fetchMe() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    final res = await _db.from('riders').select().eq('auth_user_id', uid).maybeSingle();
    return res == null ? null : Rider.fromJson(res);
  }

  /// Live list of this rider's deliveries, newest first.
  Stream<List<DeliveryOrder>> ordersStream(String riderId) => _db
      .from('delivery_orders')
      .stream(primaryKey: ['id'])
      .eq('rider_id', riderId)
      .order('created_at', ascending: false)
      .limit(100)
      .map((rows) => rows.map(DeliveryOrder.fromJson).toList());

  /// Deliveries finished since [since] — for the Earnings screen, which can
  /// reach further back than the live list's 100 rows.
  Future<List<DeliveryOrder>> fetchDelivered(String riderId, DateTime since) async {
    final res = await _db
        .from('delivery_orders')
        .select()
        .eq('rider_id', riderId)
        .eq('status', 'delivered')
        .gte('delivered_at', since.toUtc().toIso8601String())
        .order('delivered_at', ascending: false);
    return (res as List).map((e) => DeliveryOrder.fromJson(e)).toList();
  }

  Future<void> changePassword(String password) async {
    try {
      await _db.auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Returns the rider's status after the change ('busy' stays busy).
  Future<String> setOnline(bool online) async =>
      (await _db.rpc('rider_set_online', params: {'p_online': online})).toString();

  Future<void> startTrip(String deliveryId) => _db.rpc('rider_start_trip', params: {'p_delivery_id': deliveryId});

  Future<void> markDelivered(String deliveryId) =>
      _db.rpc('rider_mark_delivered', params: {'p_delivery_id': deliveryId});
}
