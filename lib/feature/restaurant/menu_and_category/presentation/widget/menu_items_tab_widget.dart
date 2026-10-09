import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/model/menu_model.dart';
import 'package:resturent_application/core/constants/currency.dart';

class MenuItemsTabWidget extends StatefulWidget {
  final List<MenuItem> items, allItems;
  final List<MenuCategory> categories;
  final String? selectedCatId;
  final ValueChanged<String?> onFilterChanged;
  final String Function(String?) catName;
  final Color Function(String?) catColor;
  final ValueChanged<MenuItem> onEdit, onDelete, onToggle;

  const MenuItemsTabWidget({
    super.key, required this.items, required this.allItems, required this.categories,
    required this.selectedCatId, required this.onFilterChanged, required this.catName,
    required this.catColor, required this.onEdit, required this.onDelete, required this.onToggle,
  });

  @override
  State<MenuItemsTabWidget> createState() => _MenuItemsTabWidgetState();
}

class _MenuItemsTabWidgetState extends State<MenuItemsTabWidget> {
  String _query = '';

  static const _cardHeight = 292.0;
  static const _gap = 16.0;

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty ? widget.items : widget.items.where((i) => i.name.toLowerCase().contains(q)).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // ── Filters: categories on the left, search on the right ──
      Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
        decoration: const BoxDecoration(color: kCard, border: Border(bottom: BorderSide(color: kBorder))),
        child: Row(children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _Chip(
                  label: 'All',
                  count: widget.allItems.length,
                  color: kPrimary,
                  isSelected: widget.selectedCatId == null,
                  onTap: () => widget.onFilterChanged(null),
                ),
                for (final c in widget.categories)
                  _Chip(
                    label: c.name,
                    count: widget.allItems.where((i) => i.categoryId == c.id).length,
                    color: c.color,
                    isSelected: widget.selectedCatId == c.id,
                    onTap: () => widget.onFilterChanged(c.id),
                  ),
              ]),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(width: 240, child: _SearchField(onChanged: (v) => setState(() => _query = v))),
        ]),
      ),

      // ── Grid ──
      Expanded(
        child: items.isEmpty
            ? _Empty(
                label: q.isNotEmpty ? 'No items match "$_query"' : 'No items yet',
                sub: q.isNotEmpty ? 'Try a different name' : 'Tap "Add Menu Item" to create one')
            : LayoutBuilder(builder: (context, c) {
                const pad = 24.0;
                final width = c.maxWidth - pad * 2;
                final cols = ((width + _gap) / (230 + _gap)).floor().clamp(1, 6);
                final cardWidth = (width - _gap * (cols - 1)) / cols;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(pad),
                  child: Wrap(
                    spacing: _gap,
                    runSpacing: _gap,
                    children: [
                      for (final item in items)
                        SizedBox(
                          width: cardWidth,
                          height: _cardHeight,
                          child: MenuItemCardWidget(
                            item: item,
                            catName: widget.catName(item.categoryId),
                            catColor: widget.catColor(item.categoryId),
                            onEdit: widget.onEdit,
                            onDelete: widget.onDelete,
                            onToggle: widget.onToggle,
                          ),
                        ),
                    ],
                  ),
                );
              }),
      ),
    ]);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.count, required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Material(
      color: isSelected ? kText : kLight,
      shape: StadiumBorder(side: BorderSide(color: isSelected ? kText : kBorder)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 7),
            Text(label,
                style: TextStyle(
                    fontSize: 13, color: isSelected ? Colors.white : kSub, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.18) : kBorder,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : kMuted)),
            ),
          ]),
        ),
      ),
    ),
  );
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    style: const TextStyle(fontSize: 13, color: kText),
    decoration: InputDecoration(
      isDense: true,
      hintText: 'Search items…',
      hintStyle: const TextStyle(color: kMuted, fontSize: 13),
      prefixIcon: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: SvgIcon(AppIcons.searchRounded, size: 17, color: kMuted),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 36),
      filled: true,
      fillColor: kLight,
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimary, width: 1.5)),
    ),
  );
}

class MenuItemCardWidget extends StatelessWidget {
  final MenuItem item;
  final String catName;
  final Color catColor;
  final ValueChanged<MenuItem> onEdit, onDelete, onToggle;

  const MenuItemCardWidget({
    super.key, required this.item, required this.catName,
    required this.catColor, required this.onEdit, required this.onDelete, required this.onToggle,
  });

  static const _imageHeight = 138.0;

