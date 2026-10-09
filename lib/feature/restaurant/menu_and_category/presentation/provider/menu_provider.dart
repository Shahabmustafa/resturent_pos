import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../auth/presentation/provider/branch_auth_provider.dart';
import '../../data/datasource/menu_datasource.dart';
import '../../data/model/menu_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum MenuStatus { initial, loading, success, error }

class MenuState {
  final MenuStatus status;
  final String? error;
  final List<MenuCategory> categories;
  final List<MenuItem> menuItems;
  final List<Deal> deals;

  const MenuState({
    this.status = MenuStatus.initial,
    this.error,
    this.categories = const [],
    this.menuItems = const [],
    this.deals = const [],
  });

  MenuState copyWith({
    MenuStatus? status,
    String? error,
    List<MenuCategory>? categories,
    List<MenuItem>? menuItems,
    List<Deal>? deals,
  }) =>
      MenuState(
        status: status ?? this.status,
        error: error ?? this.error,
        categories: categories ?? this.categories,
        menuItems: menuItems ?? this.menuItems,
        deals: deals ?? this.deals,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class MenuNotifier extends StateNotifier<MenuState> {
  final MenuRemoteDatasource _ds;

  MenuNotifier({required String branchId})
      : _ds = MenuRemoteDatasource(branchId: branchId),
        super(const MenuState());

  Future<void> loadAll() async {
    state = state.copyWith(status: MenuStatus.loading, error: null);
    try {
      final results = await Future.wait([
        _ds.fetchCategories(),
        _ds.fetchMenuItems(),
        _ds.fetchDeals(),
      ]);
      state = state.copyWith(
        status: MenuStatus.success,
        categories: results[0] as List<MenuCategory>,
        menuItems: results[1] as List<MenuItem>,
        deals: results[2] as List<Deal>,
      );
    } catch (e) {
      state = state.copyWith(status: MenuStatus.error, error: _parseError(e));
    }
  }

  // ── CATEGORIES ──────────────────────────────────────────────────────────────
  Future<String?> addCategory(MenuCategory cat) async {
    try {
      final saved = await _ds.insertCategory(cat);
      state = state.copyWith(
          status: MenuStatus.success,
          categories: [...state.categories, saved]);
      return null;
    } catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(error: msg);
      return msg;
    }
  }

  Future<String?> updateCategory(MenuCategory cat) async {
    try {
      await _ds.updateCategory(cat);
      state = state.copyWith(
          categories:
          state.categories.map((c) => c.id == cat.id ? cat : c).toList());
      return null;
    } catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(error: msg);
      return msg;
    }
  }

