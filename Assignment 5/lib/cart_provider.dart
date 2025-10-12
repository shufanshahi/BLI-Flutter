import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartNotifier extends StateNotifier<Map<int, int>> {
  CartNotifier() : super({});

  void addToCart(int itemIndex) {
    final current = state[itemIndex] ?? 0;
    state = {...state, itemIndex: current + 1};
  }

  void removeFromCart(int itemIndex) {
    final current = state[itemIndex] ?? 0;
    if (current > 1) {
      state = {...state, itemIndex: current - 1};
    } else {
      state = {...state}..remove(itemIndex);
    }
  }

  int getQuantity(int itemIndex) {
    return state[itemIndex] ?? 0;
  }

  List<int> getItems() {
    return state.keys.toList();
  }

  void removeItem(int itemIndex) {
    state = {...state}..remove(itemIndex);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, Map<int, int>>((ref) {
  return CartNotifier();
});