  @override
  Widget build(BuildContext context) {
    final hasImage = item.imageUrl?.isNotEmpty ?? false;
    final sizes = [...item.sizes]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Material(
      color: kCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: item.isAvailable ? kBorder : Colors.redAccent.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onEdit(item),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ── Photo (or placeholder) with badges ──
          SizedBox(
            height: _imageHeight,
            child: Stack(fit: StackFit.expand, children: [
              hasImage
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, prog) => prog == null ? child : Container(color: kLight),
                      errorBuilder: (_, _, _) => _Placeholder(catColor: catColor, item: item),
                    )
                  : _Placeholder(catColor: catColor, item: item),
              if (!item.isAvailable)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  alignment: Alignment.center,
                  child: const Text('Unavailable',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: .3)),
                ),
              Positioned(top: 10, left: 10, child: _CatBadge(label: catName, color: catColor)),
              Positioned(top: 8, right: 8, child: _Toggle(item: item, onToggle: onToggle)),
              if (item.imageUrls.length > 1)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _Badge(icon: AppIcons.addPhotoAlternateRounded, label: '${item.imageUrls.length}'),
                ),
            ]),
          ),

          // ── Details ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: item.isAvailable ? kText : kMuted)),
                const SizedBox(height: 3),
                Text(_priceLabel(sizes),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kPrimary)),
                const SizedBox(height: 8),
                if (sizes.length > 1) _SizesLine(sizes: sizes),
                const Spacer(),
                Row(children: [
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kText,
                          side: const BorderSide(color: kBorder),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        ),
                        onPressed: () => onEdit(item),
                        icon: const SvgIcon(AppIcons.editRounded, size: 14, color: kSub),
                        label: const Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Delete',
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.05),
                          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.25)),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        ),
                        onPressed: () => onDelete(item),
                        child: const SvgIcon(AppIcons.deleteOutlineRounded, size: 16, color: Colors.redAccent),
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  String _priceLabel(List<ItemSize> sizes) {
    if (sizes.isEmpty) return formatMoney(item.price);
    final prices = sizes.map((s) => s.price).toList()..sort();
    final min = prices.first, max = prices.last;
    return min == max ? formatMoney(min) : '${formatMoney(min)} – ${max.toStringAsFixed(0)}';
  }
}

/// "Small 650" chips on one line; whatever doesn't fit collapses into "+N".
class _SizesLine extends StatelessWidget {
  final List<ItemSize> sizes;
  const _SizesLine({required this.sizes});

  static const _style = TextStyle(fontSize: 10.5, color: kSub, fontWeight: FontWeight.w600);

  static double _chipWidth(String text) {
    final painter = TextPainter(text: TextSpan(text: text, style: _style), textDirection: TextDirection.ltr)..layout();
    return painter.width + 14 + 2 + 5; // padding + border + gap
  }

  @override
  Widget build(BuildContext context) {
    final labels = [for (final s in sizes) '${s.name} ${s.price.toStringAsFixed(0)}'];
    return LayoutBuilder(builder: (context, c) {
      var used = 0.0;
      var shown = 0;
      for (var i = 0; i < labels.length; i++) {
        final w = _chipWidth(labels[i]);
        final reserve = i == labels.length - 1 ? 0.0 : _chipWidth('+${labels.length - i - 1}');
        if (used + w + reserve > c.maxWidth) break;
        used += w;
        shown++;
      }
      Widget chip(String text) => Container(
        margin: const EdgeInsets.only(right: 5),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: kLight, borderRadius: BorderRadius.circular(6), border: Border.all(color: kBorder)),
        child: Text(text, style: _style),
      );
      return Row(children: [
        for (final l in labels.take(shown)) chip(l),
        if (shown < labels.length) chip('+${labels.length - shown}'),
      ]);
    });
  }
}

class _CatBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _CatBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 1))],
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: kText, fontSize: 10.5, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _Badge extends StatelessWidget {
  final AppIcon icon;
  final String label;
  const _Badge({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      SvgIcon(icon, size: 11, color: Colors.white),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _Toggle extends StatelessWidget {
  final MenuItem item;
  final ValueChanged<MenuItem> onToggle;
  const _Toggle({required this.item, required this.onToggle});
  @override
  Widget build(BuildContext context) => Tooltip(
    message: item.isAvailable ? 'Available — tap to hide' : 'Hidden — tap to make available',
    child: GestureDetector(
      onTap: () => onToggle(item),
      child: Container(
        width: 36, height: 20,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: item.isAvailable ? kGreen : const Color(0xFFB0B3C6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: item.isAvailable ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(width: 13, height: 13, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
        ),
      ),
    ),
  );
}

class _Placeholder extends StatelessWidget {
  final Color catColor;
  final MenuItem item;
  const _Placeholder({required this.catColor, required this.item});

  AppIcon get _icon {
    final n = item.name.toLowerCase();
    if (n.contains('pizza')) return AppIcons.localPizzaRounded;
    if (n.contains('burger')) return AppIcons.lunchDiningRounded;
    if (n.contains('drink') || n.contains('cola') || n.contains('pepsi') || n.contains('juice')) return AppIcons.localDrinkRounded;
    if (n.contains('chicken') || n.contains('fry') || n.contains('wing')) return AppIcons.setMealRounded;
    if (n.contains('rice') || n.contains('biryani')) return AppIcons.riceBowlRounded;
    if (n.contains('cake') || n.contains('dessert')) return AppIcons.cakeRounded;
    return AppIcons.fastfoodRounded;
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [catColor.withValues(alpha: 0.10), catColor.withValues(alpha: 0.22)],
      ),
    ),
    child: Center(child: SvgIcon(_icon, size: 40, color: catColor.withValues(alpha: 0.55))),
  );
}

class _Empty extends StatelessWidget {
  final String label, sub;
  const _Empty({required this.label, required this.sub});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      SvgIcon(AppIcons.menuBookOutlined, size: 40, color: kMuted.withValues(alpha: 0.6)),
      const SizedBox(height: 12),
      Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
      const SizedBox(height: 4),
      Text(sub, style: const TextStyle(fontSize: 13, color: kMuted)),
    ]),
  );
}
