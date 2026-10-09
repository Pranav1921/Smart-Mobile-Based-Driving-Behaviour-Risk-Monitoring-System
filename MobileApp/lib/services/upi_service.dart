import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Robust service to initiate 100% FREE Direct Bank-to-Bank UPI Payments
/// using official NPCI standard intent schemes (0% gateway fees).
class UpiService {
  /// Builds standard NPCI compliant UPI URI
  static String buildUpiUriString({
    required String upiId,
    required String payeeName,
    required double amount,
    String? note,
    String? transactionRef,
  }) {
    final cleanUpi = upiId.trim();
    final cleanName = Uri.encodeComponent(payeeName.trim());
    final cleanNote = Uri.encodeComponent(note?.trim() ?? 'Fleet Settlement');
    final formattedAmt = amount.toStringAsFixed(2);
    final ref = transactionRef ?? 'TXN${DateTime.now().millisecondsSinceEpoch}';

    return 'upi://pay?pa=$cleanUpi&pn=$cleanName&am=$formattedAmt&cu=INR&tn=$cleanNote&tr=$ref';
  }

  /// Launches installed UPI app (Google Pay, PhonePe, Paytm, BHIM, Cred, etc.)
  /// Directly handles bank-to-bank transfer at ₹0 merchant fee.
  static Future<bool> launchDirectUpiPayment({
    required String upiId,
    required String payeeName,
    required double amount,
    String? note,
    String? transactionRef,
    BuildContext? context,
  }) async {
    final uriString = buildUpiUriString(
      upiId: upiId,
      payeeName: payeeName,
      amount: amount,
      note: note,
      transactionRef: transactionRef,
    );

    try {
      final uri = Uri.parse(uriString);
      if (await url_launcher.canLaunchUrl(uri)) {
        final launched = await url_launcher.launchUrl(
          uri,
          mode: url_launcher.LaunchMode.externalApplication,
        );
        if (launched) {
          if (context != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '⚡ Opening UPI App to transfer ₹${amount.toStringAsFixed(2)} to $payeeName...',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: const Color(0xFF059669),
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return true;
        }
      }
    } catch (e) {
      debugPrint('[UpiService] Error launching direct UPI scheme: $e');
    }

    // Fallback: If intent fails on desktop or unsupported device, prompt user
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No external UPI app found. Direct UPI transfer requires an Android/iOS device with GPay, PhonePe, or Paytm installed.',
          ),
          backgroundColor: Colors.amber.shade900,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }
}
