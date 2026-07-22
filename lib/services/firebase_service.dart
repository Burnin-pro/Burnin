import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_storage/firebase_storage.dart';

import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/shop_status.dart';

/// Central Firestore + Storage service.
/// All raw Firebase calls are isolated here — screens talk to providers,
/// providers talk to this service.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // ── Collection references ────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _menuItems =>
      _db.collection('menu_items');

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  CollectionReference<Map<String, dynamic>> get _shopStatus =>
      _db.collection('shop_status');

  // ──────────────────────────────────────────────────────────────────────────
  // Menu
  // ──────────────────────────────────────────────────────────────────────────

  /// Real-time stream of all available menu items.
  Stream<List<MenuItem>> menuItemsStream() {
    return _menuItems
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map(MenuItem.fromFirestore).toList());
  }

  /// Add or update a menu item. If [id] is null, creates a new document.
  Future<void> saveMenuItem(MenuItem item) async {
    if (item.id.isEmpty) {
      await _menuItems.add(item.toFirestore());
    } else {
      await _menuItems.doc(item.id).set(item.toFirestore(), SetOptions(merge: true));
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Orders
  // ──────────────────────────────────────────────────────────────────────────

  /// Save a completed order to Firestore.
  Future<String> saveOrder(Order order) async {
    final ref = await _orders.add(order.toFirestore());
    return ref.id;
  }

  /// Fetch orders for a specific date (YYYY-MM-DD).
  Future<List<Order>> ordersForDate(String date) async {
    final start = DateTime.parse(date);
    final end = start.add(const Duration(days: 1));

    final snap = await _orders
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .get();

    return snap.docs.map<Order>((doc) => Order.fromFirestore(doc)).toList();
  }

  /// Stream orders for a specific date (YYYY-MM-DD).
  Stream<List<Order>> ordersStreamForDate(String date) {
    final start = DateTime.parse(date);
    final end = start.add(const Duration(days: 1));

    return _orders
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map<Order>((doc) => Order.fromFirestore(doc)).toList());
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Shop Status
  // ──────────────────────────────────────────────────────────────────────────

  /// Get today's shop status doc id (YYYY-MM-DD in local time).
  String todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}'
        '-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}';
  }

  Stream<ShopStatus> shopStatusStream(String dateKey) {
    return _shopStatus.doc(dateKey).snapshots().map((snap) {
      if (!snap.exists) return ShopStatus.closed(dateKey);
      return ShopStatus.fromFirestore(snap);
    });
  }

  Future<void> setShopStatus({required String dateKey, required bool isOpen}) {
    return _shopStatus.doc(dateKey).set(
      {
        'isOpen': isOpen,
        if (isOpen) 'openedAt': FieldValue.serverTimestamp(),
        if (!isOpen) 'closedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<ShopStatus> getShopStatus(String dateKey) async {
    final snap = await _shopStatus.doc(dateKey).get();
    if (!snap.exists) return ShopStatus.closed(dateKey);
    return ShopStatus.fromFirestore(snap);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Firebase Storage — Image Upload
  // ──────────────────────────────────────────────────────────────────────────

  /// Upload an image file to Firebase Storage, returns the download URL.
  Future<String> uploadMenuImage(Uint8List imageBytes, String fileName) async {
    final ref = _storage.ref('menu_images/$fileName');
    final task = await ref.putData(imageBytes);
    return await task.ref.getDownloadURL();
  }
}
