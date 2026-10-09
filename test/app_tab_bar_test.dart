import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/app_tab_bar.dart';

const _items = [
  AppTabItem('Categories', icon: AppIcons.categoryRounded, count: 12),
  AppTabItem('Menu Items', icon: AppIcons.fastfoodRounded, count: 148),
  AppTabItem('Deals', icon: AppIcons.localOfferRounded, count: 3),
];

Widget _host(Widget child, {double width = 800}) => MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: width, child: child))),
    );

class _ControllerHost extends StatefulWidget {
  final void Function(TabController) onReady;
  final bool expand;
  const _ControllerHost({required this.onReady, this.expand = true});
  @override
  State<_ControllerHost> createState() => _ControllerHostState();
}

class _ControllerHostState extends State<_ControllerHost> with SingleTickerProviderStateMixin {
  late final _c = TabController(length: _items.length, vsync: this);
  @override
  void initState() {
    super.initState();
    widget.onReady(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AppTabBar(controller: _c, items: _items, expand: widget.expand);
}

void main() {
  testWidgets('index mode reports the tapped tab', (tester) async {
    int? tapped;
    await tester.pumpWidget(_host(AppTabBar(items: _items, index: 0, onChanged: (i) => tapped = i)));
    await tester.tap(find.text('Menu Items'));
    expect(tapped, 1);
  });

  testWidgets('controller mode switches the controller and shows counts', (tester) async {
    late TabController c;
    await tester.pumpWidget(_host(_ControllerHost(onReady: (v) => c = v)));
    expect(find.text('148'), findsOneWidget);
    await tester.tap(find.text('Deals'));
    await tester.pumpAndSettle();
    expect(c.index, 2);
  });

  testWidgets('does not overflow on a narrow expanded bar', (tester) async {
    await tester.pumpWidget(_host(AppTabBar(items: _items, onChanged: (_) {}), width: 320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-expanded bar scrolls instead of overflowing', (tester) async {
    late TabController c;
    await tester.pumpWidget(_host(_ControllerHost(onReady: (v) => c = v, expand: false), width: 220));
    expect(tester.takeException(), isNull);
    expect(c.index, 0);
  });
}
