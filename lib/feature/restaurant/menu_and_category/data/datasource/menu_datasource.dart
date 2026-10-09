import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/menu_model.dart';

class MenuRemoteDatasource {
  final _db = Supabase.instance.client;
  final String branchId;

  MenuRemoteDatasource({required this.branchId});

  // ── CATEGORIES ─────────────────────────────────────────────────────────────

  Future<List<MenuCategory>> fetchCategories() async {
    final res = await _db
        .from('categories')
        .select()
        .eq('branch_id', branchId)
        .order('created_at', ascending: true);
    return (res as List).map((j) => MenuCategory.fromJson(j)).toList();
  }

  Future<MenuCategory> insertCategory(MenuCategory cat) async {
    final res = await _db
        .from('categories')
        .insert(cat.toInsert())
        .select()
        .single();
    return MenuCategory.fromJson(res);
  }

  Future<void> updateCategory(MenuCategory cat) async {
    await _db.from('categories').update({
      'name': cat.name,
      'description': cat.description,
      'color_index': cat.colorIndex,
    }).eq('id', cat.id);
  }

  Future<void> deleteCategory(String id) async {
    await _db.from('categories').delete().eq('id', id);
  }

  // ── STOCK ITEMS (for dropdown) ─────────────────────────────────────────────

  Future<List<StockItemRef>> fetchStockItems() async {
    final res = await _db
        .from('stock_items')
        .select('id, name, unit, qty')
        .eq('branch_id', branchId)
        .order('name');
    return (res as List).map((j) => StockItemRef.fromJson(j)).toList();
  }

  // ── INGREDIENTS ────────────────────────────────────────────────────────────

  Future<List<Ingredient>> fetchIngredients(String menuItemId) async {
    final res = await _db
        .from('menu_item_ingredients')
        .select('id, stock_item_id, quantity, stock_items(name, unit)')
        .eq('menu_item_id', menuItemId);

    return (res as List).map((j) {
      final stock = j['stock_items'] as Map<String, dynamic>? ?? {};
      return Ingredient(
        id: j['id'] as String,
        stockItemId: (j['stock_item_id'] as num).toInt(),
        stockItemName: stock['name'] as String? ?? '',
        quantity: (j['quantity'] as num).toDouble(),
        unit: stock['unit'] as String? ?? '',
      );
    }).toList();
  }

  Future<void> saveIngredients(
      String menuItemId, List<Ingredient> ingredients) async {
    await _db
        .from('menu_item_ingredients')
        .delete()
        .eq('menu_item_id', menuItemId);
    if (ingredients.isEmpty) return;
    await _db.from('menu_item_ingredients').insert(
      ingredients.map((i) => i.toInsert(menuItemId, branchId)).toList(),
    );
  }

  // ── MENU ITEMS ─────────────────────────────────────────────────────────────

  Future<List<MenuItem>> fetchMenuItems() async {
    final itemsRes = await _db
        .from('menu_items')
        .select()
        .eq('branch_id', branchId)
        .order('created_at', ascending: true);

    final itemIds =
    (itemsRes as List).map((j) => j['id'] as String).toList();

    Map<String, List<ItemSize>> sizesMap = {};
    Map<String, List<Ingredient>> ingredientsMap = {};

    if (itemIds.isNotEmpty) {
      final sizesRes = await _db
          .from('menu_item_sizes')
          .select()
          .inFilter('menu_item_id', itemIds)
          .order('sort_order');
      for (final row in sizesRes as List) {
        final mid = row['menu_item_id'] as String;
        sizesMap.putIfAbsent(mid, () => []).add(ItemSize.fromJson(row));
      }

      final ingRes = await _db
          .from('menu_item_ingredients')
          .select(
          'id, menu_item_id, stock_item_id, quantity, stock_items(name, unit)')
          .inFilter('menu_item_id', itemIds);
      for (final row in ingRes as List) {
        final mid = row['menu_item_id'] as String;
        final stock = row['stock_items'] as Map<String, dynamic>? ?? {};
        ingredientsMap.putIfAbsent(mid, () => []).add(Ingredient(
          id: row['id'] as String,
          stockItemId: (row['stock_item_id'] as num).toInt(),
          stockItemName: stock['name'] as String? ?? '',
          quantity: (row['quantity'] as num).toDouble(),
          unit: stock['unit'] as String? ?? '',
        ));
      }
    }

    return itemsRes
        .map((j) => MenuItem.fromJson(
      j,
      sizes: sizesMap[j['id']] ?? [],
      ingredients: ingredientsMap[j['id']] ?? [],
    ))
        .toList();
  }

  Future<MenuItem> insertMenuItem(MenuItem item) async {
    if (branchId.isEmpty) throw Exception('branchId is empty — login again');

    final res =
    await _db.from('menu_items').insert(item.toInsert()).select().single();
    final newId = res['id'] as String;

    if (item.sizes.isNotEmpty) {
      await _db.from('menu_item_sizes').insert(
        item.sizes.asMap().entries.map((e) => {
          'menu_item_id': newId,
          'name': e.value.name,
          'price': e.value.price,
          'sort_order': e.key,
        }).toList(),
      );
    }

    if (item.ingredients.isNotEmpty) {
      await saveIngredients(newId, item.ingredients);
    }

    final savedSizes = item.sizes.isNotEmpty
        ? (await _db
        .from('menu_item_sizes')
        .select()
        .eq('menu_item_id', newId)
        .order('sort_order'))
        .map((j) => ItemSize.fromJson(j))
        .toList()
        : <ItemSize>[];

    final savedIngredients = await fetchIngredients(newId);

    return MenuItem.fromJson(res,
        sizes: savedSizes, ingredients: savedIngredients);
  }

