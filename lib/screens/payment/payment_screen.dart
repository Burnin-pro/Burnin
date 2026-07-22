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
import '../../widgets/primary_button.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMode? _selectedMode;
  bool _isSaving = false;
  bool _showSuccess = false;

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

      await FirebaseService.instance.saveOrder(order);
      ref.read(cartProvider.notifier).clearCart();

      setState(() {
        _isSaving = false;
        _showSuccess = true;
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
        backgroundColor: AppColors.scaffoldDark,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/lottie/flame_burst.json',
                width: 180,
                height: 180,
                repeat: false,
              ),
              const SizedBox(height: 20),
              Text('Order Confirmed!',
                  style: AppTextStyles.headlineMedium
                      .copyWith(color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                '${_selectedMode!.label} • ₹${cart.totalAmount.toStringAsFixed(2)}',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondaryDark),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        title: const Text('PAYMENT MODE'),
        leading: BackButton(color: AppColors.amber),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Order summary ────────────────────────────────────────────
            Text('HOW WAS THIS PAID?',
                style: AppTextStyles.headlineSmall.copyWith(
                    color: Colors.white, letterSpacing: 1.5)),
            const SizedBox(height: 6),
            Text(
              '${cart.totalItemCount} item${cart.totalItemCount > 1 ? 's' : ''} • ₹${cart.totalAmount.toStringAsFixed(2)}',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondaryDark),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: selected ? AppColors.maroon : AppColors.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.amber : AppColors.dividerDark,
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
              color: selected ? Colors.white : AppColors.textSecondaryDark,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppTextStyles.headlineSmall.copyWith(
                color:
                    selected ? Colors.white : AppColors.textSecondaryDark,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
