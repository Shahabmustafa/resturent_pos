import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resturent_application/feature/delivery/data/model/delivery_model.dart';
import 'package:resturent_application/feature/rider_app/data/rider_datasource.dart';
import 'package:resturent_application/feature/rider_app/presentation/provider/rider_provider.dart';
import 'package:resturent_application/feature/rider_app/presentation/screen/rider_login_screen.dart';
import 'package:resturent_application/feature/rider_app/presentation/screen/rider_order_detail_screen.dart';
import 'package:resturent_application/feature/rider_app/presentation/screen/rider_shell.dart';
import 'package:resturent_application/feature/rider_app/rider_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _now = DateTime.now();

Rider _rider(RiderStatus status) => Rider(
  id: 'r1',
  name: 'Ali Hassan',
  phone: '03121212121',
  vehicle: 'Honda CD70 • LEA-1234',
  status: status,
  chargePerDelivery: 150,
  totalDeliveries: 128,
  totalEarnings: 19200,
);

DeliveryOrder _order(String id, DeliveryOrderStatus status, {double amount = 2650, String notes = ''}) => DeliveryOrder(
  id: id,
  orderNum: 'ORD-10$id',
  customerName: 'Sara Khan',
  phone: '0300 1234567',
  address: 'House 12, Street 4, Gulberg III, Lahore',
  items: 'Chicken Karahi (Full) × 1, Garlic Naan × 4, Mint Raita × 2',
  amount: amount,
  status: status,
  createdAt: _now.subtract(const Duration(minutes: 30)),
  assignedAt: _now.subtract(const Duration(minutes: 20)),
  deliveredAt: status == DeliveryOrderStatus.delivered ? _now.subtract(const Duration(minutes: 5)) : null,
  notes: notes,
  riderId: 'r1',
);

/// Serves fixed data instead of Supabase.
class _FakeDs extends RiderDatasource {
  final Rider rider;
  final List<DeliveryOrder> orders;

  _FakeDs(this.rider, this.orders)
    : super(SupabaseClient('http://localhost', 'anon', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  @override
  Future<Rider?> fetchMe() async => rider;
  @override
  Stream<List<DeliveryOrder>> ordersStream(String riderId) => Stream.value(orders);
  @override
  Future<List<DeliveryOrder>> fetchDelivered(String riderId, DateTime since) async =>
      orders.where((o) => o.status == DeliveryOrderStatus.delivered).toList();
}

Future<void> _pump(WidgetTester tester, Widget home, _FakeDs ds, {Size size = const Size(360, 740)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [riderDsProvider.overrideWithValue(ds)],
      child: MaterialApp(home: home),
    ),
  );
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('phone number → rider login email', () {
    test('accepts the usual Pakistani formats', () {
      for (final input in [
        '03001234567',
        '0300-1234567',
        '0300 1234567',
        '+92 300 1234567',
        '923001234567',
        '3001234567',
      ]) {
        expect(RiderDatasource.emailForPhone(input), '03001234567@rider.pos', reason: input);
      }
    });

    test('rejects input that is not a phone number', () {
      expect(RiderDatasource.emailForPhone(''), isNull);
      expect(RiderDatasource.emailForPhone('abc'), isNull);
      expect(RiderDatasource.emailForPhone('12345'), isNull);
    });
  });

  test('RiderState splits active and finished deliveries', () {
    final s = RiderState(
      orders: [
        _order('1', DeliveryOrderStatus.onTheWay),
        _order('2', DeliveryOrderStatus.assigned),
        _order('3', DeliveryOrderStatus.delivered),
        _order('4', DeliveryOrderStatus.cancelled),
      ],
    );
    expect(s.active.map((o) => o.id), ['1', '2']);
    expect(s.history.map((o) => o.id), ['3', '4']);
    expect(s.order('3')?.status, DeliveryOrderStatus.delivered);
    expect(s.order('missing'), isNull);
  });

  testWidgets('login screen fits a small phone', (tester) async {
    await _pump(tester, const RiderLoginScreen(), _FakeDs(_rider(RiderStatus.available), const []));
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Not a rider? Order food instead'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every tab renders on a small phone without errors', (tester) async {
    final ds = _FakeDs(_rider(RiderStatus.busy), [
      _order('1', DeliveryOrderStatus.onTheWay, notes: 'Call before arriving'),
      _order('2', DeliveryOrderStatus.assigned, amount: 1890),
      _order('3', DeliveryOrderStatus.delivered, amount: 1240),
    ]);
    await _pump(tester, const RiderShell(), ds);

    // Deliveries: busy header, two active cards with the right next step.
    expect(find.text('On a delivery'), findsOneWidget);
    expect(find.text('BUSY'), findsOneWidget);
    expect(find.text('Mark Delivered'), findsOneWidget);
    expect(find.text('3 items · Chicken Karahi (Full) × 1 +2 more'), findsWidgets);
    // The second card sits below the fold on a small phone.
    await tester.scrollUntilVisible(find.text('Picked Up — Start Trip'), 300, scrollable: find.byType(Scrollable).last);
    expect(find.text('Picked Up — Start Trip'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, 2000));
    await tester.pump(const Duration(milliseconds: 300));

    // History tab
    await tester.tap(find.text('History'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('ORD-103'), findsOneWidget);
    // Finished deliveries are grouped under a day heading (Yesterday just after midnight).
    expect(find.text('TODAY').evaluate().length + find.text('YESTERDAY').evaluate().length, greaterThan(0));
    expect(tester.takeException(), isNull);

    // Earnings: one delivery today at £150.
    await tester.tap(find.text('Earnings').last);
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('You earned'), findsOneWidget);
    expect(find.text('£150.00'), findsWidgets);
    expect(tester.takeException(), isNull);

    // Profile: all-time totals from the rider row.
    await tester.tap(find.text('Profile').last);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('128'), findsOneWidget);
    expect(find.text('£19,200.00'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Switch to the customer app'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Switch to the customer app'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delivery detail lists every item and the next step', (tester) async {
    final ds = _FakeDs(_rider(RiderStatus.busy), [_order('1', DeliveryOrderStatus.assigned)]);
    await _pump(tester, const RiderOrderDetailScreen(orderId: '1'), ds);

    expect(find.text('ORD-101'), findsOneWidget);
    expect(find.text('Garlic Naan × 4'), findsOneWidget);
    expect(find.text('Picked Up — Start Trip'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline rider sees the go-online hint', (tester) async {
    await _pump(tester, const RiderShell(), _FakeDs(_rider(RiderStatus.offline), const []));
    expect(find.text("You're offline"), findsWidgets);
    expect(find.byType(Switch), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
