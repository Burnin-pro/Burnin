import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single item on the BurnIn menu.
class MenuItem {
  final String id;
  final String name;
  final double price;
  final String category; // 'Food' | 'Drinks'
  final bool isVeg;
  final bool isAvailable;
  final String? imageUrl; // Firebase Storage URL

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.isVeg,
    required this.isAvailable,
    this.imageUrl,
  });

  factory MenuItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuItem(
      id: doc.id,
      name: data['name'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] as String? ?? 'Food',
      isVeg: data['isVeg'] as bool? ?? true,
      isAvailable: data['isAvailable'] as bool? ?? true,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'isVeg': isVeg,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
    };
  }

  MenuItem copyWith({
    String? id,
    String? name,
    double? price,
    String? category,
    bool? isVeg,
    bool? isAvailable,
    String? imageUrl,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      isVeg: isVeg ?? this.isVeg,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MenuItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Cart entry — wraps MenuItem with a quantity.
class CartItem {
  final MenuItem menuItem;
  final int quantity;

  const CartItem({required this.menuItem, required this.quantity});

  double get subtotal => menuItem.price * quantity;

  CartItem copyWith({MenuItem? menuItem, int? quantity}) {
    return CartItem(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
    );
  }
}
