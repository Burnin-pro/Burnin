import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/order.dart' as model;
import '../../providers/sales_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedSalesDateProvider);
    final summary = ref.watch(salesSummaryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payments & Sales'),
          actions: [
            IconButton(
              icon: const Icon(Icons.restaurant_menu_rounded, color: AppColors.orange),
              onPressed: () => _showFoodAnalytics(context, summary),
            ),
            IconButton(
              icon: const Icon(Icons.pie_chart_rounded, color: AppColors.vegGreen),
              onPressed: () => _showPaymentSplitAnalytics(context, summary),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // ── Top Header (Date & Total) ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.flameGradientHorizontal,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.maroon.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.maroon, // header background color
                                onPrimary: Colors.white, // header text color
                                onSurface: Colors.black, // body text color
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        ref.read(selectedSalesDateProvider.notifier).state = date;
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE, dd MMM yyyy').format(selectedDate),
                          style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'TOTAL INCOME',
                    style: AppTextStyles.labelSmall.copyWith(color: Colors.white54, letterSpacing: 2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${summary.totalIncome.toStringAsFixed(0)}',
                    style: AppTextStyles.priceTotal.copyWith(fontSize: 40, color: Colors.white),
                  ),
                ],
              ),
            ),

            // ── Tabs ───────────────────────────────────────────────────────
            TabBar(
              labelColor: AppColors.amber,
              unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
              indicatorColor: AppColors.amber,
              indicatorWeight: 3,
              labelStyle: AppTextStyles.labelMedium,
              tabs: [
                Tab(text: 'CASH (${summary.cashOrders.length})'),
                Tab(text: 'UPI (${summary.upiOrders.length})'),
              ],
            ),
            
            // ── Tab Views ──────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                children: [
                  _OrdersList(orders: summary.cashOrders),
                  _OrdersList(orders: summary.upiOrders),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentSplitAnalytics(BuildContext context, SalesSummary summary) {
    if (summary.totalIncome == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data for this date')),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('Payment Split', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 32),
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                    sections: [
                      if (summary.cashOrders.isNotEmpty)
                        PieChartSectionData(
                          color: AppColors.orange,
                          value: summary.cashOrders.length.toDouble(),
                          title: '${((summary.cashOrders.length / (summary.cashOrders.length + summary.upiOrders.length)) * 100).toStringAsFixed(0)}%',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      if (summary.upiOrders.isNotEmpty)
                        PieChartSectionData(
                          color: AppColors.amber,
                          value: summary.upiOrders.length.toDouble(),
                          title: '${((summary.upiOrders.length / (summary.cashOrders.length + summary.upiOrders.length)) * 100).toStringAsFixed(0)}%',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Indicator(color: AppColors.orange, text: 'Cash (${summary.cashOrders.length})'),
                  const SizedBox(width: 24),
                  _Indicator(color: AppColors.amber, text: 'UPI (${summary.upiOrders.length})'),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }

  void _showFoodAnalytics(BuildContext context, SalesSummary summary) {
    if (summary.itemSalesCount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data for this date')),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('Top Selling Items', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: summary.itemSalesCount.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final entry = summary.itemSalesCount.entries.elementAt(index);
                    final revenue = summary.itemSalesRevenue[entry.key] ?? 0;
                    return Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: index == 0 ? AppColors.amber.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text('#${index + 1}', style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: index == 0 ? AppColors.amber : (isDark ? Colors.white70 : Colors.black54),
                          )),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.key, style: AppTextStyles.labelMedium),
                              const SizedBox(height: 4),
                              Text('₹${revenue.toStringAsFixed(0)}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.vegGreen)),
                            ],
                          ),
                        ),
                        Text('${entry.value} sold', style: AppTextStyles.labelMedium.copyWith(color: AppColors.orange)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;

  const _Indicator({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 8),
        Text(text, style: AppTextStyles.labelMedium),
      ],
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<model.Order> orders;

  const _OrdersList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No orders found.', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        final timeStr = DateFormat('hh:mm a').format(order.timestamp);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return GestureDetector(
          onTap: () => _showReceiptBottomSheet(context, order),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.dividerDark : Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.person_rounded, color: AppColors.orange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.phone, style: AppTextStyles.labelMedium),
                      const SizedBox(height: 4),
                      Text(timeStr, style: AppTextStyles.bodySmall.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
                Text('₹${order.total.toStringAsFixed(0)}', style: AppTextStyles.price.copyWith(fontSize: 18, color: AppColors.vegGreen)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReceiptBottomSheet(BuildContext context, model.Order order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('Order Receipt', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 4),
              Text(order.phone, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.orange)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: order.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return Row(
                      children: [
                        Text('${item.quantity}x', style: AppTextStyles.labelMedium.copyWith(color: AppColors.orange)),
                        const SizedBox(width: 16),
                        Expanded(child: Text(item.name, style: AppTextStyles.bodyMedium)),
                        Text('₹${(item.quantity * item.price).toStringAsFixed(0)}', style: AppTextStyles.labelMedium),
                      ],
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL PAID', style: AppTextStyles.labelMedium),
                    Text('₹${order.total.toStringAsFixed(0)}', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.vegGreen)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
