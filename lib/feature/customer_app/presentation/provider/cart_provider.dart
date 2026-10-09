import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/dish_model.dart';

class CartLine {
  final Dish dish;
  final DishOption option;
  final int qty;

  const CartLine({required this.dish, required this.option, required this.qty});

  String get key => '${dish.id}:${option.label}';
  double get total => option.price * qty;

  CartLine copyWith({int? qty}) => CartLine(dish: dish, option: option, qty: qty ?? this.qty);
}

class CartNotifier extends Notifier<List<CartLine>> {
  @override
  List<CartLine> build() => const [];

  void add(Dish dish, DishOption option, {int qty = 1}) {
    final key = '${dish.id}:${option.label}';
    final i = state.indexWhere((l) => l.key == key);
    if (i == -1) {
      state = [...state, CartLine(dish: dish, option: option, qty: qty)];
    } else {
      state = [
        for (final l in state)
          if (l.key == key) l.copyWith(qty: l.qty + qty) else l,
      ];
    }
  }

  void setQty(String key, int qty) {
    state = qty <= 0
        ? state.where((l) => l.key != key).toList()
        : [
            for (final l in state)
              if (l.key == key) l.copyWith(qty: qty) else l,
          ];
  }

  void clear() => state = const [];
}

final cartProvider = NotifierProvider<CartNotifier, List<CartLine>>(CartNotifier.new);

final cartCountProvider = Provider<int>((ref) => ref.watch(cartProvider).fold(0, (sum, l) => sum + l.qty));

final cartSubtotalProvider = Provider<double>((ref) => ref.watch(cartProvider).fold(0.0, (sum, l) => sum + l.total));
