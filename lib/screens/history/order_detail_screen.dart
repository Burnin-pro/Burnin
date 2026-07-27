import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../models/order.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/veg_dot.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat('dd MMM yyyy, hh:mm a').format(order.timestamp);
    final isCash = order.paymentMode == PaymentMode.cash;
    final payColor = isCash ? AppColors.cashTag : AppColors.upiTag;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('ORDER DETAILS'),
        leading: BackButton(color: AppColors.amber),
        centerTitle: true,
        backgroundColor: AppColors.maroon,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Logo Header
            const Center(
              child: AppLogo(size: 80, showTagline: false),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
            
            const SizedBox(height: 32),

            // Customer & Payment Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.maroon, AppColors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.maroon.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    order.phone.length > 3 ? order.phone : 'No phone provided',
                    style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    time,
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCash ? Icons.payments_rounded : Icons.qr_code_2_rounded,
                          color: payColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Paid via ${order.paymentMode.label}',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: payColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms).scale(begin: const Offset(0.9, 0.9)),

            const SizedBox(height: 32),

            // Order Items Label
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ORDER ITEMS',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 16),

            // Items List
            ...order.items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        'x${item.quantity}',
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.amber),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              VegDot(isVeg: item.isVeg),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${item.price.toStringAsFixed(0)} each',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${item.subtotal.toStringAsFixed(0)}',
                      style: AppTextStyles.price.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (300 + (50 * idx)).ms).slideX(begin: 0.1);
            }),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Grand Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GRAND TOTAL',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '₹${order.total.toStringAsFixed(0)}',
                  style: AppTextStyles.price.copyWith(
                    fontSize: 28,
                    color: AppColors.maroonLight,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
