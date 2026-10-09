import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import '../../data/customer_datasource.dart';
import '../../data/model/dish_model.dart';
import '../provider/customer_providers.dart';
import '../provider/navigation_provider.dart';
import '../theme/customer_theme.dart';
import '../widget/customer_widgets.dart';
import 'home_screen.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(customerMenuProvider);
    final menu = menuAsync.value;
    final q = _query.trim().toLowerCase();

    // Null = "All": every category as its own section.
    final category = menu?.category(ref.watch(menuCategoryProvider));
    final sections = menu == null ? const <_Section>[] : _sectionsFor(menu, category, q);

    final width = MediaQuery.sizeOf(context).width;
    // Same content column as Home: side gutter, then centred at the max width.
    final minGutter = width < 640 ? 20.0 : 28.0;
    final gutter = ((width - 1260) / 2).clamp(minGutter, double.infinity);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OUR MENU', style: CText.eyebrow()),
                const SizedBox(height: 8),
                Text('What are you craving?', style: CText.display(30)),
                const SizedBox(height: 18),
                // Compact search box; on phones it still fills the width.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    style: CText.body(14.5),
                    decoration: InputDecoration(
                      hintText: 'Search the menu…',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: SvgIcon(AppIcons.searchRounded, size: 20, color: CColors.muted),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 48),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () => setState(() {
                                _search.clear();
                                _query = '';
                              }),
                              icon: const SvgIcon(AppIcons.closeRounded, size: 18, color: CColors.muted),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (menu == null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: menuAsync.hasError
                ? MenuStatus.error(error: '${menuAsync.error}', onRetry: () => ref.invalidate(customerMenuProvider))
                : const MenuStatus.loading(),
          )
        else if (menu.dishes.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: MenuStatus.empty('The menu is empty right now — new items are coming soon.'),
          ),
        // Chips stay pinned while scrolling so switching category is always one tap.
        if (menu != null && menu.categories.isNotEmpty)
          SliverPersistentHeader(
            pinned: true,
            delegate: _ChipsHeader(
              gutter: gutter,
              child: CategoryChips(
                categories: menu.categories,
                showAll: true,
                selected: category?.id,
                onSelected: (id) => ref.read(menuCategoryProvider.notifier).state = id,
              ),
            ),
          ),
        if (menu != null && menu.dishes.isNotEmpty) ...[
          if (sections.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SvgIcon(AppIcons.searchRounded, size: 40, color: CColors.mutedLight),
                    const SizedBox(height: 10),
                    Text('No dishes match "$_query"', style: CText.body(15, color: CColors.muted)),
                  ],
                ),
              ),
            )
          else
            for (final section in sections)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 26),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionHeader(section: section),
                      const SizedBox(height: 16),
                      DishGrid(dishes: section.dishes, shrinkWrap: true),
                    ],
                  ),
                ),
              ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ],
    );
  }
}

class _ChipsHeader extends SliverPersistentHeaderDelegate {
  final double gutter;
  final Widget child;

  const _ChipsHeader({required this.gutter, required this.child});

  static const _height = 72.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return AnimatedContainer(
      duration: Duration.zero,
      decoration: BoxDecoration(
        color: CColors.cream,
        border: Border(bottom: BorderSide(color: overlapsContent ? CColors.line : Colors.transparent)),
      ),
      padding: EdgeInsets.fromLTRB(gutter, 14, gutter, 14),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_ChipsHeader old) => old.gutter != gutter || old.child != child;
}

/// A titled group of dishes on the menu page.
class _Section {
  final String title;
  final String subtitle;
  final List<Dish> dishes;

  const _Section(this.title, this.subtitle, this.dishes);
}

String _countLabel(int n) => '$n ${n == 1 ? 'dish' : 'dishes'}';

/// Search results, one chosen category, or every category (plus uncategorised dishes).
List<_Section> _sectionsFor(CustomerMenu menu, MenuCategory? category, String query) {
  if (query.isNotEmpty) {
    final hits = menu.dishes.where((d) => d.name.toLowerCase().contains(query)).toList();
    return hits.isEmpty ? const [] : [_Section('Search results', _countLabel(hits.length), hits)];
  }
  final cats = category == null ? menu.categories : [category];
  final sections = [
    for (final c in cats)
      if (menu.byCategory(c.id).isNotEmpty) _Section(c.name, _tagline(c), menu.byCategory(c.id)),
  ];
  if (category == null) {
    final known = {for (final c in menu.categories) c.id};
    final other = menu.dishes.where((d) => !known.contains(d.categoryId)).toList();
    if (other.isNotEmpty) sections.add(_Section('More', _countLabel(other.length), other));
  }
  return sections;
}

String _tagline(MenuCategory c) =>
    c.tagline.isEmpty ? _countLabel(c.dishCount) : '${c.tagline} · ${_countLabel(c.dishCount)}';

class _SectionHeader extends StatelessWidget {
  final _Section section;

  const _SectionHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.title, style: CText.display(24)),
            const SizedBox(height: 3),
            Text(section.subtitle, style: CText.body(13, color: CColors.muted)),
          ],
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(height: 1, color: CColors.line),
          ),
        ),
      ],
    );
  }
}
