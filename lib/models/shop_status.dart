import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the open/closed status of the shop for a given date.
/// Stored in Firestore `shop_status` collection with doc id = 'YYYY-MM-DD'.
class ShopStatus {
  final String date; // 'YYYY-MM-DD'
  final bool isOpen;
  final DateTime? openedAt;
  final DateTime? closedAt;

  const ShopStatus({
    required this.date,
    required this.isOpen,
    this.openedAt,
    this.closedAt,
  });

  factory ShopStatus.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShopStatus(
      date: doc.id,
      isOpen: data['isOpen'] as bool? ?? false,
      openedAt: (data['openedAt'] as Timestamp?)?.toDate(),
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isOpen': isOpen,
      if (openedAt != null) 'openedAt': Timestamp.fromDate(openedAt!),
      if (closedAt != null) 'closedAt': Timestamp.fromDate(closedAt!),
    };
  }

  /// Default closed status for a date.
  factory ShopStatus.closed(String date) {
    return ShopStatus(date: date, isOpen: false);
  }
}
