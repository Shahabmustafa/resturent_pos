import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/model/menu_model.dart';

class CategoriesTabWidget extends StatelessWidget {
  final List<MenuCategory> categories;
  final List<MenuItem> menuItems;
  final ValueChanged<MenuCategory> onEdit, onDelete;
  const CategoriesTabWidget({super.key, required this.categories, required this.menuItems, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const _Empty(label: 'No categories yet', sub: 'Add your first category');
    return LayoutBuilder(builder: (context, c) {
      const pad = 24.0, gap = 16.0;
      final width = c.maxWidth - pad * 2;
      final cols = ((width + gap) / (300 + gap)).floor().clamp(1, 5);
      final cardWidth = (width - gap * (cols - 1)) / cols;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(pad),
        child: Wrap(spacing: gap, runSpacing: gap, children: [
          for (final cat in categories)
            SizedBox(
              width: cardWidth,
              height: 148,
              child: _CategoryCard(
                cat: cat,
                items: menuItems.where((m) => m.categoryId == cat.id).toList(),
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ),
        ]),
      );
    });
  }
}

class _CategoryCard extends StatelessWidget {
  final MenuCategory cat;
  final List<MenuItem> items;
  final ValueChanged<MenuCategory> onEdit, onDelete;
  const _CategoryCard({required this.cat, required this.items, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = cat.color;
    final photos = [for (final i in items) if (i.imageUrl?.isNotEmpty ?? false) i.imageUrl!];
    final count = items.length;

    return Material(
      color: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: kBorder)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onEdit(cat),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 5, color: c),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: SvgIcon(AppIcons.categoryRounded, size: 19, color: c),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(cat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kText)),
                      Text('$count ${count == 1 ? 'item' : 'items'}',
                          style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  _IconBtn(icon: AppIcons.editOutlined, color: kSub, tooltip: 'Edit', onTap: () => onEdit(cat)),
                  _IconBtn(
                      icon: AppIcons.deleteOutlineRounded,
                      color: Colors.redAccent,
                      tooltip: 'Delete',
                      onTap: () => onDelete(cat)),
                ]),
                const SizedBox(height: 10),
                Text(cat.description.isEmpty ? 'No description' : cat.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: cat.description.isEmpty ? kMuted : kSub)),
                const Spacer(),
                _Thumbs(photos: photos, count: count, color: c),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Overlapping round photos of the category's items, plus "+N".
class _Thumbs extends StatelessWidget {
  final List<String> photos;
  final int count;
  final Color color;
  const _Thumbs({required this.photos, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const Text('No items in this category yet', style: TextStyle(fontSize: 12, color: kMuted));
    }
    const size = 34.0, step = 24.0;
    final shown = photos.take(4).toList();
    final extra = count - shown.length;
    final slots = shown.length + (extra > 0 ? 1 : 0);
    Widget circle(Widget child) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
    return SizedBox(
      height: size,
      width: slots == 0 ? 0 : size + step * (slots - 1),
      child: Stack(children: [
        for (var i = 0; i < shown.length; i++)
          Positioned(
            left: step * i,
            child: circle(Image.network(shown[i], fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox())),
          ),
        if (extra > 0)
          Positioned(
            left: step * shown.length,
            child: circle(Center(
              child: Text('+$extra', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
            )),
          ),
      ]),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final AppIcon icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    icon: SvgIcon(icon, size: 17, color: color),
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    splashRadius: 18,
  );
}

class _Empty extends StatelessWidget {
  final String label, sub;
  const _Empty({required this.label, required this.sub});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      SvgIcon(AppIcons.categoryOutlined, size: 40, color: kMuted.withValues(alpha: 0.6)),
      const SizedBox(height: 12),
      Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
      const SizedBox(height: 4),
      Text(sub, style: const TextStyle(fontSize: 13, color: kMuted)),
    ]),
  );
}