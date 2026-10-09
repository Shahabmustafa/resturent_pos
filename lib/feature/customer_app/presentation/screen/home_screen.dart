import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import '../../data/customer_datasource.dart';
import '../../data/menu_data.dart';
import '../../data/model/dish_model.dart';
import '../provider/customer_providers.dart';
import '../provider/navigation_provider.dart';
import '../theme/customer_theme.dart';
import '../widget/customer_widgets.dart';
import '../widget/depth_effects.dart';
import '../widget/dish_card.dart';
import '../widget/feedback_widgets.dart';
import '../widget/reveal.dart';

const _maxContentWidth = 1260.0;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void openMenu([String? categoryId]) {
      if (categoryId != null) ref.read(menuCategoryProvider.notifier).state = categoryId;
      ref.read(customerTabProvider.notifier).state = CustomerTab.menu;
    }

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _Hero(wide: wide, onOrder: openMenu),
            _Section(
              child: _ExploreMenu(wide: wide, onCategory: openMenu),
            ),
            _SignatureDish(wide: wide, onOrder: openMenu),
            _Section(
              background: CColors.paper,
              child: _HotSelling(wide: wide, onSeeAll: openMenu),
            ),
            const _StatsBand(),
            _Section(child: _About(wide: wide)),
            _Section(child: _WhyUs(wide: wide)),
            _Reviews(wide: wide),
            _HoursCta(wide: wide, onOrder: openMenu),
            const CustomerFooter(),
          ],
        );
      },
    );
  }
}

/// Centers content at the site's max width with its side gutter.
class _Section extends StatelessWidget {
  final Widget child;
  final Color? background;
  final bool reveal; // fade the content in when it scrolls into view

  const _Section({required this.child, this.background, this.reveal = true});

