import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../delivery/data/model/delivery_model.dart';
import '../../data/rider_datasource.dart';
import '../../rider_app.dart';

bool isActiveDelivery(DeliveryOrder o) =>
    o.status == DeliveryOrderStatus.assigned || o.status == DeliveryOrderStatus.onTheWay;

class RiderState {
  final Rider? me;
  final List<DeliveryOrder>? orders; // null until the live list first arrives
  final String? error;
  final bool togglingOnline;
  final Set<String> working; // delivery ids with an action in flight
  final int newAssignments; // goes up each time the restaurant assigns a new delivery

  const RiderState({
    this.me,
    this.orders,
    this.error,
    this.togglingOnline = false,
    this.working = const {},
    this.newAssignments = 0,
  });

  List<DeliveryOrder> get active => (orders ?? const []).where(isActiveDelivery).toList();
  List<DeliveryOrder> get history => (orders ?? const []).where((o) => !isActiveDelivery(o)).toList();

  DeliveryOrder? order(String id) => orders?.where((o) => o.id == id).firstOrNull;

  RiderState copyWith({
    Rider? me,
    List<DeliveryOrder>? orders,
    String? error,
    bool clearError = false,
    bool? togglingOnline,
    Set<String>? working,
    int? newAssignments,
  }) => RiderState(
    me: me ?? this.me,
    orders: orders ?? this.orders,
    error: clearError ? null : error ?? this.error,
    togglingOnline: togglingOnline ?? this.togglingOnline,
    working: working ?? this.working,
    newAssignments: newAssignments ?? this.newAssignments,
  );
}

/// The signed-in rider and their live deliveries, shared by every rider tab.
class RiderNotifier extends StateNotifier<RiderState> {
  final RiderDatasource _ds;
  StreamSubscription<List<DeliveryOrder>>? _sub;
  Set<String> _seenActive = {};

  RiderNotifier(this._ds) : super(const RiderState()) {
    load();
  }

  Future<void> load() async {
    try {
      final me = await _ds.fetchMe();
      if (!mounted) return;
      if (me == null) {
        // The session isn't a rider's (or the login was removed) — back to login.
        await _ds.signOut();
        return;
      }
      state = state.copyWith(me: me, clearError: true);
      _sub ??= _ds
          .ordersStream(me.id)
          .listen(
            _onOrders,
            onError: (_) {
              if (mounted) state = state.copyWith(error: 'Live updates paused. Pull down to refresh.');
            },
          );
    } catch (_) {
      if (mounted) state = state.copyWith(error: 'Could not load your account. Check your internet and try again.');
    }
  }

  void _onOrders(List<DeliveryOrder> orders) {
    if (!mounted) return;
    final active = {
      for (final o in orders)
        if (isActiveDelivery(o)) o.id,
    };
    // Only count as "new" after the first load.
    final fresh = state.orders != null && active.difference(_seenActive).isNotEmpty;
    _seenActive = active;
    state = state.copyWith(orders: orders, clearError: true, newAssignments: fresh ? state.newAssignments + 1 : null);
    _refreshMe(); // assigning/finishing changes the rider's status and totals
  }

  Future<void> _refreshMe() async {
    try {
      final me = await _ds.fetchMe();
      if (mounted && me != null) state = state.copyWith(me: me);
    } catch (_) {}
  }

  Future<void> refresh() async {
    await _sub?.cancel();
    _sub = null;
    await load();
  }

  /// Returns a message to show, or null.
  Future<String?> setOnline(bool online) async {
    state = state.copyWith(togglingOnline: true);
    try {
      final status = await _ds.setOnline(online);
      await _refreshMe();
      return status == 'busy' && !online ? 'Finish your current delivery before going offline.' : null;
    } catch (_) {
      return 'Could not change status. Try again.';
    } finally {
      if (mounted) state = state.copyWith(togglingOnline: false);
    }
  }

  /// Both actions return null on success or an error message.
  Future<String?> startTrip(String deliveryId) => _run(deliveryId, () => _ds.startTrip(deliveryId));
  Future<String?> markDelivered(String deliveryId) => _run(deliveryId, () => _ds.markDelivered(deliveryId));

  Future<String?> _run(String id, Future<void> Function() action) async {
    state = state.copyWith(working: {...state.working, id});
    try {
      await action();
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Check your internet and try again.';
    } finally {
      if (mounted) state = state.copyWith(working: {...state.working}..remove(id));
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final riderProvider = StateNotifierProvider.autoDispose<RiderNotifier, RiderState>(
  (ref) => RiderNotifier(ref.read(riderDsProvider)),
);

/// Finished deliveries from the last [days] days (1 = today) for the Earnings tab.
/// Re-fetches whenever the rider's delivery count changes.
final riderEarningsProvider = FutureProvider.autoDispose.family<List<DeliveryOrder>, int>((ref, days) async {
  // Select plain values: the Rider object is replaced on every refresh.
  final riderId = ref.watch(riderProvider.select((s) => s.me?.id));
  ref.watch(riderProvider.select((s) => s.me?.totalDeliveries));
  if (riderId == null) return const [];
  final now = DateTime.now();
  final since = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
  return ref.read(riderDsProvider).fetchDelivered(riderId, since);
});
