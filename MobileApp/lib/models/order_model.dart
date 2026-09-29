import 'package:url_launcher/url_launcher.dart' as url_launcher;

class DeliveryOrder {
  final String id;
  final String pickupAddress;
  final String dropAddress;
  final double distanceKm;
  final int estimatedTimeMinutes;
  final double payoutAmount;
  final String status; // 'available', 'accepted', 'rejected', 'completed'
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;
  final String packageItems;
  final String driverName;
  final String driverPhone;
  final String driverAddress;
  final String customerName;
  final String customerPhone;

  DeliveryOrder({
    required this.id,
    required this.pickupAddress,
    required this.dropAddress,
    required this.distanceKm,
    required this.estimatedTimeMinutes,
    required this.payoutAmount,
    this.status = 'available',
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
    this.packageItems = 'Tactical Logistics Package',
    this.driverName = 'Pranav Kumar (Agent #402)',
    this.driverPhone = '+91 98451 23098',
    this.driverAddress = 'Sector 4 Depot Hub',
    this.customerName = 'Kavya Sharma',
    this.customerPhone = '+91 94482 67119',
  });

  /// Dial the delivery driver's phone number directly
  Future<bool> callDriver() async {
    return _makePhoneCall(driverPhone);
  }

  /// Dial the customer's phone number directly
  Future<bool> callCustomer() async {
    return _makePhoneCall(customerPhone);
  }

  static Future<bool> _makePhoneCall(String rawPhone) async {
    try {
      final clean = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
      final uri = Uri.parse('tel:$clean');
      if (await url_launcher.canLaunchUrl(uri)) {
        return await url_launcher.launchUrl(uri);
      }
    } catch (_) {}
    return false;
  }

  DeliveryOrder copyWith({
    String? id,
    String? pickupAddress,
    String? dropAddress,
    double? distanceKm,
    int? estimatedTimeMinutes,
    double? payoutAmount,
    String? status,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
    String? packageItems,
    String? driverName,
    String? driverPhone,
    String? driverAddress,
    String? customerName,
    String? customerPhone,
  }) {
    return DeliveryOrder(
      id: id ?? this.id,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropAddress: dropAddress ?? this.dropAddress,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      payoutAmount: payoutAmount ?? this.payoutAmount,
      status: status ?? this.status,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropLat: dropLat ?? this.dropLat,
      dropLng: dropLng ?? this.dropLng,
      packageItems: packageItems ?? this.packageItems,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverAddress: driverAddress ?? this.driverAddress,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pickupAddress': pickupAddress,
      'dropAddress': dropAddress,
      'distanceKm': distanceKm,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'payoutAmount': payoutAmount,
      'status': status,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropLat': dropLat,
      'dropLng': dropLng,
      'packageItems': packageItems,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverAddress': driverAddress,
      'customerName': customerName,
      'customerPhone': customerPhone,
    };
  }

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    final location = json['deliveryLocation'] as Map<String, dynamic>?;

    return DeliveryOrder(
      id: json['id']?.toString() ?? '',
      pickupAddress: json['deliveryFrom'] ?? 'Main Logistics Depot',
      dropAddress: location?['address'] ?? json['deliveryTo'] ?? 'Customer Destination',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 8.5,
      estimatedTimeMinutes: json['estimatedTimeMinutes'] as int? ?? 18,
      payoutAmount: (json['amount'] as num?)?.toDouble() ?? 25.0,
      status: json['status']?.toString().toLowerCase() ?? 'available',
      pickupLat: (json['pickupLat'] as num?)?.toDouble() ?? 12.7749,
      pickupLng: (json['pickupLng'] as num?)?.toDouble() ?? 75.2023,
      dropLat: (location?['latitude'] as num?)?.toDouble() ?? 12.7950,
      dropLng: (location?['longitude'] as num?)?.toDouble() ?? 75.2250,
      packageItems: json['orderItems'] ?? json['packageItems'] ?? json['items'] ?? 'Tactical Logistics Package',
      driverName: json['driverName'] ?? 'Pranav Kumar (Agent #402)',
      driverPhone: json['driverPhone'] ?? '+91 98451 23098',
      driverAddress: json['driverAddress'] ?? (json['deliveryFrom'] ?? 'Sector 4 Depot Hub'),
      customerName: json['customerName'] ?? 'Kavya Sharma',
      customerPhone: json['customerPhone'] ?? '+91 94482 67119',
    );
  }
}
