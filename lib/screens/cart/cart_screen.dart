import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/menu_item.dart';
import '../../providers/cart_provider.dart';
import '../../services/qr_service.dart';
import '../../services/whatsapp_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/veg_dot.dart';

/// Phone number provider (local to cart screen).
final phoneProvider = StateProvider<String>((ref) => '');

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();
  bool _sendingWhatsApp = false;
  String? _phoneError;

  String _sanitizePhone(String input) {
    return input.replaceAll(RegExp(r'\D'), '');
  }

  bool _validatePhone(String phone) {
    final digits = _sanitizePhone(phone);
    return digits.length == 10;
  }

  Future<void> _sendBillWhatsApp() async {
    final phone = _phoneController.text;
    if (!_validatePhone(phone)) {
      setState(() => _phoneError = 'Enter a valid 10-digit mobile number');
      return;
    }
    setState(() {
      _phoneError = null;
      _sendingWhatsApp = true;
    });
    try {
      final cart = ref.read(cartProvider);
      final billText = WhatsAppService.instance.formatBillText(
        shopName: QrService.kShopName,
        items: cart.itemList
            .map((e) =>
                (name: e.menuItem.name, qty: e.quantity, price: e.menuItem.price))
            .toList(),
        total: cart.totalAmount,
      );
      await WhatsAppService.instance.sendBill(
        phone: phone,
        billText: billText,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingWhatsApp = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final upiData = QrService.instance.buildUpiQrData(amount: cart.totalAmount);

    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        title: const Text('CART'),
        leading: BackButton(color: AppColors.amber),
        actions: [
          if (cart.totalItemCount > 0)
            TextButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
                Navigator.of(context).pop();
              },
              child: Text('CLEAR',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.errorRed)),
            ),
        ],
      ),
      body: cart.totalItemCount == 0
          ? _EmptyCart(onBack: () => Navigator.of(context).pop())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Cart items ───────────────────────────────────────
                  ...cart.itemList.map((e) => _CartItemRow(item: e)),
                  const SizedBox(height: 8),
                  const Divider(color: AppColors.dividerDark),
                  // ── Total ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TOTAL',
                            style: AppTextStyles.headlineSmall
                                .copyWith(color: Colors.white, letterSpacing: 2)),
                        Text('₹${cart.totalAmount.toStringAsFixed(2)}',
                            style: AppTextStyles.priceTotal),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.dividerDark),
                  const SizedBox(height: 20),

                  // ── Bill preview ─────────────────────────────────────
                  _BillPreview(cart: cart, upiData: upiData),
                  const SizedBox(height: 20),

                  // ── Phone number ─────────────────────────────────────
                  TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) {
                      if (_phoneError != null) {
                        setState(() => _phoneError = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Customer Mobile Number',
                      hintText: '9876543210',
                      prefixText: '+91  ',
                      prefixStyle: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.amber),
                      prefixIcon:
                          const Icon(Icons.phone_outlined),
                      counterText: '',
                      errorText: _phoneError,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Send WhatsApp ─────────────────────────────────────
                  PrimaryButton(
                    label: 'Send Bill via WhatsApp',
                    icon: Icons.send_rounded,
                    isLoading: _sendingWhatsApp,
                    onPressed: _sendBillWhatsApp,
                  ),
                  const SizedBox(height: 12),

                  // ── Proceed to payment ────────────────────────────────
                  OutlinedButton.icon(
                    onPressed: () {
                      final phone = _phoneController.text;
                      if (!_validatePhone(phone)) {
                        setState(() => _phoneError =
                            'Enter a valid 10-digit mobile number');
                        return;
                      }
                      ref.read(phoneProvider.notifier).state = phone;
                      Navigator.of(context).pushNamed('/payment');
                    },
                    icon: const Icon(Icons.payment_rounded),
                    label: const Text('CONFIRM & LOG ORDER'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

// ── Cart item row ───────────────────────────────────────────────────────────
class _CartItemRow extends ConsumerWidget {
  final CartItem item;
  const _CartItemRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          VegDot(isVeg: item.menuItem.isVeg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.menuItem.name,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: Colors.white)),
                Text('₹${item.menuItem.price.toStringAsFixed(0)} each',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondaryDark)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          QuantityStepper(
            value: item.quantity,
            onIncrement: () =>
                ref.read(cartProvider.notifier).addItem(item.menuItem),
            onDecrement: () =>
                ref.read(cartProvider.notifier).removeItem(item.menuItem),
            height: 30,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: Text(
              '₹${item.subtotal.toStringAsFixed(0)}',
              style: AppTextStyles.price.copyWith(fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bill preview with QR ────────────────────────────────────────────────────
class _BillPreview extends StatelessWidget {
  final CartState cart;
  final String upiData;

  const _BillPreview({required this.cart, required this.upiData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.maroon.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo + shop name
          const AppLogo(size: 56),
          const SizedBox(height: 4),
          Text(QrService.kShopName,
              style: AppTextStyles.wordmark.copyWith(fontSize: 22)),
          const Divider(height: 20),

          // Item list
          ...cart.itemList.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${e.menuItem.name} ×${e.quantity}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textPrimaryLight),
                      ),
                    ),
                    Text(
                      '₹${e.subtotal.toStringAsFixed(2)}',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )),
          const Divider(height: 16),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.maroon)),
              Text(
                '₹${cart.totalAmount.toStringAsFixed(2)}',
                style: AppTextStyles.priceTotal
                    .copyWith(color: AppColors.maroon, fontSize: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // QR Code
          Text('Scan to pay via UPI',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondaryLight)),
          const SizedBox(height: 8),
          QrImageView(
            data: upiData,
            version: QrVersions.auto,
            size: 160,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.maroon,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(QrService.kShopUpiId,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondaryLight)),
        ],
      ),
    );
  }
}

// ── Empty cart ──────────────────────────────────────────────────────────────
class _EmptyCart extends StatelessWidget {
  final VoidCallback onBack;
  const _EmptyCart({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 72,
              color: AppColors.textSecondaryDark.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('Your cart is empty',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: AppColors.textSecondaryDark)),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Back to Menu', onPressed: onBack),
        ],
      ),
    );
  }
}
