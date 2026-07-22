import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../screens/cart/cart_screen.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/primary_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMode? _selectedMode;
  bool _isSaving = false;
  bool _showSuccess = false;
  double _confirmedTotal = 0.0;

  Future<void> _confirmOrder() async {
    if (_selectedMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment mode')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final cart = ref.read(cartProvider);
      final phone = ref.read(phoneProvider);
      final user = ref.read(currentUserProvider);

      final order = Order(
        id: '',
        items: cart.itemList
            .map((e) => OrderLineItem(
                  itemId: e.menuItem.id,
                  name: e.menuItem.name,
                  price: e.menuItem.price,
                  quantity: e.quantity,
                  isVeg: e.menuItem.isVeg,
                ))
            .toList(),
        total: cart.totalAmount,
        phone: '+91${phone.replaceAll(RegExp(r'\D'), '')}',
        paymentMode: _selectedMode!,
        timestamp: DateTime.now(),
        staffId: user?.uid ?? 'unknown',
      );

      final orderTotal = cart.totalAmount;
      await FirebaseService.instance.saveOrder(order);
      ref.read(cartProvider.notifier).clearCart();

      setState(() {
        _isSaving = false;
        _showSuccess = true;
        _confirmedTotal = orderTotal;
      });

      // Auto navigate back to menu after success animation
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/menu', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    if (_showSuccess) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Razorpay style Green Check Animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF43A047),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 70,
                ),
              ).animate().scale(
                begin: const Offset(0.1, 0.1),
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),
              const SizedBox(height: 30),
              Text('Order Confirmed!',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  )).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_selectedMode!.label} • ₹${_confirmedTotal.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('PAYMENT MODE'),
        leading: BackButton(color: AppColors.amber),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Logo
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: AppLogo(size: 60),
              ),
            ),
            // ── Order summary ────────────────────────────────────────────
            Text('HOW WAS THIS PAID?',
                style: AppTextStyles.headlineSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface, letterSpacing: 1.5)),
            const SizedBox(height: 6),
            Text(
              '${cart.totalItemCount} item${cart.totalItemCount > 1 ? 's' : ''} • ₹${cart.totalAmount.toStringAsFixed(2)}',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 36),

            // ── Payment mode selector ────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _PaymentModeCard(
                    label: 'CASH',
                    icon: Icons.money_rounded,
                    selected: _selectedMode == PaymentMode.cash,
                    onTap: () =>
                        setState(() => _selectedMode = PaymentMode.cash),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _PaymentModeCard(
                    label: 'UPI',
                    icon: Icons.qr_code_rounded,
                    selected: _selectedMode == PaymentMode.upi,
                    onTap: () =>
                        setState(() => _selectedMode = PaymentMode.upi),
                  ),
                ),
              ],
            ),
            const Spacer(),

            // ── Confirm button ───────────────────────────────────────────
            PrimaryButton(
              label: 'CONFIRM & LOG ORDER',
              isLoading: _isSaving,
              onPressed: _selectedMode == null ? null : _confirmOrder,
              icon: Icons.check_circle_outline_rounded,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PaymentModeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentModeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: selected ? AppColors.maroon : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.amber : Theme.of(context).colorScheme.outline,
            width: selected ? 2 : 0.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.maroon.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: selected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppTextStyles.headlineSmall.copyWith(
                color:
                    selected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