  Future<String?> deleteCategory(String id) async {
    try {
      await _ds.deleteCategory(id);
      state = state.copyWith(
        categories: state.categories.where((c) => c.id != id).toList(),
        menuItems: state.menuItems.where((m) => m.categoryId != id).toList(),
      );
      return null;
    } catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(error: msg);
      return msg;
    }
  }

  // ── MENU ITEMS ──────────────────────────────────────────────────────────────
  /// Uploads [images] and returns their public URLs, in order.
  Future<List<String>> _uploadImages(List<PickedImage> images) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return [
      for (var i = 0; i < images.length; i++)
        await _ds.uploadMenuImageBytes(
          images[i].bytes,
          '${stamp}_$i.${images[i].mimeType == 'image/png' ? 'png' : 'jpg'}',
          images[i].mimeType,
        ),
    ];
  }

  /// Appends uploaded [newImages] to the item's photos; the first photo is the cover.
  Future<void> _attachImages(MenuItem item, List<PickedImage> newImages) async {
    item.imageUrls = [...item.imageUrls, ...await _uploadImages(newImages)];
    item.imageUrl = item.imageUrls.isEmpty ? null : item.imageUrls.first;
  }

  Future<String?> addMenuItem(MenuItem item, {List<PickedImage> newImages = const []}) async {
    try {
      await _attachImages(item, newImages);
      final saved = await _ds.insertMenuItem(item);
      state = state.copyWith(
          status: MenuStatus.success,
          menuItems: [...state.menuItems, saved]);
      return null;
    } catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(error: msg);
      return msg;
    }
  }

  /// [removedUrls] are photos the user took off the item; they are deleted from
  /// storage once the item is saved.
  Future<String?> updateMenuItem(MenuItem item,
      {List<PickedImage> newImages = const [], List<String> removedUrls = const []}) async {
    try {
      await _attachImages(item, newImages);
      await _ds.updateMenuItem(item);
      for (final url in removedUrls) {
        await _ds.deleteMenuImage(url);
      }
      state = state.copyWith(
          menuItems:
          state.menuItems.map((m) => m.id == item.id ? item : m).toList());
      return null;
    } catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(error: msg);
      return msg;
    }
  }

  Future<String?> deleteMenuItem(MenuItem item) async {
    try {
      await _ds.deleteMenuItem(item.id);
      for (final url in {...item.imageUrls, if (item.imageUrl?.isNotEmpty ?? false) item.imageUrl!}) {
        await _ds.deleteMenuImage(url);
      }
      state = state.copyWith(
          menuItems: state.menuItems.where((m) => m.id != item.id).toList());
      return null;
    } catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(error: msg);
      return msg;
    }
  }

  Future<void> toggleMenuItem(MenuItem item) async {
    final newVal = !item.isAvailable;
    final updated = state.menuItems.map((m) {
      if (m.id != item.id) return m;
      m.isAvailable = newVal;
      return m;
    }).toList();
    state = state.copyWith(menuItems: updated);
    try {
      await _ds.toggleMenuItem(item.id, newVal);
    } catch (e) {
      // revert
      final reverted = state.menuItems.map((m) {
        if (m.id != item.id) return m;
        m.isAvailable = item.isAvailable;
        return m;
      }).toList();
      state = state.copyWith(menuItems: reverted, error: _parseError(e));
    }
  }

  // ── DEALS ────────────────────────────────────────────────────────────────────
  Future<String?> addDeal(Deal deal) async {
    try {
      final saved = await _ds.insertDeal(deal);
      state = state.copyWith(
          status: MenuStatus.success, deals: [...state.deals, saved]);
      return null;
    } catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(error: msg);
      return msg;
    }
  }

  Future<String?> updateDeal(Deal deal) async {
    try {
      await _ds.updateDeal(deal);
      state = state.copyWith(
          deals: state.deals.map((d) => d.id == deal.id ? deal : d).toList());
      return null;
    } catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(error: msg);
      return msg;
    }
  }

  Future<String?> deleteDeal(String id) async {
    try {
      await _ds.deleteDeal(id);
      state = state.copyWith(
          deals: state.deals.where((d) => d.id != id).toList());
      return null;
    } catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(error: msg);
      return msg;
    }
  }

  Future<void> toggleDeal(Deal deal) async {
    final newVal = !deal.isAvailable;
    final updated = state.deals.map((d) {
      if (d.id != deal.id) return d;
      d.isAvailable = newVal;
      return d;
    }).toList();
    state = state.copyWith(deals: updated);
    try {
      await _ds.toggleDeal(deal.id, newVal);
    } catch (e) {
      final reverted = state.deals.map((d) {
        if (d.id != deal.id) return d;
        d.isAvailable = deal.isAvailable;
        return d;
      }).toList();
      state = state.copyWith(deals: reverted, error: _parseError(e));
    }
  }

  // ── Computed helpers ─────────────────────────────────────────────────────────
  List<MenuItem> itemsByCategory(String? catId) => catId == null
      ? state.menuItems
      : state.menuItems.where((m) => m.categoryId == catId).toList();

  String catNameOf(String? id) => state.categories
      .firstWhere((c) => c.id == id,
      orElse: () =>
          MenuCategory(id: '', branchId: '', name: '—', description: ''))
      .name;

  Color catColorOf(String? id) {
    final idx = state.categories.indexWhere((c) => c.id == id);
    return categoryShadeAt(idx < 0 ? 0 : idx);
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('42501')) return 'Permission denied — check RLS policies in Supabase';
    if (msg.contains('23503')) return 'Foreign key error — category or branch missing';
    if (msg.contains('23505')) return 'Duplicate entry — already exists';
    if (msg.contains('branchId is empty')) return 'Session expired — please login again';
    if (msg.contains('SocketException') || msg.contains('Network')) return 'Network error — check internet';
    return msg;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  final branch = ref.watch(branchAuthProvider).branch;
  return MenuNotifier(branchId: branch?.branchId ?? '');
});