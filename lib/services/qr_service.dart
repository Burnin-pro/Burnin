/// QR code data builder for UPI payments.
/// The actual QR widget rendering is done by [qr_flutter] in the UI layer.
/// This service only builds the correctly-formatted UPI deep-link string.
class QrService {
  QrService._();
  static final QrService instance = QrService._();

  // ── Shop Configuration ────────────────────────────────────────────────────
  // TODO: Replace this with the real shop UPI ID before going live.
  static const String kShopUpiId = 'yourshop@upi';
  static const String kShopName = 'Burnin Hotfire';
  static const String kShopUpiNote = 'BurnIn Order Payment';

  // ──────────────────────────────────────────────────────────────────────────

  /// Build a UPI payment URI string suitable for encoding as a QR code.
  ///
  /// Format: `upi://pay?pa=<UPI_ID>&pn=<NAME>&am=<AMOUNT>&cu=INR&tn=<NOTE>`
  ///
  /// This follows the NPCI UPI deep-link specification and is scannable by
  /// any UPI app (GPay, PhonePe, Paytm, etc.).
  String buildUpiQrData({
    required double amount,
    String? note,
    String? upiId,
    String? payeeName,
  }) {
    final pa = Uri.encodeComponent(upiId ?? kShopUpiId);
    final pn = Uri.encodeComponent(payeeName ?? kShopName);
    final am = amount.toStringAsFixed(2);
    final tn = Uri.encodeComponent(note ?? kShopUpiNote);

    return 'upi://pay?pa=$pa&pn=$pn&am=$am&cu=INR&tn=$tn';
  }

  /// Helper: returns just the UPI ID being used (for display in profile/settings).
  String get currentUpiId => kShopUpiId;
}
