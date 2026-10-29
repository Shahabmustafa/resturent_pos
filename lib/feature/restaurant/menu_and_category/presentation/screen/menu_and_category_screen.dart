import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resturent_application/feature/restaurant/menu_and_category/presentation/widget/deals_tab_widget.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/model/menu_model.dart';
import '../provider/menu_provider.dart';
import '../widget/categories_tab_widget.dart';
import '../widget/menu_skeleton.dart';
import '../widget/menu_dialog_widgets.dart';
import '../widget/menu_items_tab_widget.dart';
import 'package:resturent_application/feature/restaurant/pos_and_order/presentation/widget/till_dialog.dart';

class MenuManagementPage extends ConsumerStatefulWidget {
  const MenuManagementPage({super.key});

  @override
  ConsumerState<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends ConsumerState<MenuManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String? _filterCatId;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(menuProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SvgIcon(
              AppIcons.errorOutlineRounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SvgIcon(
              AppIcons.checkCircleOutlineRounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(msg, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openCatDialog([MenuCategory? existing]) => showDialog(
    context: context,
    builder: (_) => CategoryDialog(
      existing: existing,
      onSave: (cat) async {
        final err = existing == null
            ? await ref.read(menuProvider.notifier).addCategory(cat)
            : await ref.read(menuProvider.notifier).updateCategory(cat);
        if (err != null)
          _showError(err);
        else
          _showSuccess(
            existing == null ? 'Category added' : 'Category updated',
          );
      },
    ),
  );

  void _openItemDialog([MenuItem? existing]) => showDialog(
    context: context,
    builder: (_) => MenuItemDialog(
      existing: existing,
      onSave: (item, newImages, removedUrls) async {
        final err = existing == null
            ? await ref
                  .read(menuProvider.notifier)
                  .addMenuItem(item, newImages: newImages)
            : await ref
                  .read(menuProvider.notifier)
                  .updateMenuItem(
                    item,
                    newImages: newImages,
                    removedUrls: removedUrls,
                  );
        if (err != null)
          _showError(err);
        else
          _showSuccess(
            existing == null ? '${item.name} added' : '${item.name} updated',
          );
      },
    ),
  );

  void _openDealDialog([Deal? existing]) => showDialog(
    context: context,
    builder: (_) => DealDialog(
      existing: existing,
      onSave: (deal) async {
        final err = existing == null
            ? await ref.read(menuProvider.notifier).addDeal(deal)
            : await ref.read(menuProvider.notifier).updateDeal(deal);
        if (err != null)
          _showError(err);
        else
          _showSuccess(
            existing == null ? '${deal.name} added' : '${deal.name} updated',
          );
      },
    ),
  );

  void _confirmDelete(String msg, VoidCallback onConfirm) => showDialog(
    context: context,
    builder: (_) => TillDialog(
      title: 'Delete?',
      width: 460,
      child: Text(msg, style: const TextStyle(fontSize: 15, color: kText)),
      actions: [
        TillButton.cancel(onTap: () => Navigator.pop(context)),
        TillButton(
          label: 'DELETE',
          icon: AppIcons.deleteOutlineRounded,
          color: const Color(0xFFD9534F),
          onTap: () {
            Navigator.pop(context);
            onConfirm();
          },
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(menuProvider);
    final notifier = ref.read(menuProvider.notifier);
    final loading = state.status == MenuStatus.loading;

    final tabs = [
      ('Categories', AppIcons.categoryRounded, state.categories.length),
      ('Menu Items', AppIcons.fastfoodRounded, state.menuItems.length),
      ('Deals', AppIcons.localOfferRounded, state.deals.length),
    ];
    final add = [
      () => _openCatDialog(),
      () => _openItemDialog(),
      () => _openDealDialog(),
    ][_tab.index];

    return Scaffold(
      backgroundColor: _tillBg,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++) ...[
                  _TillTab(
                    label: loading
                        ? tabs[i].$1
                        : '${tabs[i].$1} (${tabs[i].$3})',
                    icon: tabs[i].$2,
                    active: _tab.index == i,
                    onTap: () => _tab.animateTo(i),
                  ),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                _TillTab(
                  label: 'ADD ${_TopBar._labels[_tab.index].toUpperCase()}',
                  icon: AppIcons.addRounded,
                  active: true,
                  color: const Color(0xFF5CB85C),
                  onTap: add,
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (state.status) {
              MenuStatus.loading => MenuBodySkeleton(tabIndex: _tab.index),
              MenuStatus.error => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SvgIcon(
                      AppIcons.errorOutlineRounded,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.error ?? 'Unknown error',
                      style: const TextStyle(color: kSub),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: notifier.loadAll,
                      icon: const SvgIcon(AppIcons.refreshRounded, size: 18),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              _ => TabBarView(
                controller: _tab,
                children: [
                  CategoriesTabWidget(
                    categories: state.categories,
                    menuItems: state.menuItems,
                    onEdit: _openCatDialog,
                    onDelete: (cat) => _confirmDelete(
                      'Delete "${cat.name}"? All its items will also be removed.',
                      () async {
                        final err = await notifier.deleteCategory(cat.id);
                        if (err != null) _showError(err);
                      },
                    ),
                  ),
                  MenuItemsTabWidget(
                    items: notifier.itemsByCategory(_filterCatId),
                    allItems: state.menuItems,
                    categories: state.categories,
                    selectedCatId: _filterCatId,
                    onFilterChanged: (id) => setState(() => _filterCatId = id),
                    catName: notifier.catNameOf,
                    catColor: notifier.catColorOf,
                    onEdit: _openItemDialog,
                    onDelete: (item) =>
                        _confirmDelete('Delete "${item.name}"?', () async {
                          final err = await notifier.deleteMenuItem(item);
                          if (err != null) _showError(err);
                        }),
                    onToggle: notifier.toggleMenuItem,
                  ),
                  DealsTabWidget(
                    deals: state.deals,
                    menuItems: state.menuItems,
                    onEdit: _openDealDialog,
                    onDelete: (deal) =>
                        _confirmDelete('Delete "${deal.name}"?', () async {
                          final err = await notifier.deleteDeal(deal.id);
                          if (err != null) _showError(err);
                        }),
                    onToggle: notifier.toggleDeal,
                  ),
                ],
              ),
            },
          ),
        ],
      ),
    );
  }
}

const _tillBg = Color(0xFFD4D4D2);
const _tillPurple = Color(0xFF9B51B8);

class _TopBar {
  static const _labels = ['Category', 'Menu Item', 'Deal'];
}

/// Flat till-style tab / action key.
class _TillTab extends StatelessWidget {
  final String label;
  final AppIcon icon;
  final bool active;
  final Color? color;
  final VoidCallback onTap;
  const _TillTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: active ? (color ?? _tillPurple) : Colors.white,
    elevation: 1,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 200,
        height: 46,
        child: Row(
          children: [
            const SizedBox(width: 14),
            SvgIcon(
              icon,
              size: 20,
              color: active ? Colors.white : Colors.black87,
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: active ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    ),
  );
}
