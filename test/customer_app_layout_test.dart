import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resturent_application/feature/customer_app/data/customer_datasource.dart';
import 'package:resturent_application/feature/customer_app/data/model/dish_model.dart';
import 'package:resturent_application/feature/customer_app/presentation/provider/cart_provider.dart';
import 'package:resturent_application/feature/customer_app/presentation/provider/customer_providers.dart';
import 'package:resturent_application/feature/customer_app/presentation/provider/navigation_provider.dart';
import 'package:resturent_application/feature/customer_app/presentation/screen/customer_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

const _pizza = Dish(
  id: 'pizza',
  name: 'Chicken Pizza',
  description: 'Stone-baked with chicken tikka.',
  categoryId: 'c-pizza',
  image: '',
  options: [DishOption('Small', 11), DishOption('Large', 14)],
);

const _fries = Dish(
  id: 'fries',
  name: 'Chicken Fry',
  description: '',
  categoryId: 'c-fry',
  image: '',
  options: [DishOption('Regular', 800)],
);

const _menu = CustomerMenu(
  categories: [
    MenuCategory(id: 'c-pizza', name: 'Pizza', tagline: '1 item', image: '', dishCount: 1),
    MenuCategory(id: 'c-fry', name: 'Fry', tagline: '1 item', image: '', dishCount: 1),
  ],
  dishes: [_pizza, _fries],
);

final _customer = User(
  id: 'u1',
  appMetadata: const {},
  userMetadata: const {'full_name': 'Ali Khan', 'phone': '03001234567'},
  aud: 'authenticated',
  email: 'ali@example.com',
  createdAt: '2026-01-01T00:00:00Z',
);

final _orders = [
  CustomerOrder(
    id: 'o2', number: '#1004', type: 'Delivery', status: 'pending', paymentStatus: 'Unpaid',
    total: 1600, createdAt: DateTime(2026, 9, 29, 18, 5),
    lines: const [CustomerOrderLine(name: 'Chicken Fry', qty: 2, total: 1600)],
  ),
  CustomerOrder(
    id: 'o1', number: '#1003', type: 'Takeaway', status: 'completed', paymentStatus: 'Paid',
    total: 1200, createdAt: DateTime(2026, 9, 28, 20, 30),
    lines: const [CustomerOrderLine(name: 'Chicken Pizza (Large)', qty: 1, total: 1200)],
  ),
];

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<ProviderContainer> pumpShell(WidgetTester tester, Size size, {User? user}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // No Supabase in tests: serve a fixed menu and signed-in state.
    final container = ProviderContainer(overrides: [
      customerMenuProvider.overrideWith((_) async => _menu),
      customerUserProvider.overrideWith((_) => Stream.value(user)),
      myOrdersProvider.overrideWith((_) => Stream.value(user == null ? null : _orders)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: CustomerShell()),
    ));
    await tester.pump();
    await tester.pump();
    return container;
  }

  /// Scrolls every visible scrollable to the end so every section lays out.
  Future<void> scrollThrough(WidgetTester tester) async {
    final scrollable = find.byType(Scrollable).hitTestable();
    for (var i = 0; i < 30; i++) {
      if (scrollable.evaluate().isEmpty) break;
      await tester.drag(scrollable.first, const Offset(0, -400));
      await tester.pump();
    }
  }

  for (final size in const [Size(360, 740), Size(1400, 900)]) {
    for (final user in [null, _customer]) {
      testWidgets('all tabs lay out without overflow at $size (${user == null ? 'guest' : 'signed in'})',
          (tester) async {
        final container = await pumpShell(tester, size, user: user);
        container.read(cartProvider.notifier).add(_pizza, _pizza.options.last);

        for (final tab in CustomerTab.values) {
          container.read(customerTabProvider.notifier).state = tab;
          await tester.pump();
          await scrollThrough(tester);
        }
        // Fonts can't load offline in tests; ignore that, fail on anything else.
        final e = tester.takeException();
        expect(e == null || '$e'.contains('GoogleFonts') || '$e'.contains('font'), isTrue, reason: '$e');
      });
    }
  }

  testWidgets('guests must log in before ordering', (tester) async {
    final container = await pumpShell(tester, const Size(1400, 900));
    container.read(cartProvider.notifier).add(_fries, _fries.options.first);
    container.read(customerTabProvider.notifier).state = CustomerTab.cart;
    await tester.pump();

    expect(find.text('Login to Order'), findsOneWidget);
    expect(find.text('Place Order'), findsNothing);

    // The home marquee animates forever, so pump a fixed duration instead of settling.
    await tester.tap(find.text('Login to Order'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('signed-in customers get a prefilled details form', (tester) async {
    final container = await pumpShell(tester, const Size(1400, 900), user: _customer);
    container.read(cartProvider.notifier).add(_fries, _fries.options.first);
    container.read(customerTabProvider.notifier).state = CustomerTab.cart;
    await tester.pump();

    expect(find.text('Place Order'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Ali Khan'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '03001234567'), findsOneWidget);
  });

  testWidgets('My Orders asks guests to log in', (tester) async {
    final container = await pumpShell(tester, const Size(1400, 900));
    container.read(customerTabProvider.notifier).state = CustomerTab.orders;
    await tester.pump();
    await tester.pump();

    expect(find.text('Log in to see your orders'), findsOneWidget);
  });

  testWidgets('My Orders splits open and past orders with their status', (tester) async {
    final container = await pumpShell(tester, const Size(1400, 900), user: _customer);
    container.read(customerTabProvider.notifier).state = CustomerTab.orders;
    await tester.pump();
    await tester.pump();

    // Filter tabs show their count in a separate badge.
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Order history'), findsOneWidget);
    // Open order: live card with its progress steps.
    expect(find.text('Order #1004'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('Chicken Fry'), findsOneWidget);
    // Past order: in the history list with its final status ("Completed" is also a filter tab).
    expect(find.text('Order #1003'), findsOneWidget);
    expect(find.text('Completed'), findsNWidgets(2));
    expect(find.text('1 item · Chicken Pizza (Large)'), findsOneWidget);
  });

  test('menu item rows map to dishes, sizes sorted', () {
    final plain = Dish.fromMenuItemJson({
      'id': 'a', 'name': 'Chicken Fry', 'price': 800, 'category_id': 'c', 'image_url': null,
      'menu_item_sizes': [],
    });
    expect(plain.options.single.price, 800);
    expect(plain.hasOptions, isFalse);
    expect(plain.image, '');

    final sized = Dish.fromMenuItemJson({
      'id': 'b', 'name': 'Pizza', 'price': 650, 'category_id': 'c',
      'menu_item_sizes': [
        {'name': 'Large', 'price': 1200, 'sort_order': 2},
        {'name': 'Small', 'price': 650, 'sort_order': 0},
      ],
    });
    expect(sized.options.map((o) => o.label), ['Small', 'Large']);
    expect(sized.fromPrice, 650);
    expect(formatPrice(1200), '£1,200.00');
    expect(formatPrice(8.5), '£8.50');
  });

  test('cart merges same dish + option and removes at qty 0', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final cart = c.read(cartProvider.notifier);

    cart.add(_pizza, _pizza.options.first);
    cart.add(_pizza, _pizza.options.first, qty: 2);
    cart.add(_pizza, _pizza.options.last);
    expect(c.read(cartProvider).length, 2);
    expect(c.read(cartCountProvider), 4);
    expect(c.read(cartSubtotalProvider), 11 * 3 + 14);

    cart.setQty(c.read(cartProvider).first.key, 0);
    expect(c.read(cartProvider).length, 1);
  });
}
