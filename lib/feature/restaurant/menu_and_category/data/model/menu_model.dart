import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';

/// A photo picked in the item form that still has to be uploaded.
class PickedImage {
  final Uint8List bytes;
  final String mimeType;

  const PickedImage({required this.bytes, required this.mimeType});
}

// ── Color shades (red only) ────────────────────────────────────────────────
const List<Color> kCategoryShades = [
  Color(0xFFB91C1C), Color(0xFFDC2626), Color(0xFFF87171),
  Color(0xFF991B1B), Color(0xFFE11D48), Color(0xFFFCA5A5),
  Color(0xFF7F1D1D), Color(0xFFBE123C),
];
Color categoryShadeAt(int index) => kCategoryShades[index % kCategoryShades.length];

// ── ItemSize ──────────────────────────────────────────────────────────────────
class ItemSize {
  final String id;
  String name;
  double price;
  int sortOrder;

  ItemSize({
    required this.id,
    required this.name,
    required this.price,
    this.sortOrder = 0,
  });

  factory ItemSize.fromJson(Map<String, dynamic> j) => ItemSize(
    id: j['id'] as String,
    name: j['name'] as String,
    price: (j['price'] as num).toDouble(),
    sortOrder: (j['sort_order'] as int?) ?? 0,
  );

  factory ItemSize.temp({required String name, required double price, int sortOrder = 0}) =>
      ItemSize(id: '', name: name, price: price, sortOrder: sortOrder);

  Map<String, dynamic> toInsertMenuItem(String menuItemId) => {
    'menu_item_id': menuItemId,
    'name': name,
    'price': price,
    'sort_order': sortOrder,
  };

  Map<String, dynamic> toInsertDeal(String dealId) => {
    'deal_id': dealId,
    'name': name,
    'price': price,
    'sort_order': sortOrder,
  };
}

// ── Ingredient ────────────────────────────────────────────────────────────────
class Ingredient {
  final String id;         // menu_item_ingredients.id (uuid)
  final int stockItemId;   // stock_items.id (bigint)
  String stockItemName;    // for display only
  double quantity;         // how much to deduct per order
  String unit;             // g, kg, pcs, etc.

  Ingredient({
    required this.id,
    required this.stockItemId,
    required this.stockItemName,
    required this.quantity,
    required this.unit,
  });

  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(
    id: j['id'] as String,
    stockItemId: (j['stock_item_id'] as num).toInt(),
    stockItemName: j['stock_item_name'] as String? ?? '',
    quantity: (j['quantity'] as num).toDouble(),
    unit: j['unit'] as String? ?? '',
  );

  // temp before saving
  factory Ingredient.temp({
    required int stockItemId,
    required String stockItemName,
    required double quantity,
    required String unit,
  }) => Ingredient(id: '', stockItemId: stockItemId, stockItemName: stockItemName, quantity: quantity, unit: unit);

  Map<String, dynamic> toInsert(String menuItemId, String branchId) => {
    'menu_item_id': menuItemId,
    'stock_item_id': stockItemId,
    'quantity': quantity,
    'branch_id': branchId,
  };
}

// ── MenuCategory ──────────────────────────────────────────────────────────────
class MenuCategory {
  final String id;
  final String branchId;
  String name;
  String description;
  int colorIndex;

  MenuCategory({
    required this.id,
    required this.branchId,
    required this.name,
    required this.description,
    this.colorIndex = 0,
  });

  Color get color => categoryShadeAt(colorIndex);

  factory MenuCategory.fromJson(Map<String, dynamic> j) => MenuCategory(
    id: j['id'] as String,
    branchId: j['branch_id'] as String,
    name: j['name'] as String,
    description: j['description'] as String? ?? '',
    colorIndex: (j['color_index'] as int?) ?? 0,
  );

  Map<String, dynamic> toInsert() => {
    'branch_id': branchId,
    'name': name,
    'description': description,
    'color_index': colorIndex,
  };
}

// ── MenuItem ──────────────────────────────────────────────────────────────────
class MenuItem {
  final String id;
  final String branchId;
  String name;
  double price;
  double costPrice;
  String? imageUrl;          // cover image (first of imageUrls) — used by POS and website
  List<String> imageUrls;    // all photos, cover first
  String? categoryId;
  bool isAvailable;
  List<ItemSize> sizes;
  List<Ingredient> ingredients;

