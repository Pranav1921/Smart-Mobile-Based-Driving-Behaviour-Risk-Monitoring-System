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
  });

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
    };
  }

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    return DeliveryOrder(
      id: json['id'] ?? '',
      pickupAddress: json['pickupAddress'] ?? '',
      dropAddress: json['dropAddress'] ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      estimatedTimeMinutes: json['estimatedTimeMinutes'] ?? 0,
      payoutAmount: (json['payoutAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'available',
      pickupLat: (json['pickupLat'] as num?)?.toDouble() ?? 0.0,
      pickupLng: (json['pickupLng'] as num?)?.toDouble() ?? 0.0,
      dropLat: (json['dropLat'] as num?)?.toDouble() ?? 0.0,
      dropLng: (json['dropLng'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
