import 'package:intl/intl.dart';

class CurrencyUtil {
  static String format(double amount, {String? regionId}) {
    // Default to INR for Indian users (puttur_taluk is in India)
    String locale = 'en_IN';
    String symbol = '₹';

    // If region is not the default Indian one, we could switch,
    // but the requirement is "make it rupees it for indian mianly"
    if (regionId != null && regionId.contains('us')) {
      locale = 'en_US';
      symbol = '\$';
    }

    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 2,
    );

    return formatter.format(amount);
  }
}
