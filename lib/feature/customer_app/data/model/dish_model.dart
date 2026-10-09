import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import 'package:resturent_application/core/constants/currency.dart';

class DishOption {
  final String label;
  final double price;

  /// True when this is a row of `menu_item_sizes` (sent with the order so the
  /// server can price it); false for an item's single base price.
  final bool isSize;

  const DishOption(this.label, this.price, {this.isSize = false});
}

/// A menu item as the website shows it — built from the POS `menu_items`
/// (+ `menu_item_sizes`) rows, so the site always matches the desktop menu.
class Dish {
  final String id;
  final String name;
  final String description;
  final String categoryId;

  /// Network URL (Supabase storage) or bundled asset path; empty = placeholder.
  final String image;
  final List<DishOption> options;

  /// Highlighted on the printed menu and listed in the home page's Signature Menu.
  final bool isSignature;

  const Dish({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.image,
    required this.options,
    this.isSignature = false,
  });

  /// `menu_items` row with its nested `menu_item_sizes`.
  factory Dish.fromMenuItemJson(Map<String, dynamic> j) {
    final sizes = [...(j['menu_item_sizes'] as List? ?? const [])]
      ..sort((a, b) => ((a['sort_order'] as int?) ?? 0).compareTo((b['sort_order'] as int?) ?? 0));
    return Dish(
      id: j['id'] as String,
      name: j['name'] as String,
      description: (j['description'] as String?) ?? '',
      categoryId: (j['category_id'] as String?) ?? '',
      isSignature: (j['is_signature'] as bool?) ?? false,
      image: (j['image_url'] as String?) ?? '',
      options: sizes.isEmpty
          ? [DishOption('Regular', (j['price'] as num).toDouble())]
          : [for (final s in sizes) DishOption(s['name'] as String, (s['price'] as num).toDouble(), isSize: true)],
    );
  }

  double get fromPrice => options.map((o) => o.price).reduce((a, b) => a < b ? a : b);
  bool get hasOptions => options.length > 1;
}

class MenuCategory {
  final String id;
  final String name;
  final String tagline;
  final String image;
  final AppIcon icon;
  final int dishCount;

  const MenuCategory({
    required this.id,
    required this.name,
    required this.tagline,
    required this.image,
    this.icon = AppIcons.restaurantRounded,
    required this.dishCount,
  });
}

/// Website prices use the same pound format as the POS, e.g. "£8.50".
String formatPrice(double v) => formatMoney(v);
