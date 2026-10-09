import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:resturent_application/feature/restaurant/menu_and_category/data/model/menu_model.dart';
import 'package:resturent_application/feature/restaurant/menu_and_category/presentation/provider/menu_provider.dart';
import 'package:resturent_application/feature/restaurant/menu_and_category/presentation/widget/menu_dialog_widgets.dart';

/// Serves one category without touching Supabase.
class _FakeMenuNotifier extends MenuNotifier {
  _FakeMenuNotifier() : super(branchId: 'branch') {
    state = MenuState(
      status: MenuStatus.success,
      categories: [MenuCategory(id: 'c1', branchId: 'branch', name: 'Pizza', description: '')],
    );
  }

  @override
  Future<void> loadAll() async {}
}

typedef _Saved = ({MenuItem item, List<PickedImage> newImages, List<String> removedUrls});

Future<List<_Saved>> _openDialog(WidgetTester tester, {MenuItem? existing}) async {
  tester.view.physicalSize = const Size(1200, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final saved = <_Saved>[];
  await tester.pumpWidget(ProviderScope(
    overrides: [menuProvider.overrideWith((ref) => _FakeMenuNotifier())],
    child: MaterialApp(
      home: Scaffold(
        body: MenuItemDialog(
          existing: existing,
          onSave: (item, newImages, removedUrls) =>
              saved.add((item: item, newImages: newImages, removedUrls: removedUrls)),
        ),
      ),
    ),
  ));
  await tester.pump();
  return saved;
}

bool _saveEnabled(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Save Item')).onPressed != null;

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-key',
      authOptions: FlutterAuthClientOptions(localStorage: const EmptyLocalStorage()),
    );
  });

  testWidgets('new item form has only images, name, category and sizes', (tester) async {
    await _openDialog(tester);

    expect(find.text('Images'), findsOneWidget);
    expect(find.text('Item Name *'), findsOneWidget);
    expect(find.text('Category *'), findsOneWidget);
    expect(find.text('Sizes & Prices *'), findsOneWidget);
    // Small and Large are prefilled, prices still empty.
    expect(find.widgetWithText(TextField, 'Small'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Large'), findsOneWidget);

    expect(find.textContaining('Cost'), findsNothing);
    expect(find.textContaining('Margin'), findsNothing);
    expect(find.textContaining('Ingredient'), findsNothing);
    expect(_saveEnabled(tester), isFalse);
  });

  testWidgets('every size needs a price before saving', (tester) async {
    final saved = await _openDialog(tester, existing: MenuItem(
      id: 'i1', branchId: 'branch', name: 'Chicken Pizza', price: 650, costPrice: 300, categoryId: 'c1',
      sizes: [ItemSize.temp(name: 'Small', price: 650), ItemSize.temp(name: 'Large', price: 1200, sortOrder: 1)],
    ));
    expect(_saveEnabled(tester), isTrue);

    await tester.enterText(find.widgetWithText(TextField, '1200'), '');
    await tester.pump();
    expect(_saveEnabled(tester), isFalse);

    await tester.enterText(find.widgetWithText(TextField, '8.50').last, '1500');
    await tester.pump();
    await tester.tap(find.text('Save Item'));
    await tester.pump();

    final item = saved.single.item;
    expect(item.sizes.map((s) => (s.name, s.price)), [('Small', 650.0), ('Large', 1500.0)]);
    expect(item.price, 650, reason: 'base price is the cheapest size');
    expect(item.costPrice, 300, reason: 'existing cost is kept even though the field is gone');
  });

  testWidgets('an item without sizes opens with its price as one size', (tester) async {
    await _openDialog(tester, existing: MenuItem(
      id: 'i2', branchId: 'branch', name: 'Chicken Fry', price: 800, costPrice: 0, categoryId: 'c1',
    ));
    expect(find.widgetWithText(TextField, 'Regular'), findsOneWidget);
    expect(find.widgetWithText(TextField, '800'), findsOneWidget);
    expect(_saveEnabled(tester), isTrue);
  });

  testWidgets('removing a photo reports it and moves the cover', (tester) async {
    final saved = await _openDialog(tester, existing: MenuItem(
      id: 'i3', branchId: 'branch', name: 'Burger', price: 500, costPrice: 0, categoryId: 'c1',
      imageUrl: 'https://img/a.jpg', imageUrls: ['https://img/a.jpg', 'https://img/b.jpg'],
      sizes: [ItemSize.temp(name: 'Regular', price: 500)],
    ));
    expect(find.text('Cover'), findsOneWidget);

    // Remove the first (cover) photo.
    await tester.tap(find.byType(InkWell).at(0));
    await tester.pump();
    await tester.tap(find.text('Save Item'));
    await tester.pump();

    final s = saved.single;
    expect(s.removedUrls, ['https://img/a.jpg']);
    expect(s.item.imageUrls, ['https://img/b.jpg']);
    expect(s.item.imageUrl, 'https://img/b.jpg');
    expect(s.newImages, isEmpty);
  });
}
