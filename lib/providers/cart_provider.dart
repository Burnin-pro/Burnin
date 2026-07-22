import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_item.dart';

/// The cart state: a map from MenuItem.id → CartItem.
class CartState {
  final Map<String, CartItem> items;

  const CartState({required this.items});

  factory CartState.empty() => const CartState(items: {});

  int get totalItemCount =>
      items.values.fold(0, (sum, e) => sum + e.quantity);

  double get totalAmount =>
      items.values.fold(0.0, (sum, e) => sum + e.subtotal);

  List<CartItem> get itemList => items.values.toList();

  int quantityOf(String itemId) => items[itemId]?.quantity ?? 0;

  CartState copyWith({Map<String, CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}

/// Riverpod StateNotifier managing the cart.
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState.empty());

  void addItem(MenuItem item) {
    final current = state.items[item.id];
    final updated = Map<String, CartItem>.from(state.items);
    if (current == null) {
      updated[item.id] = CartItem(menuItem: item, quantity: 1);
    } else {
      updated[item.id] = current.copyWith(quantity: current.quantity + 1);
    }
    state = state.copyWith(items: updated);
  }

  void removeItem(MenuItem item) {
    final current = state.items[item.id];
    if (current == null) return;
    final updated = Map<String, CartItem>.from(state.items);
    if (current.quantity <= 1) {
      updated.remove(item.id);
    } else {
      updated[item.id] = current.copyWith(quantity: current.quantity - 1);
    }
    state = state.copyWith(items: updated);
  }

  void setQuantity(MenuItem item, int quantity) {
    final updated = Map<String, CartItem>.from(state.items);
    if (quantity <= 0) {
      updated.remove(item.id);
    } else {
      updated[item.id] = CartItem(menuItem: item, quantity: quantity);
    }
    state = state.copyWith(items: updated);
  }

  void clearCart() {
    state = CartState.empty();
  }

  int quantityOf(String itemId) => state.items[itemId]?.quantity ?? 0;
}

/// Global cart provider.
final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);
