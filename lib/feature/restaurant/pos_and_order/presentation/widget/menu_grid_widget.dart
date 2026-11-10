import 'package:flutter/material.dart';
import 'package:resturent_application/core/constants/currency.dart';
import 'package:resturent_application/feature/restaurant/setup/pos_setup.dart';
import '../../data/model/order_model.dart';

const _dealsId = '__deals__';

// Till colours per category position: (item tile, category button). The menu's
// own category colours are all red shades, which are too alike to tell apart here.
const _palette = [
  (Color(0xFF1E3A9E), Color(0xFFA8D080)),
  (Color(0xFFB23A2E), Color(0xFF29B6F6)),
  (Color(0xFF2E7D4F), Color(0xFFFFFACD)),
  (Color(0xFF6A3FA0), Color(0xFFBDD330)),
  (Color(0xFF00796B), Color(0xFF9CCC65)),
  (Color(0xFFC0570F), Color(0xFFFFE4EC)),
  (Color(0xFF7A7A1E), Color(0xFFE6E6A8)),
  (Color(0xFF7B4A2E), Color(0xFFE8D2C2)),
];

/// Touch menu: item tiles for the chosen category on top, category buttons
/// along the bottom.
class MenuGridWidget extends StatefulWidget {
  final List<MenuProduct> products;
  final List<MenuProduct> deals;
  final List<PosCategoryModel> categories;
  final ValueChanged<MenuProduct> onAddToCart;
  final bool isLoading;

  /// Text from the till's search box; when set it lists matching items from every category.
  final String query;

  const MenuGridWidget({
    super.key,
    required this.products,
    required this.deals,
    required this.categories,
    required this.onAddToCart,
    this.isLoading = false,
    this.query = '',
  });

  @override
  State<MenuGridWidget> createState() => _MenuGridWidgetState();
}

class _MenuGridWidgetState extends State<MenuGridWidget> {
  String? _categoryId;

  /// Categories that have items, in menu order, plus Deals when there are any.
  List<PosCategoryModel> get _tabs => [
    for (final c in widget.categories)
      if (widget.products.any((p) => p.categoryId == c.id)) c,
    if (widget.deals.isNotEmpty)
      const PosCategoryModel(id: _dealsId, name: 'Deals'),
  ];

  @override
  Widget build(BuildContext context) {
    final setup = readPosSetup(context);
    final tabs = _tabs;
    final selected =
        tabs.where((c) => c.id == _categoryId).firstOrNull ?? tabs.firstOrNull;
    final q = widget.query.trim().toLowerCase();
    final items = q.isNotEmpty
        ? [
            for (final p in [...widget.products, ...widget.deals])
              if (p.name.toLowerCase().contains(q)) p,
          ]
        : selected == null
        ? widget.products
        : selected.id == _dealsId
        ? widget.deals
        : widget.products.where((p) => p.categoryId == selected.id).toList();
    final tileColor =
        _palette[(selected == null ? 0 : tabs.indexOf(selected)) %
                _palette.length]
            .$1;

    return Container(
      color: setup.menuColor,
      child: Column(
        children: [
          Expanded(
            child: widget.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : items.isEmpty
                ? const Center(
                    child: Text(
                      'No items in this category',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: setup.productWidth.toDouble(),
                      mainAxisExtent: setup.productHeight.toDouble(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _ItemTile(
                      product: items[i],
                      color: tileColor,
                      fontSize: setup.productFont.toDouble(),
                      showPrice: !setup.nameOnly,
                      onTap: () => widget.onAddToCart(items[i]),
                    ),
                  ),
          ),
          if (tabs.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
              child: Wrap(
                spacing: 12,
                runSpacing: 14,
                children: [
                  for (final (i, c) in tabs.indexed)
                    _CategoryButton(
                      label: c.name,
                      color: _palette[i % _palette.length].$2,
                      selected: c.id == selected?.id,
                      width: setup.categoryWidth.toDouble(),
                      height: setup.categoryHeight.toDouble(),
                      fontSize: setup.categoryFont.toDouble(),
                      onTap: () => setState(() => _categoryId = c.id),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final MenuProduct product;
  final Color color;
  final double fontSize;
  final bool showPrice;
  final VoidCallback onTap;
  const _ItemTile({
    required this.product,
    required this.color,
    required this.fontSize,
    required this.showPrice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final prices = product.sizes.map((s) => s.price).toList()..sort();
    final price = prices.isNotEmpty ? prices.first : product.price;
    final imageUrl = product.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    const shadow = [Shadow(color: Colors.black87, blurRadius: 4)];
    return Material(
      color: color,
      elevation: 3,
      borderRadius: BorderRadius.circular(3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage) ...[
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
              // Darken the photo so the white name and price stay readable.
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      shadows: hasImage ? shadow : null,
                    ),
                  ),
                  if (showPrice) ...[
                    const SizedBox(height: 4),
                    Text(
                      formatMoney(price).replaceAll('£', ''),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        shadows: hasImage ? shadow : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final double width;
  final double height;
  final double fontSize;
  final VoidCallback onTap;
  const _CategoryButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      boxShadow: [BoxShadow(color: Colors.black87, offset: Offset(3, 3))],
    ),
    child: Material(
      color: color,
      elevation: 0,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
        side: selected
            ? const BorderSide(color: Color(0xFF1F1FC8), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(3),
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF222222),
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    ),
  );
}
