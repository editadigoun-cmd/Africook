import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(CartItem item) {
    final idx = state.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      final updated = List<CartItem>.from(state);
      updated[idx].quantity++;
      state = updated;
    } else {
      state = [...state, item];
    }
  }

  void removeItem(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  void updateQuantity(String id, int qty) {
    if (qty <= 0) {
      removeItem(id);
      return;
    }
    state = state
        .map((e) => e.id == id ? (e..quantity = qty) : e)
        .toList();
  }

  void clear() => state = [];

  double get total => state.fold(0, (sum, e) => sum + e.total);
  int get itemCount => state.fold(0, (sum, e) => sum + e.quantity);
}