  MenuItem({
    required this.id,
    required this.branchId,
    required this.name,
    required this.price,
    required this.costPrice,
    this.imageUrl,
    this.imageUrls = const [],
    this.categoryId,
    this.isAvailable = true,
    this.sizes = const [],
    this.ingredients = const [],
  });

  double get effectivePrice => sizes.isNotEmpty
      ? sizes.map((s) => s.price).reduce((a, b) => a < b ? a : b)
      : price;

  bool get hasSizes => sizes.isNotEmpty;
  bool get hasIngredients => ingredients.isNotEmpty;

  double get profit => effectivePrice - costPrice;
  double get margin => effectivePrice > 0 ? (profit / effectivePrice) * 100 : 0;

  factory MenuItem.fromJson(Map<String, dynamic> j,
      {List<ItemSize> sizes = const [], List<Ingredient> ingredients = const []}) =>
      MenuItem(
        id: j['id'] as String,
        branchId: j['branch_id'] as String,
        name: j['name'] as String,
        price: (j['price'] as num).toDouble(),
        costPrice: (j['cost_price'] as num).toDouble(),
        imageUrl: j['image_url'] as String?,
        imageUrls: _imageUrlsFromJson(j),
        categoryId: j['category_id'] as String?,
        isAvailable: j['is_available'] as bool? ?? true,
        sizes: sizes,
        ingredients: ingredients,
      );

  /// `image_urls` column, falling back to the single `image_url` for items
  /// saved before multiple images existed.
  static List<String> _imageUrlsFromJson(Map<String, dynamic> j) {
    final urls = [for (final u in (j['image_urls'] as List? ?? const [])) '$u'];
    if (urls.isNotEmpty) return urls;
    final single = j['image_url'] as String?;
    return single == null || single.isEmpty ? [] : [single];
  }

  Map<String, dynamic> toInsert() => {
    'branch_id': branchId,
    'name': name,
    'price': price,
    'cost_price': costPrice,
    'image_url': imageUrl,
    'image_urls': imageUrls,
    'category_id': categoryId,
    'is_available': isAvailable,
  };
}

// ── Deal ──────────────────────────────────────────────────────────────────────
class Deal {
  final String id;
  final String branchId;
  String name;
  double dealPrice;
  List<String> itemIds;
  String description;
  bool isAvailable;
  List<ItemSize> sizes;

  Deal({
    required this.id,
    required this.branchId,
    required this.name,
    required this.dealPrice,
    required this.itemIds,
    required this.description,
    this.isAvailable = true,
    this.sizes = const [],
  });

  bool get hasSizes => sizes.isNotEmpty;

  double get effectivePrice => sizes.isNotEmpty
      ? sizes.map((s) => s.price).reduce((a, b) => a < b ? a : b)
      : dealPrice;

  factory Deal.fromJson(Map<String, dynamic> j, List<String> itemIds,
      {List<ItemSize> sizes = const []}) =>
      Deal(
        id: j['id'] as String,
        branchId: j['branch_id'] as String,
        name: j['name'] as String,
        dealPrice: (j['deal_price'] as num).toDouble(),
        itemIds: itemIds,
        description: j['description'] as String? ?? '',
        isAvailable: j['is_available'] as bool? ?? true,
        sizes: sizes,
      );

  Map<String, dynamic> toInsert() => {
    'branch_id': branchId,
    'name': name,
    'deal_price': dealPrice,
    'description': description,
    'is_available': isAvailable,
  };
}

// ── StockItemRef — lightweight reference for dropdown ─────────────────────────
class StockItemRef {
  final int id;
  final String name;
  final String unit;
  final double qty;

  StockItemRef({required this.id, required this.name, required this.unit, required this.qty});

  factory StockItemRef.fromJson(Map<String, dynamic> j) => StockItemRef(
    id: (j['id'] as num).toInt(),
    name: j['name'] as String,
    unit: j['unit'] as String? ?? 'pcs',
    qty: (j['qty'] as num).toDouble(),
  );
}