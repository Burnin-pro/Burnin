import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    StreamProvider.family<List<Order>, String>((ref, dateKey) {
  return FirebaseService.instance.ordersStreamForDate(dateKey);
});

/// Shop status for selected date.
final shopStatusForDateProvider =
    StreamProvider.family<ShopStatus, String>((ref, dateKey) {
  return FirebaseService.instance.shopStatusStream(dateKey);
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dates = ref.watch(availableDatesProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    
    // Auto-refresh dates if the day rolled over
    if (dates.isNotEmpty) {
      final now = DateTime.now();
      if (dates.first.day != now.day || dates.first.month != now.month || dates.first.year != now.year) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(availableDatesProvider);
          ref.read(selectedDateProvider.notifier).state = DateTime(now.year, now.month, now.day);
        });
      }
    }

    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    final ordersAsync = ref.watch(ordersForDateProvider(dateKey));
    final shopStatusAsync = ref.watch(shopStatusForDateProvider(dateKey));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.maroon, AppColors.maroonLight, AppColors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row
                      Row(
                        children: [
                          Text(
                            'HISTORY',
                            style: AppTextStyles.headlineSmall
                                .copyWith(color: Colors.white, letterSpacing: 2, fontSize: 20),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              final orders = ordersAsync.value ?? [];
                              _showSalesCalculatorDialog(context, orders, selectedDate);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: const Icon(Icons.calculate_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              final now = DateTime.now();
                              ref.read(selectedDateProvider.notifier).state =
                                  DateTime(now.year, now.month, now.day);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.today_rounded,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Today',
                                      style: AppTextStyles.labelSmall
                                          .copyWith(color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Date picker
                      SizedBox(
                        height: 78,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: dates.length,
                          itemBuilder: (context, i) {
                            final date = dates[i];
                            final isSelected =
                                date.day == selectedDate.day &&
                                    date.month == selectedDate.month &&
                                    date.year == selectedDate.year;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: _HistoryDateChip(
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
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          shopStatusAsync.when(
            data: (status) {
              if (!status.isOpen) {
                return SliverFillRemaining(
                  child: _ClosedDayState(date: selectedDate),
                );
              }
              return ordersAsync.when(
                data: (orders) => _OrdersContent(
                    orders: orders, selectedDate: selectedDate),
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.amber),
                  ),
                ),
                error: (e, _) =>
                    SliverFillRemaining(child: _ErrorState(message: e.toString())),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.amber),
              ),
            ),
            error: (e, _) {
              return ordersAsync.when(
                data: (orders) => _OrdersContent(
                    orders: orders, selectedDate: selectedDate),
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.amber),
                  ),
                ),
                error: (e2, _) =>
                    SliverFillRemaining(child: _ErrorState(message: e2.toString())),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── History Date Chip (inside the gradient header) ────────────────────────────
class _HistoryDateChip extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _HistoryDateChip({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final day = DateFormat('dd').format(date);
    final month = DateFormat('MMM').format(date).toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              day,
              style: AppTextStyles.headlineSmall.copyWith(
                color: isSelected ? AppColors.maroon : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              month,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? AppColors.orange : Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Orders Content (as slivers) ─────────────────────────────────────────────
class _OrdersContent extends StatelessWidget {
  final List<Order> orders;
  final DateTime selectedDate;

  const _OrdersContent({required this.orders, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.receipt_long_outlined,
                    size: 48,
                    color: (Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 16),
              Text('No orders on this day',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            ],
          ),
        ),
      );
    }

    final totalSales = orders.fold(0.0, (sum, o) => sum + o.total);

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // ── Summary Card ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.maroon.withValues(alpha: 0.6),
                  Theme.of(context).cardColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: AppColors.maroon.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          DateFormat('EEEE, dd MMM').format(selectedDate),
                          style: AppTextStyles.bodySmall.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                      const SizedBox(height: 6),
                      Text('TOTAL SALES',
                          style: AppTextStyles.labelSmall.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : AppColors.textSecondaryLight,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text('₹${totalSales.toStringAsFixed(0)}',
                          style: AppTextStyles.priceTotal.copyWith(
                              fontSize: 30,
                              color: Theme.of(context).colorScheme.onSurface)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text('${orders.length}',
                          style: AppTextStyles.headlineLarge.copyWith(
                              color: AppColors.amber, fontSize: 28)),
                      Text('orders',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

          const SizedBox(height: 24),

          // ── Transaction label ──────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text('TRANSACTIONS',
                  style: AppTextStyles.labelSmall.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 14),

          // ── Order cards ────────────────────────────────────────────────
          ...orders.asMap().entries.map((entry) => _OrderCard(
                order: entry.value,
                index: entry.key,
              )),
        ]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final int index;
  const _OrderCard({required this.order, required this.index});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('hh:mm a').format(order.timestamp);
    final isCash = order.paymentMode == PaymentMode.cash;
    final payColor = isCash ? AppColors.cashTag : AppColors.upiTag;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 0.5),
      ),
      child: Row(
        children: [
          // Payment mode badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: payColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                isCash ? Icons.payments_outlined : Icons.qr_code_2_rounded,
                color: payColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Phone + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.phone,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 12, color: AppColors.textSecondaryDark),
                    const SizedBox(width: 4),
                    Text(time,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondaryDark)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: payColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.paymentMode.label.toUpperCase(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: payColor,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '₹${order.total.toStringAsFixed(0)}',
            style: AppTextStyles.price.copyWith(fontSize: 17),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (50 * index).ms, duration: 300.ms);
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.store_outlined,
                size: 48, color: AppColors.textSecondaryDark),
          ),
          const SizedBox(height: 20),
          Text(
            'Shop was closed',
            style: AppTextStyles.headlineSmall
                .copyWith(color: AppColors.textSecondaryDark),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('EEEE, dd MMMM yyyy').format(date),
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryDark.withValues(alpha: 0.6)),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline,
                size: 40, color: AppColors.errorRed),
          ),
          const SizedBox(height: 16),
          Text('Error loading data',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondaryDark)),
        ],
      ),
    );
  }
}

void _showSalesCalculatorDialog(
    BuildContext context, List<Order> orders, DateTime date) {
  final totalSales = orders.fold<double>(0, (sum, o) => sum + o.total);
  final totalOrders = orders.length;

  showDialog(
    context: context,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calculate_rounded,
                    size: 40, color: AppColors.orange),
              ),
              const SizedBox(height: 16),
              Text(
                'Daily Summary',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMM yyyy').format(date),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark ? AppColors.dividerDark : Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Orders Count:',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark ? Colors.white70 : AppColors.textSecondaryLight)),
                        Text('$totalOrders',
                            style: AppTextStyles.labelMedium.copyWith(
                                color: isDark ? Colors.white : AppColors.textPrimaryLight)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Revenue:',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark ? Colors.white70 : AppColors.textSecondaryLight)),
                        Text('₹${totalSales.toStringAsFixed(0)}',
                            style: AppTextStyles.headlineSmall.copyWith(
                                color: AppColors.vegGreen)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.maroon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
