import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/order.dart';
import '../../models/shop_status.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/date_chip.dart';

/// Provider for the list of available dates (last 30 days).
final availableDatesProvider = Provider<List<DateTime>>((ref) {
  final now = DateTime.now();
  return List.generate(30, (i) {
    final d = now.subtract(Duration(days: i));
    return DateTime(d.year, d.month, d.day);
  });
});

/// Selected date provider.
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Orders for the selected date.
final ordersForDateProvider =
    FutureProvider.family<List<Order>, String>((ref, dateKey) {
  return FirebaseService.instance.ordersForDate(dateKey);
});

/// Shop status for selected date.
final shopStatusForDateProvider =
    FutureProvider.family<ShopStatus, String>((ref, dateKey) {
  return FirebaseService.instance.getShopStatus(dateKey);
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dates = ref.watch(availableDatesProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    final ordersAsync = ref.watch(ordersForDateProvider(dateKey));
    final shopStatusAsync = ref.watch(shopStatusForDateProvider(dateKey));

    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        title: const Text('HISTORY'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded, color: AppColors.amber),
            tooltip: 'Today',
            onPressed: () {
              final now = DateTime.now();
              ref.read(selectedDateProvider.notifier).state =
                  DateTime(now.year, now.month, now.day);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Date picker row ──────────────────────────────────────────
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: dates.length,
              itemBuilder: (context, i) {
                final date = dates[i];
                final isSelected = date.day == selectedDate.day &&
                    date.month == selectedDate.month &&
                    date.year == selectedDate.year;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: DateChip(
                    date: date,
                    isSelected: isSelected,
                    onTap: () => ref
                        .read(selectedDateProvider.notifier)
                        .state = date,
                  ),
                );
              },
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          Expanded(
            child: shopStatusAsync.when(
              data: (status) {
                if (!status.isOpen) {
                  return _ClosedDayState(date: selectedDate);
                }
                return ordersAsync.when(
                  data: (orders) => _OrdersList(
                      orders: orders, selectedDate: selectedDate),
                  loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.amber),
                  ),
                  error: (e, _) => _ErrorState(message: e.toString()),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.amber),
              ),
              error: (e, _) {
                // If status fetch fails, still show orders
                return ordersAsync.when(
                  data: (orders) => _OrdersList(
                      orders: orders, selectedDate: selectedDate),
                  loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.amber),
                  ),
                  error: (e2, _) => _ErrorState(message: e2.toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Orders list ─────────────────────────────────────────────────────────────
class _OrdersList extends StatelessWidget {
  final List<Order> orders;
  final DateTime selectedDate;

  const _OrdersList({required this.orders, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64,
                color: AppColors.textSecondaryDark.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No orders on this day',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondaryDark)),
          ],
        ),
      );
    }

    final totalSales =
        orders.fold(0.0, (sum, o) => sum + o.total);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Summary card ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.maroon.withValues(alpha: 0.8),
                AppColors.cardDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.maroon, width: 0.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('dd MMM yyyy').format(selectedDate),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondaryDark)),
                    const SizedBox(height: 4),
                    Text('TOTAL SALES',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondaryDark,
                            letterSpacing: 1.5)),
                    Text('₹${totalSales.toStringAsFixed(2)}',
                        style: AppTextStyles.priceTotal),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${orders.length}',
                      style: AppTextStyles.headlineLarge
                          .copyWith(color: Colors.white)),
                  Text('orders',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondaryDark)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Transaction list ───────────────────────────────────────────
        Text('TRANSACTIONS',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textSecondaryDark, letterSpacing: 2)),
        const SizedBox(height: 10),
        ...orders.map((order) => _OrderCard(order: order)),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('hh:mm a').format(order.timestamp);
    final isCash = order.paymentMode == PaymentMode.cash;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerDark, width: 0.5),
      ),
      child: Row(
        children: [
          // Payment mode badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (isCash ? AppColors.cashTag : AppColors.upiTag)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCash ? AppColors.cashTag : AppColors.upiTag,
                width: 0.5,
              ),
            ),
            child: Text(
              order.paymentMode.label.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                color: isCash ? AppColors.cashTag : AppColors.upiTag,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Phone + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.phone,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: Colors.white, fontSize: 13)),
                Text(time,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondaryDark)),
              ],
            ),
          ),
          // Amount
          Text(
            '₹${order.total.toStringAsFixed(2)}',
            style: AppTextStyles.price.copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ClosedDayState extends StatelessWidget {
  final DateTime date;
  const _ClosedDayState({required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.store_outlined,
              size: 64, color: AppColors.textSecondaryDark),
          const SizedBox(height: 16),
          Text(
            'Shop was closed on this day',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondaryDark),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, dd MMMM yyyy').format(date),
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondaryDark.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline,
              size: 48, color: AppColors.errorRed),
          const SizedBox(height: 12),
          Text('Error loading data',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondaryDark)),
        ],
      ),
    );
  }
}
