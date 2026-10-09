import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';

void main() {
  Future<Size> iconSize(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: child))));
    await tester.pumpAndSettle();
    return tester.getSize(find.byType(SvgPicture));
  }

  testWidgets('keeps its size inside a larger tight box (like Icon)', (tester) async {
    final size = await iconSize(
      tester,
      Container(width: 40, height: 40, child: const SvgIcon(AppIcons.add, size: 18)),
    );
    expect(size, const Size(18, 18));
  });

  testWidgets('defaults to 24 and follows IconTheme', (tester) async {
    expect(await iconSize(tester, const SvgIcon(AppIcons.add)), const Size(24, 24));
    expect(
      await iconSize(tester, const IconTheme(data: IconThemeData(size: 16), child: SvgIcon(AppIcons.add))),
      const Size(16, 16),
    );
  });
}