  Future<void> updateMenuItem(MenuItem item) async {
    await _db.from('menu_items').update({
      'name': item.name,
      'price': item.price,
      'cost_price': item.costPrice,
      'image_url': item.imageUrl,
      'image_urls': item.imageUrls,
      'category_id': item.categoryId,
      'is_available': item.isAvailable,
    }).eq('id', item.id);

    await _db.from('menu_item_sizes').delete().eq('menu_item_id', item.id);
    if (item.sizes.isNotEmpty) {
      await _db.from('menu_item_sizes').insert(
        item.sizes.asMap().entries.map((e) => {
          'menu_item_id': item.id,
          'name': e.value.name,
          'price': e.value.price,
          'sort_order': e.key,
        }).toList(),
      );
    }
    // Ingredients are no longer edited from the item form, so existing links are left as they are.
  }

  Future<void> deleteMenuItem(String id) async {
    await _db.from('menu_items').delete().eq('id', id);
  }

  Future<void> toggleMenuItem(String id, bool isAvailable) async {
    await _db
        .from('menu_items')
        .update({'is_available': isAvailable}).eq('id', id);
  }

  // ── IMAGE UPLOAD — Web-compatible (Uint8List bytes) ───────────────────────

  Future<String> uploadMenuImageBytes(
      Uint8List bytes, String fileName, String mimeType) async {
    final path = 'menu/$branchId/$fileName';
    await _db.storage.from('menu-images').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(upsert: true, contentType: mimeType),
    );
    return _db.storage.from('menu-images').getPublicUrl(path);
  }

  Future<void> deleteMenuImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      final idx = segments.indexOf('menu-images');
      if (idx == -1) return;
      final path = segments.sublist(idx + 1).join('/');
      await _db.storage.from('menu-images').remove([path]);
    } catch (_) {}
  }

  // ── DEALS ──────────────────────────────────────────────────────────────────

  Future<List<Deal>> fetchDeals() async {
    final dealsRes = await _db
        .from('deals')
        .select()
        .eq('branch_id', branchId)
        .order('created_at');

    final dealIds =
    (dealsRes as List).map((j) => j['id'] as String).toList();

    final itemsRes =
    await _db.from('deal_items').select('deal_id, menu_item_id');
    final itemMap = <String, List<String>>{};
    for (final row in itemsRes as List) {
      itemMap
          .putIfAbsent(row['deal_id'] as String, () => [])
          .add(row['menu_item_id'] as String);
    }

    Map<String, List<ItemSize>> sizesMap = {};
    if (dealIds.isNotEmpty) {
      final sizesRes = await _db
          .from('deal_sizes')
          .select()
          .inFilter('deal_id', dealIds)
          .order('sort_order');
      for (final row in sizesRes as List) {
        final did = row['deal_id'] as String;
        sizesMap.putIfAbsent(did, () => []).add(ItemSize.fromJson(row));
      }
    }

    return dealsRes
        .map((j) => Deal.fromJson(
      j,
      itemMap[j['id']] ?? [],
      sizes: sizesMap[j['id']] ?? [],
    ))
        .toList();
  }

  Future<Deal> insertDeal(Deal deal) async {
    if (branchId.isEmpty) throw Exception('branchId is empty — login again');

    final res =
    await _db.from('deals').insert(deal.toInsert()).select().single();
    final newId = res['id'] as String;

    if (deal.itemIds.isNotEmpty) {
      await _db.from('deal_items').insert(deal.itemIds
          .map((mid) => {'deal_id': newId, 'menu_item_id': mid})
          .toList());
    }

    if (deal.sizes.isNotEmpty) {
      await _db.from('deal_sizes').insert(
        deal.sizes.asMap().entries.map((e) => {
          'deal_id': newId,
          'name': e.value.name,
          'price': e.value.price,
          'sort_order': e.key,
        }).toList(),
      );
    }

    final savedSizes = deal.sizes.isNotEmpty
        ? (await _db
        .from('deal_sizes')
        .select()
        .eq('deal_id', newId)
        .order('sort_order'))
        .map((j) => ItemSize.fromJson(j))
        .toList()
        : <ItemSize>[];

    return Deal.fromJson(res, deal.itemIds, sizes: savedSizes);
  }

  Future<void> updateDeal(Deal deal) async {
    await _db.from('deals').update({
      'name': deal.name,
      'deal_price': deal.dealPrice,
      'description': deal.description,
      'is_available': deal.isAvailable,
    }).eq('id', deal.id);

    await _db.from('deal_items').delete().eq('deal_id', deal.id);
    if (deal.itemIds.isNotEmpty) {
      await _db.from('deal_items').insert(deal.itemIds
          .map((mid) => {'deal_id': deal.id, 'menu_item_id': mid})
          .toList());
    }

    await _db.from('deal_sizes').delete().eq('deal_id', deal.id);
    if (deal.sizes.isNotEmpty) {
      await _db.from('deal_sizes').insert(
        deal.sizes.asMap().entries.map((e) => {
          'deal_id': deal.id,
          'name': e.value.name,
          'price': e.value.price,
          'sort_order': e.key,
        }).toList(),
      );
    }
  }

  Future<void> deleteDeal(String id) async {
    await _db.from('deals').delete().eq('id', id);
  }

  Future<void> toggleDeal(String id, bool isAvailable) async {
    await _db
        .from('deals')
        .update({'is_available': isAvailable}).eq('id', id);
  }
}