  @override
  Widget build(BuildContext context) {
    final gutter = MediaQuery.sizeOf(context).width < 640 ? 20.0 : 28.0;
    return Container(
      color: background,
      padding: EdgeInsets.symmetric(horizontal: gutter, vertical: 56),
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: reveal ? Reveal(rotateX: 3, fromScale: 0.98, child: child) : child,
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────
/// Hero photos that cross-fade every few seconds; the dots jump to a photo.
class _HeroSlider extends StatefulWidget {
  const _HeroSlider();

  @override
  State<_HeroSlider> createState() => _HeroSliderState();
}

class _HeroSliderState extends State<_HeroSlider> {
  static const _interval = Duration(seconds: 4);
  final _images = MenuData.heroImages;
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load every photo up front so the next slide doesn't flash a placeholder.
    for (final image in _images) {
      precacheImage(AssetImage(image), context);
    }
  }

  /// (Re)starts the timer, so a dot tap gets a full interval before moving on.
  void _restart() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => setState(() => _index = (_index + 1) % _images.length));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 900),
          child: FoodImage(_images[_index], key: ValueKey(_index)),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _images.length; i++)
                GestureDetector(
                  onTap: () {
                    setState(() => _index = i);
                    _restart();
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index ? Colors.white : Colors.white.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 4)],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final bool wide;
  final VoidCallback onOrder;

  const _Hero({required this.wide, required this.onOrder});

  @override
  Widget build(BuildContext context) {
    // Hero copy enters line by line on page load.
    var step = 0;
    Widget enter(Widget w) => EntranceFade(
      delay: Duration(milliseconds: 110 * step++),
      child: w,
    );

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        enter(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: CColors.paper,
              borderRadius: BorderRadius.circular(30),
              boxShadow: CShadows.soft,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SvgIcon(AppIcons.starRounded, size: 15, color: CColors.gold),
                const SizedBox(width: 7),
                Text(
                  'Walton Road, Woking',
                  style: CText.body(12.5, color: CColors.inkSoft, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        enter(
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: "Woking's Favourite "),
                TextSpan(
                  text: 'Pak-Afghan',
                  style: CText.display(wide ? 60 : 38, color: CColors.rust, style: FontStyle.italic),
                ),
                const TextSpan(text: ' Restaurant'),
              ],
            ),
            style: CText.display(wide ? 60 : 38),
          ),
        ),
        const SizedBox(height: 18),
        enter(Text('Bold Flavours, Cooked Fresh Daily.', style: CText.body(17.5, color: CColors.muted, height: 1.6))),
        const SizedBox(height: 30),
        if (wide)
          enter(
            Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                PillButton(label: 'Order Online Now', icon: AppIcons.arrowForwardRounded, onPressed: onOrder),
                PillButton(label: 'View Our Menu', style: PillStyle.outlineDark, onPressed: onOrder),
              ],
            ),
          )
        else
          // Full-width stacked buttons are easier to hit and line up on phones.
          enter(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PillButton(
                  label: 'Order Online Now',
                  icon: AppIcons.arrowForwardRounded,
                  expand: true,
                  onPressed: onOrder,
                ),
                const SizedBox(height: 12),
                PillButton(label: 'View Our Menu', style: PillStyle.outlineDark, expand: true, onPressed: onOrder),
              ],
            ),
          ),
        const SizedBox(height: 34),
        enter(
          Wrap(
            spacing: 22,
            runSpacing: 14,
            children: const [
              _Trust(AppIcons.deliveryDiningRounded, '30-Min Delivery'),
              _Trust(AppIcons.shieldRounded, '100% Halal'),
              _Trust(AppIcons.emojiEventsRounded, 'Weddings & Parties'),
            ],
          ),
        ),
      ],
    );

    final visual = SizedBox(
      height: wide ? 520 : 360,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            right: 0,
            left: wide ? 70 : 24,
            bottom: 0,
            child: EntranceFade(
              delay: const Duration(milliseconds: 150),
              offsetY: 0,
              fromScale: 0.94,
              child: FloatSway(
                child: ParallaxLayer(
                  depth: 16,
                  tilt: 8,
                  child: const _HeroSlider(),
                  // The shadow drifts opposite the pointer, as if the plate is lifted toward it.
                  builder: (context, p, child) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x381A140F),
                          blurRadius: 64,
                          offset: Offset(-p.dx * 22, 30 - p.dy * 12),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: CColors.cream,
        gradient: RadialGradient(
          center: Alignment(0.76, -0.84),
          radius: 1.1,
          colors: [Color(0x29C68A2E), Color(0x00F8F2E6)],
        ),
      ),
      child: PointerParallax(
        child: Stack(
          children: [
            Positioned(
              top: -180,
              right: -180,
              child: ParallaxLayer(depth: 6, child: _Ring(520, CColors.gold.withValues(alpha: .25))),
            ),
            Positioned(
              top: -120,
              right: -120,
              child: ParallaxLayer(depth: 10, child: _Ring(340, CColors.rust.withValues(alpha: .15))),
            ),
            _Section(
              reveal: false, // the hero has its own entrance animation
              child: wide
                  ? Row(
                      children: [
                        Expanded(child: copy),
                        const SizedBox(width: 60),
                        Expanded(child: visual),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [copy, const SizedBox(height: 44), visual],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double size;
  final Color color;

  const _Ring(this.size, this.color);

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color),
    ),
  );
}

class _Trust extends StatelessWidget {
  final AppIcon icon;
  final String label;

  const _Trust(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconBadge(icon, size: 34),
        const SizedBox(width: 10),
        Text(
          label,
          style: CText.body(13.5, color: CColors.inkSoft, weight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ── Signature menu (dishes of the signature category) ─────────────────────────
class _ExploreMenu extends ConsumerWidget {
  final bool wide;
  final ValueChanged<String> onCategory;

  const _ExploreMenu({required this.wide, required this.onCategory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(customerMenuProvider);
    final menu = menuAsync.value;
    final dishes = menu?.dishes.where((d) => d.isSignature).toList() ?? const <Dish>[];
    // "See all" opens the category the signature dishes belong to.
    final categoryId = dishes.isEmpty ? null : dishes.first.categoryId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          eyebrow: 'Our Menus',
          title: 'Signature Menu',
          subtitle: 'Our Pak Afghan signature dishes — made fresh when you order.',
        ),
        const SizedBox(height: 30),
        if (menuAsync.hasError && menu == null)
          MenuStatus.error(error: '${menuAsync.error}', onRetry: () => ref.invalidate(customerMenuProvider))
        else if (menuAsync.isLoading && menu == null)
          const MenuStatus.loading()
        else if (dishes.isEmpty)
          const MenuStatus.empty('Signature dishes are coming soon.')
        else ...[
          DishGrid(dishes: dishes, shrinkWrap: true),
          const SizedBox(height: 28),
          Center(
            child: PillButton(
              label: 'See All Signature Dishes',
              style: PillStyle.outlineDark,
              icon: AppIcons.arrowForwardRounded,
              onPressed: () => onCategory(categoryId!),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Signature dish spotlight ──────────────────────────────────────────────────
class _SignatureDish extends StatelessWidget {
  final bool wide;
  final VoidCallback onOrder;

  const _SignatureDish({required this.wide, required this.onOrder});

  @override
  Widget build(BuildContext context) {
    final image = ScrollDepth(
      rotateX: 6,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: CColors.gold.withValues(alpha: .5), width: 1.5),
          ),
          padding: const EdgeInsets.all(14),
          child: ClipOval(child: ScrollDepth(spin: 10, child: FoodImage(MenuData.signatureImage))),
        ),
      ),
    );

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Woking’s Fresh Shawarma & Grilled Favourites',
          subtitle:
              'Enjoy delicious chicken and lamb shawarma, freshly prepared wraps, and sizzling shish kebabs. '
              'Packed with bold flavours, crisp salads, and tasty sauces—perfect for your next bite.',
          light: true,
        ),
        const SizedBox(height: 24),
        PillButton(
          label: 'See Full Menu',
          style: PillStyle.gold,
          icon: AppIcons.arrowForwardRounded,
          onPressed: onOrder,
        ),
      ],
    );

    return Container(
      color: CColors.ink,
      child: _Section(
        child: wide
            ? Row(
                children: [
                  SizedBox(width: 420, child: image),
                  const SizedBox(width: 60),
                  Expanded(child: copy),
                ],
              )
            : Column(
                children: [
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 30), child: image),
                  const SizedBox(height: 36),
                  copy,
                ],
              ),
      ),
    );
  }
}

// ── Stats band ────────────────────────────────────────────────────────────────
class _StatsBand extends ConsumerWidget {
  const _StatsBand();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemCount = ref.watch(customerMenuProvider).value?.dishes.length;
    final stats = [
      (itemCount == null ? '—' : '$itemCount', 'Menu items'),
      ('Fresh', 'Cooked to order'),
      ('100%', 'Halal'),
      ('7', 'Days a week'),
    ];
    return Container(
      decoration: const BoxDecoration(gradient: CColors.goldGradient),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runSpacing: 20,
        children: [
          for (final (value, label) in stats)
            SizedBox(
              width: 150,
              child: Column(
                children: [
                  Text(value, style: CText.display(34)),
                  const SizedBox(height: 2),
                  Text(
                    label.toUpperCase(),
                    style: CText.body(
                      11.5,
                      color: CColors.inkSoft,
                      weight: FontWeight.w600,
                    ).copyWith(letterSpacing: 1.4),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── About ─────────────────────────────────────────────────────────────────────
class _About extends StatelessWidget {
  final bool wide;

  const _About({required this.wide});

  @override
  Widget build(BuildContext context) {
    final images = SizedBox(
      height: wide ? 440 : 300,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: ScrollDepth(
              shiftY: -10,
              rotateX: 4,
              child: ClipRRect(borderRadius: BorderRadius.circular(22), child: FoodImage(MenuData.aboutImages[0])),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ScrollDepth(
              shiftY: 14,
              rotateX: -3,
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: FoodImage(MenuData.aboutImages[1]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: FoodImage(MenuData.aboutImages[2]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          eyebrow: 'About Us',
          title: 'Authentic Taste, Crafted with Love & Tradition',
          subtitle:
              'From smoky Peshawari Chapli Kabab to slow-simmered Nihari, every dish is cooked '
              'fresh in our Woking kitchen using 100% halal ingredients and recipes passed down '
              'through generations.',
        ),
        const SizedBox(height: 22),
        for (final t in const [
          'Traditional Pakistani & Afghan recipes',
          'Catering for weddings & parties',
          'Breakfast every Fri – Sun',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const SvgIcon(AppIcons.checkCircleRounded, size: 20, color: CColors.olive),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(t, style: CText.body(14.5, weight: FontWeight.w500)),
                ),
              ],
            ),
          ),
      ],
    );

    return wide
        ? Row(
            children: [
              Expanded(child: images),
              const SizedBox(width: 60),
              Expanded(child: copy),
            ],
          )
        : Column(children: [copy, const SizedBox(height: 30), images]);
  }
}

// ── Hot selling dishes ────────────────────────────────────────────────────────
class _HotSelling extends ConsumerStatefulWidget {
  final bool wide;
  final VoidCallback onSeeAll;

  const _HotSelling({required this.wide, required this.onSeeAll});

  @override
  ConsumerState<_HotSelling> createState() => _HotSellingState();
}

class _HotSellingState extends ConsumerState<_HotSelling> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final menu = ref.watch(customerMenuProvider).value;
    if (menu == null || menu.categories.isEmpty) return const SizedBox.shrink();

    final category = menu.category(_category) ?? menu.categories.first;
    // Up to 16 dishes: 4 rows on desktop before the "See Full Menu" button.
    final dishes = menu.byCategory(category.id).take(16).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          eyebrow: 'Order Online',
          title: 'Fresh From Our Kitchen',
          subtitle: 'Tap a category, add your favourites to the cart and order in a minute.',
          align: CrossAxisAlignment.center,
        ),
        const SizedBox(height: 26),
        CategoryChips(
          categories: menu.categories,
          selected: category.id,
          onSelected: (id) => setState(() => _category = id),
        ),
        const SizedBox(height: 24),
        DishGrid(dishes: dishes, shrinkWrap: true),
        const SizedBox(height: 28),
        Center(
          child: PillButton(
            label: 'See Full Menu',
            style: PillStyle.outlineDark,
            icon: AppIcons.arrowForwardRounded,
            onPressed: widget.onSeeAll,
          ),
        ),
      ],
    );
  }
}

/// Horizontal category pill tabs shared by Home and Menu.
/// With [showAll], an "All" chip comes first and a null [selected] means All.
class CategoryChips extends StatelessWidget {
  final List<MenuCategory> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final bool showAll;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    this.showAll = false,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <(String?, String, String)>[
      if (showAll) (null, 'All', ''),
      for (final c in categories) (c.id, c.name, c.image),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final (id, name, image) = chips[i];
          final active = id == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () => onSelected(id),
            child: AnimatedContainer(
              duration: Duration.zero,
              padding: EdgeInsets.fromLTRB(id == null || image.isEmpty ? 18 : 5, 5, 18, 5),
              decoration: BoxDecoration(
                color: active ? CColors.ink : CColors.paper,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: active ? CColors.ink : CColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (id == null)
                    SvgIcon(AppIcons.menuBookRounded, size: 17, color: active ? CColors.goldLight : CColors.rust)
                  else if (image.isNotEmpty)
                    ClipOval(child: SizedBox(width: 32, height: 32, child: FoodImage(image)))
                  else
                    SvgIcon(AppIcons.restaurantRounded, size: 17, color: active ? CColors.goldLight : CColors.rust),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: CText.body(13.5, color: active ? Colors.white : CColors.ink, weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Responsive dish grid: 2 columns on phones, up to 4 on wide screens.
class DishGrid extends StatelessWidget {
  final List<Dish> dishes;
  final bool shrinkWrap;
  final EdgeInsets padding;

  const DishGrid({super.key, required this.dishes, this.shrinkWrap = false, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 14.0;
        // ~175px per card: 4 columns from ~700px wide, 3 on small tablets, 2 on phones.
        final cols = (c.maxWidth / 175).floor().clamp(2, 4);
        final cellWidth = (c.maxWidth - gap * (cols - 1)) / cols;
        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
          padding: padding,
          itemCount: dishes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            // Image scales with the card; the text block below it is fixed height.
            mainAxisExtent: cellWidth * 0.8 + 150,
          ),
          // Keyed by dish so cards animate in again when the category changes.
          itemBuilder: (_, i) => Reveal(
            key: ValueKey(dishes[i].id),
            delay: Duration(milliseconds: 80 * (i % cols)),
            child: DishCard(dish: dishes[i]),
          ),
        );
      },
    );
  }
}

// ── Why choose us ─────────────────────────────────────────────────────────────
class _WhyUs extends StatelessWidget {
  final bool wide;

  const _WhyUs({required this.wide});

  static const _items = [
    (
      AppIcons.soupKitchenRounded,
      'Cooked Fresh Daily',
      'Every order is prepared fresh when you place it — nothing sits under a heat lamp.',
    ),
    (AppIcons.deliveryDiningRounded, '30-Min Delivery Promise', 'Hot food at your door across Woking, fast.'),
    (AppIcons.setMealRounded, 'Generous Portions', 'Proper Pak-Afghan portions made for sharing — or not.'),
  ];

  @override
  Widget build(BuildContext context) {
    final cards = [
      for (final (icon, title, body) in _items)
        Tilt3D(
          maxTilt: 6,
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: CColors.paper,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: CColors.line),
              boxShadow: CShadows.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(gradient: CColors.goldGradient, borderRadius: BorderRadius.circular(16)),
                  alignment: Alignment.center,
                  child: SvgIcon(icon, size: 24, color: CColors.ink),
                ),
                const SizedBox(height: 18),
                Text(title, style: CText.display(20)),
                const SizedBox(height: 8),
                Text(body, style: CText.body(14, color: CColors.muted, height: 1.6)),
              ],
            ),
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          eyebrow: 'Why Choose Us',
          title: 'Why Pak Afghan & Woking Shawarma',
          align: CrossAxisAlignment.center,
        ),
        const SizedBox(height: 30),
        if (wide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 18),
                  Expanded(
                    child: Reveal(
                      delay: Duration(milliseconds: 120 * i),
                      child: cards[i],
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          for (final card in cards)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Reveal(child: card),
            ),
      ],
    );
  }
}

// ── Customer reviews ──────────────────────────────────────────────────────────
/// Ratings customers left on completed orders. Hidden until there is at least one.
class _Reviews extends ConsumerWidget {
  final bool wide;

  const _Reviews({required this.wide});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(publicFeedbackProvider).value;
    if (summary == null || summary.count == 0) return const SizedBox.shrink();

    return _Section(
      background: CColors.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(eyebrow: 'Reviews', title: 'What Our Customers Say', align: CrossAxisAlignment.center),
          const SizedBox(height: 14),
          Center(
            child: Wrap(
              spacing: 10,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(summary.average.toStringAsFixed(1), style: CText.display(28)),
                StarRow(rating: summary.average.round(), size: 20),
                Text(
                  'from ${summary.count} ${summary.count == 1 ? 'rating' : 'ratings'}',
                  style: CText.body(14, color: CColors.muted),
                ),
              ],
            ),
          ),
          if (summary.latest.isNotEmpty) ...[
            const SizedBox(height: 30),
            LayoutBuilder(
              builder: (context, c) {
                const gap = 18.0;
                final cols = wide ? 3 : (c.maxWidth >= 560 ? 2 : 1);
                final width = (c.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (var i = 0; i < summary.latest.length; i++)
                      SizedBox(
                        width: width,
                        child: Reveal(
                          delay: Duration(milliseconds: 100 * (i % cols)),
                          child: Tilt3D(maxTilt: 5, child: _ReviewCard(feedback: summary.latest[i])),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final PublicFeedback feedback;

  const _ReviewCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: CColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StarRow(rating: feedback.rating),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              '“${feedback.comment}”',
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: CText.body(14, color: CColors.text, height: 1.6),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: CColors.goldPale,
                child: Text(
                  feedback.name.isEmpty ? '?' : feedback.name[0].toUpperCase(),
                  style: CText.body(14, color: CColors.rustDeep, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  feedback.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CText.body(14, color: CColors.ink, weight: FontWeight.w600),
                ),
              ),
              Text(DateFormat('d MMM yyyy').format(feedback.createdAt), style: CText.body(12, color: CColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── CTA + opening hours ───────────────────────────────────────────────────────
class _HoursCta extends StatelessWidget {
  final bool wide;
  final VoidCallback onOrder;

  const _HoursCta({required this.wide, required this.onOrder});

  @override
  Widget build(BuildContext context) {
    final cta = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hungry? We\'re cooking right now.', style: CText.display(wide ? 40 : 30, color: Colors.white)),
        const SizedBox(height: 12),
        Text(
          'Order online for delivery across Woking or collect from Walton Road.',
          style: CText.body(15, color: CColors.goldPale, height: 1.6),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            PillButton(label: 'Order Online Now', style: PillStyle.gold, onPressed: onOrder),
            PillButton(
              label: 'Call ${MenuData.phone}',
              style: PillStyle.outlineLight,
              onPressed: () => copyToClipboard(context, MenuData.phone, 'Phone number'),
            ),
          ],
        ),
      ],
    );

    final hours = Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: CColors.paper,
        borderRadius: BorderRadius.circular(20),
        boxShadow: CShadows.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(AppIcons.accessTimeRounded, size: 40, background: CColors.cream),
              const SizedBox(width: 12),
              Expanded(child: Text('Opening Hours', style: CText.display(22))),
            ],
          ),
          const SizedBox(height: 18),
          const OpeningHours(),
        ],
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CColors.rust, CColors.rustDeep],
        ),
      ),
      child: _Section(
        background: Colors.transparent,
        child: wide
            ? Row(
                children: [
                  Expanded(child: cta),
                  const SizedBox(width: 60),
                  SizedBox(width: 400, child: hours),
                ],
              )
            : Column(children: [cta, const SizedBox(height: 30), hours]),
      ),
    );
  }
}

/// Hours as set in the POS (Settings → Company → Working hours).
class OpeningHours extends ConsumerWidget {
  const OpeningHours({super.key});

  /// (day, time) rows for [hours]; a placeholder while they load.
  static List<(String, String)> rowsFor(OpeningHoursInfo? hours) => [
    ('Monday – Sunday', hours == null ? '…' : hours.range),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = rowsFor(ref.watch(openingHoursProvider).value);
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(color: CColors.line, height: 22),
          Row(
            children: [
              Expanded(
                child: Text(rows[i].$1, style: CText.body(14, color: CColors.muted)),
              ),
              Text(
                rows[i].$2,
                style: CText.body(14, color: CColors.ink, weight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────
class CustomerFooter extends ConsumerWidget {
  const CustomerFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    Widget heading(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(t.toUpperCase(), style: CText.eyebrow(color: CColors.goldLight)),
    );

    Widget row(AppIcon icon, String text, [VoidCallback? onTap]) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgIcon(icon, size: 18, color: CColors.goldLight),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: CText.body(14, color: CColors.mutedLight, height: 1.5)),
            ),
          ],
        ),
      ),
    );

    Widget link(String label, CustomerTab tab) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => ref.read(customerTabProvider.notifier).state = tab,
        child: Text(label, style: CText.body(14, color: CColors.mutedLight)),
      ),
    );

    final brand = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandMark(light: true),
        const SizedBox(height: 16),
        Text(
          'Authentic Pakistani & Afghan food, shawarma and smash burgers — cooked fresh daily in Woking.',
          style: CText.body(14, color: CColors.mutedLight, height: 1.6),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in const ['100% Halal', 'Delivery & Collection', 'Catering'])
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: CColors.inkElev),
                ),
                child: Text(
                  t,
                  style: CText.body(12, color: CColors.goldPale, weight: FontWeight.w500),
                ),
              ),
          ],
        ),
      ],
    );

    final explore = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading('Explore'),
        link('Home', CustomerTab.home),
        link('Our Menu', CustomerTab.menu),
        link('Your Order', CustomerTab.cart),
        link('Contact & Catering', CustomerTab.contact),
      ],
    );

    final visit = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading('Visit Us'),
        row(AppIcons.locationOnOutlined, MenuData.address, () => copyToClipboard(context, MenuData.address, 'Address')),
        row(AppIcons.phoneRounded, MenuData.phone, () => copyToClipboard(context, MenuData.phone, 'Phone number')),
        row(AppIcons.alternateEmailRounded, MenuData.email, () => copyToClipboard(context, MenuData.email, 'Email')),
      ],
    );

    final hours = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading('Hours'),
        for (final (day, time) in OpeningHours.rowsFor(ref.watch(openingHoursProvider).value))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(day, style: CText.body(13, color: CColors.muted)),
                Text(
                  time,
                  style: CText.body(14.5, color: Colors.white, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );

    return Container(
      color: CColors.ink,
      child: _Section(
        background: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: brand),
                  const SizedBox(width: 48),
                  Expanded(flex: 2, child: explore),
                  const SizedBox(width: 32),
                  Expanded(flex: 3, child: visit),
                  const SizedBox(width: 32),
                  Expanded(flex: 2, child: hours),
                ],
              )
            else ...[
              brand,
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: explore),
                  const SizedBox(width: 20),
                  Expanded(child: hours),
                ],
              ),
              const SizedBox(height: 16),
              visit,
            ],
            const SizedBox(height: 22),
            const Divider(color: CColors.inkElev),
            const SizedBox(height: 14),
            SizedBox(
              // Full width so spaceBetween pushes the second line to the right edge.
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text(
                    '© ${DateTime.now().year} Pak Afghan & Woking Shawarma',
                    style: CText.body(12.5, color: CColors.muted),
                  ),
                  Text('Cooked fresh in Woking, Surrey', style: CText.body(12.5, color: CColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo: favicon mark + two-line name.
class BrandMark extends StatelessWidget {
  final bool light;

  const BrandMark({super.key, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: CColors.goldGradient),
          clipBehavior: Clip.antiAlias,
          child: const FoodImage(MenuData.logoImage),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pak Afghan', style: CText.display(18, color: light ? Colors.white : CColors.ink)),
            Text(
              '& WOKING SHAWARMA',
              style: CText.body(
                9.5,
                color: light ? CColors.goldLight : CColors.rust,
                weight: FontWeight.w700,
              ).copyWith(letterSpacing: 1.6),
            ),
          ],
        ),
      ],
    );
  }
}
