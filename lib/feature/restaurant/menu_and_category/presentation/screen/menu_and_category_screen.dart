import 'package:resturent_application/core/widget/stat_card.dart';
import 'package:resturent_application/core/widget/app_tab_bar.dart';
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const SvgIcon(AppIcons.errorOutlineRounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
      ]),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const SvgIcon(AppIcons.checkCircleOutlineRounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Text(msg, style: const TextStyle(color: Colors.white)),
      ]),
      backgroundColor: kGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  void _openCatDialog([MenuCategory? existing]) => showDialog(
    context: context,
    builder: (_) => CategoryDialog(
      existing: existing,
      onSave: (cat) async {
        final err = existing == null
            ? await ref.read(menuProvider.notifier).addCategory(cat)
            : await ref.read(menuProvider.notifier).updateCategory(cat);
        if (err != null) _showError(err);
        else _showSuccess(existing == null ? 'Category added' : 'Category updated');
      },
    ),
  );

  void _openItemDialog([MenuItem? existing]) => showDialog(
    context: context,
    builder: (_) => MenuItemDialog(
      existing: existing,
      onSave: (item, newImages, removedUrls) async {
        final err = existing == null
            ? await ref.read(menuProvider.notifier).addMenuItem(item, newImages: newImages)
            : await ref.read(menuProvider.notifier)
                .updateMenuItem(item, newImages: newImages, removedUrls: removedUrls);
        if (err != null) _showError(err);
        else _showSuccess(existing == null ? '${item.name} added' : '${item.name} updated');
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
        if (err != null) _showError(err);
        else _showSuccess(existing == null ? '${deal.name} added' : '${deal.name} updated');
      },
    ),
  );

  void _confirmDelete(String msg, VoidCallback onConfirm) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete?',
          style: TextStyle(color: kText, fontWeight: FontWeight.w800)),
      content: Text(msg, style: const TextStyle(color: kSub)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kMuted))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () { Navigator.pop(context); onConfirm(); },
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(menuProvider);
    final notifier = ref.read(menuProvider.notifier);
    final loading = state.status == MenuStatus.loading;

    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        _TopBar(
          tabIndex: _tab.index,
          onAdd: [
                () => _openCatDialog(),
                () => _openItemDialog(),
                () => _openDealDialog(),
          ][_tab.index],
        ),
        loading
            ? const MenuStatsStripSkeleton()
            : _StatsStrip(state: state),
        Container(
          color: kCard,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
          child: AppTabBar(
            controller: _tab,
            items: [
              AppTabItem('Categories', icon: AppIcons.categoryRounded, count: loading ? null : state.categories.length),
              AppTabItem('Menu Items', icon: AppIcons.fastfoodRounded, count: loading ? null : state.menuItems.length),
              AppTabItem('Deals', icon: AppIcons.localOfferRounded, count: loading ? null : state.deals.length),
            ],
          ),
        ),
        Expanded(
          child: switch (state.status) {
            MenuStatus.loading => MenuBodySkeleton(tabIndex: _tab.index),
            MenuStatus.error => Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SvgIcon(AppIcons.errorOutlineRounded, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(state.error ?? 'Unknown error',
                      style: const TextStyle(color: kSub), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary, foregroundColor: Colors.white),
                    onPressed: notifier.loadAll,
                    icon: const SvgIcon(AppIcons.refreshRounded, size: 18),
                    label: const Text('Retry'),
                  ),
                ])),
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
                  onDelete: (item) => _confirmDelete(
                    'Delete "${item.name}"?',
                        () async {
                      final err = await notifier.deleteMenuItem(item);
                      if (err != null) _showError(err);
                    },
                  ),
                  onToggle: notifier.toggleMenuItem,
                ),
                DealsTabWidget(
                  deals: state.deals,
                  menuItems: state.menuItems,
                  onEdit: _openDealDialog,
                  onDelete: (deal) => _confirmDelete(
                    'Delete "${deal.name}"?',
                        () async {
                      final err = await notifier.deleteDeal(deal.id);
                      if (err != null) _showError(err);
                    },
                  ),
                  onToggle: notifier.toggleDeal,
                ),
              ],
            ),
          },
        ),
      ]),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int tabIndex;
  final VoidCallback onAdd;
  const _TopBar({required this.tabIndex, required this.onAdd});
  static const _labels = ['Category', 'Menu Item', 'Deal'];

  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: const BoxDecoration(
      color: kCard,
      border: Border(bottom: BorderSide(color: kBorder)),
      boxShadow: [BoxShadow(color: Color(0x08000020), blurRadius: 8, offset: Offset(0, 2))],
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: const SvgIcon(AppIcons.menuBookRounded, color: kPrimary, size: 22),
      ),
      const SizedBox(width: 12),
      const Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Menu & Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kText)),
        Text('Manage items, categories and deals', style: TextStyle(fontSize: 11, color: kMuted)),
      ]),
      const Spacer(),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onAdd,
        icon: const SvgIcon(AppIcons.addRounded, size: 18),
        label: Text('Add ${_labels[tabIndex]}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    ]),
  );
}

// ── Stats Strip ───────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final MenuState state;
  const _StatsStrip({required this.state});

  @override
  Widget build(BuildContext context) {
    final available = state.menuItems.where((i) => i.isAvailable).length;

    return Container(
      color: kCard,
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
      child: StatCardRow(cards: [
        StatCardData(AppIcons.categoryRounded,    'Categories', '${state.categories.length}', kBlue),
        StatCardData(AppIcons.fastfoodRounded,    'Menu Items', '${state.menuItems.length}',  kPrimary),
        StatCardData(AppIcons.checkCircleRounded, 'Available',  '$available',                 kGreen),
        StatCardData(AppIcons.localOfferRounded,  'Deals',      '${state.deals.length}',      kYellow),
      ]),
    );
  }
}