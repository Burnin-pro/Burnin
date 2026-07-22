import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment method enum.
enum PaymentMode { cash, upi }

extension PaymentModeX on PaymentMode {
  String get label => this == PaymentMode.cash ? 'Cash' : 'UPI';
  String get firestoreValue => this == PaymentMode.cash ? 'cash' : 'upi';

  static PaymentMode fromString(String value) {
    return value == 'cash' ? PaymentMode.cash : PaymentMode.upi;
  }
}

/// Represents a completed order saved to Firestore `orders` collection.
class Order {
  final String id;
  final List<OrderLineItem> items;
  final double total;
  final String phone; // +91XXXXXXXXXX
  final PaymentMode paymentMode;
  final DateTime timestamp;
  final String staffId;

  const Order({
    required this.id,
    required this.items,
    required this.total,
    required this.phone,
    required this.paymentMode,
    required this.timestamp,
    required this.staffId,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawItems = (data['items'] as List<dynamic>?) ?? [];
    return Order(
      id: doc.id,
      items: rawItems
          .map((e) => OrderLineItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      phone: data['phone'] as String? ?? '',
      paymentMode: PaymentModeX.fromString(data['paymentMode'] as String? ?? 'cash'),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      staffId: data['staffId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'phone': phone,
      'paymentMode': paymentMode.firestoreValue,
      'timestamp': Timestamp.fromDate(timestamp),
      'staffId': staffId,
    };
  }
}

/// Single line item within an order.
class OrderLineItem {
  final String itemId;
  final String name;
  final double price;
  final int quantity;
  final bool isVeg;

  const OrderLineItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.isVeg,
  });

  double get subtotal => price * quantity;

  factory OrderLineItem.fromMap(Map<String, dynamic> map) {
    return OrderLineItem(
      itemId: map['itemId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      isVeg: map['isVeg'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'isVeg': isVeg,
    };
  }
}
