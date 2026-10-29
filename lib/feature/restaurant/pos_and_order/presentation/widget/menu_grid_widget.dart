import 'package:flutter/material.dart';
import 'package:resturent_application/core/constants/currency.dart';
import '../../data/model/order_model.dart';

const _bg = Color(0xFF2F6FD6);
const _dealsId = '__deals__';

// Till colours per category position: (item tile, category button). The menu's
// own category colours are all red shades, which are too alike to tell apart here.
const _palette = [
  (Color(0xFF1E3A9E), Color(0xFFBFD7F5)),
  (Color(0xFFB23A2E), Color(0xFFF6C6C0)),
  (Color(0xFF2E7D4F), Color(0xFFC8EBC9)),
  (Color(0xFF6A3FA0), Color(0xFFDCCBF0)),
  (Color(0xFF00796B), Color(0xFFB9E6E0)),
  (Color(0xFFC0570F), Color(0xFFF9D5B5)),
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

  const MenuGridWidget({
    super.key,
    required this.products,
    required this.deals,
    required this.categories,
    required this.onAddToCart,
    this.isLoading = false,
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
    final tabs = _tabs;
    final selected =
        tabs.where((c) => c.id == _categoryId).firstOrNull ?? tabs.firstOrNull;
    final items = selected == null
        ? widget.products
        : selected.id == _dealsId
        ? widget.deals
        : widget.products.where((p) => p.categoryId == selected.id).toList();
    final tileColor =
        _palette[(selected == null ? 0 : tabs.indexOf(selected)) %
                _palette.length]
            .$1;

    return Container(
      color: _bg,
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
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 150,
                          mainAxisExtent: 92,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _ItemTile(
                      product: items[i],
                      color: tileColor,
                      onTap: () => widget.onAddToCart(items[i]),
                    ),
                  ),
          ),
          if (tabs.isNotEmpty)
            Container(
              width: double.infinity,
              color: const Color(0xFF2A62C0),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (i, c) in tabs.indexed)
                    _CategoryButton(
                      label: c.name,
                      color: _palette[i % _palette.length].$2,
                      selected: c.id == selected?.id,
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
  final VoidCallback onTap;
  const _ItemTile({
    required this.product,
    required this.color,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      shadows: hasImage ? shadow : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatMoney(price).replaceAll('£', ''),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: hasImage ? shadow : null,
                    ),
                  ),
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
  final VoidCallback onTap;
  const _CategoryButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    elevation: selected ? 0 : 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(3),
      side: selected
          ? const BorderSide(color: Color(0xFF1B2A4A), width: 2.5)
          : BorderSide.none,
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(3),
      onTap: onTap,
      child: Container(
        width: 140,
        height: 54,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}
