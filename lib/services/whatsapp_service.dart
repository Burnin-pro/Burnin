import 'package:url_launcher/url_launcher.dart';

/// Handles WhatsApp deep-link generation and sending.
/// Uses wa.me free tier — no WhatsApp Business API needed.
class WhatsAppService {
  WhatsAppService._();
  static final WhatsAppService instance = WhatsAppService._();

  /// Build a wa.me URL for the given phone number and pre-filled message text.
  /// [phone] should be in E.164 format without '+': e.g. '919876543210'
  Uri buildWaLink({required String phone, required String message}) {
    final encodedMessage = Uri.encodeComponent(message);
    return Uri.parse('https://wa.me/$phone?text=$encodedMessage');
  }

  /// Open WhatsApp with a pre-filled bill text for [phone].
  /// [phone] can be '9876543210' (10 digits) — we prefix +91.
  Future<bool> sendBill({
    required String phone,
    required String billText,
  }) async {
    // Normalise: strip non-digits, prefix 91 if needed
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final e164 = digits.startsWith('91') ? digits : '91$digits';

    final uri = buildWaLink(phone: e164, message: billText);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    throw Exception('WhatsApp is not installed or link cannot be opened.');
  }

  /// Format a plain-text bill summary for the WhatsApp message body.
  String formatBillText({
    required String shopName,
    required List<({String name, int qty, double price})> items,
    required double total,
  }) {
    final sb = StringBuffer();
    sb.writeln('🔥 *$shopName* — Your Bill');
    sb.writeln('─' * 28);
    for (final item in items) {
      final subtotal = (item.qty * item.price).toStringAsFixed(2);
      sb.writeln('${item.name} x${item.qty}  ₹$subtotal');
    }
    sb.writeln('─' * 28);
    sb.writeln('*Total: ₹${total.toStringAsFixed(2)}*');
    sb.writeln();
    sb.writeln('Please scan the UPI QR code to pay. Thank you! 🙏');
    return sb.toString();
  }
}
