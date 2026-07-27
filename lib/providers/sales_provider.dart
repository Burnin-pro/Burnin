import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart' as model;
import '../services/firebase_service.dart';

/// Provider for the currently selected date in the Sales screen.
final selectedSalesDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Formats the selected date into the YYYY-MM-DD key used by Firebase.
final selectedDateKeyProvider = Provider<String>((ref) {
  final date = ref.watch(selectedSalesDateProvider);
  return '${date.year.toString().padLeft(4, '0')}'
      '-${date.month.toString().padLeft(2, '0')}'
      '-${date.day.toString().padLeft(2, '0')}';
});

/// Stream of all orders for the selected date.
final salesOrdersProvider = StreamProvider<List<model.Order>>((ref) {
  final dateKey = ref.watch(selectedDateKeyProvider);
  return FirebaseService.instance.ordersStreamForDate(dateKey);
});

/// Aggregate sales data for the selected date.
class SalesSummary {
  final double totalIncome;
  final List<model.Order> cashOrders;
  final List<model.Order> upiOrders;
  final Map<String, int> itemSalesCount; // Item name -> Quantity sold
  final Map<String, double> itemSalesRevenue; // Item name -> Total revenue

  SalesSummary({
    required this.totalIncome,
    required this.cashOrders,
    required this.upiOrders,
    required this.itemSalesCount,
    required this.itemSalesRevenue,
  });

  factory SalesSummary.fromOrders(List<model.Order> orders) {
    double totalIncome = 0;
    final cashOrders = <model.Order>[];
    final upiOrders = <model.Order>[];
    final itemSalesCount = <String, int>{};
    final itemSalesRevenue = <String, double>{};

    for (final order in orders) {
      totalIncome += order.total;
      
      if (order.paymentMode == model.PaymentMode.cash) {
        cashOrders.add(order);
      } else {
        upiOrders.add(order);
      }

      for (final item in order.items) {
        itemSalesCount[item.name] = (itemSalesCount[item.name] ?? 0) + item.quantity;
        itemSalesRevenue[item.name] = (itemSalesRevenue[item.name] ?? 0) + (item.quantity * item.price);
      }
    }

    // Sort item sales by quantity descending
    final sortedItemSales = itemSalesCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final sortedItemCountMap = Map.fromEntries(sortedItemSales);

    return SalesSummary(
      totalIncome: totalIncome,
      cashOrders: cashOrders,
      upiOrders: upiOrders,
      itemSalesCount: sortedItemCountMap,
      itemSalesRevenue: itemSalesRevenue,
    );
  }
}

/// Provides the aggregated SalesSummary from the current orders stream.
final salesSummaryProvider = Provider<SalesSummary>((ref) {
  final orders = ref.watch(salesOrdersProvider).valueOrNull ?? [];
  return SalesSummary.fromOrders(orders);
});
