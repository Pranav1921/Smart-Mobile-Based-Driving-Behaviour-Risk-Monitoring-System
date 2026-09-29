import 'dart:convert';

enum TransactionType {
  income,
  expense,
}

enum PaymentCategory {
  fuel,
  maintenance,
  food,
  toll,
  parking,
  supplies,
  upiTransfer,
  tripPayout,
  rewardsRedeem,
  safetyBonus,
  other,
}

enum TransactionStatus {
  success,
  pending,
  failed,
}

class PaymentTransaction {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final TransactionType type;
  final PaymentCategory category;
  final DateTime timestamp;
  final String? upiId;
  final String utrNumber;
  final TransactionStatus status;
  final String paymentMethod;
  final String? notes;

  PaymentTransaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
    required this.category,
    required this.timestamp,
    this.upiId,
    required this.utrNumber,
    this.status = TransactionStatus.success,
    this.paymentMethod = "UPI · State Bank of India (****4821)",
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'amount': amount,
      'type': type.name,
      'category': category.name,
      'timestamp': timestamp.toIso8601String(),
      'upiId': upiId,
      'utrNumber': utrNumber,
      'status': status.name,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      category: PaymentCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => PaymentCategory.other,
      ),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      upiId: json['upiId'],
      utrNumber: json['utrNumber'] ?? '429184719203',
      status: TransactionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TransactionStatus.success,
      ),
      paymentMethod: json['paymentMethod'] ?? "UPI · State Bank of India (****4821)",
      notes: json['notes'],
    );
  }

  static List<PaymentTransaction> getInitialDefaultExpenses() {
    final now = DateTime.now();
    return [
      PaymentTransaction(
        id: 'TXN-882194',
        title: 'IndianOil Fuel Station',
        subtitle: 'Scan & Pay UPI · Petrol / Diesel',
        amount: 350.0,
        type: TransactionType.expense,
        category: PaymentCategory.fuel,
        timestamp: now.subtract(const Duration(hours: 1, minutes: 45)),
        upiId: 'iocl.puttur@oksbi',
        utrNumber: '423985102941',
        paymentMethod: 'UPI · State Bank of India (****4821)',
        notes: '3.4L Vehicle Fuel Refill',
      ),
      PaymentTransaction(
        id: 'TXN-881923',
        title: 'Highway Fastag Toll Plaza',
        subtitle: 'Automated Toll Clearance',
        amount: 45.0,
        type: TransactionType.expense,
        category: PaymentCategory.toll,
        timestamp: now.subtract(const Duration(hours: 3, minutes: 20)),
        upiId: 'fastag.nhai@icici',
        utrNumber: '423982847192',
        paymentMethod: 'UPI · Fastag Linked Wallet',
        notes: 'Puttur Bypass Toll',
      ),
      PaymentTransaction(
        id: 'TXN-880412',
        title: 'Sri Krishna Chai & Refreshments',
        subtitle: 'Scan & Pay UPI · Driver Break',
        amount: 30.0,
        type: TransactionType.expense,
        category: PaymentCategory.food,
        timestamp: now.subtract(const Duration(hours: 4, minutes: 50)),
        upiId: 'srikrishna.tea@paytm',
        utrNumber: '423971938472',
        paymentMethod: 'UPI · State Bank of India (****4821)',
        notes: 'Chai & Snacks during shift',
      ),
    ];
  }
}
