import 'event_model.dart';

class DriverTrip {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceKm;
  final int durationSeconds;
  final double averageSpeed;
  final double maxSpeed;
  final double safetyScore;
  final List<SafetyEvent> events;
  final List<List<double>> routeCoordinates; // [[lat, lng], [lat, lng], ...]
  final String industry;
  final String vehicleName;
  final String? deliveryFrom;
  final String? deliveryTo;
  final String? orderItems;
  final String? orderId;
  final double? payout;
  final int? pointsEarned;

  DriverTrip({
    required this.id,
    required this.startTime,
    this.endTime,
    this.distanceKm = 0.0,
    this.durationSeconds = 0,
    this.averageSpeed = 0.0,
    this.maxSpeed = 0.0,
    this.safetyScore = 100.0,
    required this.events,
    required this.routeCoordinates,
    required this.industry,
    required this.vehicleName,
    this.deliveryFrom,
    this.deliveryTo,
    this.orderItems,
    this.orderId,
    this.payout,
    this.pointsEarned,
  });

  double get earnedPayout => payout ?? (distanceKm > 0 ? (distanceKm * 15.0) : 75.0);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'distanceKm': distanceKm,
      'durationSeconds': durationSeconds,
      'averageSpeed': averageSpeed,
      'maxSpeed': maxSpeed,
      'safetyScore': safetyScore,
      'events': events.map((e) => e.toJson()).toList(),
      'routeCoordinates': routeCoordinates,
      'industry': industry,
      'vehicleName': vehicleName,
      'deliveryFrom': deliveryFrom,
      'deliveryTo': deliveryTo,
      'orderItems': orderItems,
      'orderId': orderId,
      'payout': earnedPayout,
      'pointsEarned': pointsEarned,
    };
  }

  factory DriverTrip.fromJson(Map<String, dynamic> json) {
    var rawEvents = json['events'] as List? ?? [];
    List<SafetyEvent> parsedEvents = rawEvents.map((e) => SafetyEvent.fromJson(e)).toList();

    var rawCoords = json['routeCoordinates'] as List? ?? [];
    List<List<double>> coords = rawCoords.map((c) {
      List<dynamic> doubleList = c as List;
      return [doubleList[0] as double, doubleList[1] as double];
    }).toList();

    return DriverTrip(
      id: json['id'] ?? '',
      startTime: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: json['durationSeconds'] ?? 0,
      averageSpeed: (json['averageSpeed'] as num?)?.toDouble() ?? 0.0,
      maxSpeed: (json['maxSpeed'] as num?)?.toDouble() ?? 0.0,
      safetyScore: (json['safetyScore'] as num?)?.toDouble() ?? 100.0,
      events: parsedEvents,
      routeCoordinates: coords,
      industry: json['industry'] ?? 'Logistics',
      vehicleName: json['vehicleName'] ?? 'Unknown Vehicle',
      deliveryFrom: json['deliveryFrom'],
      deliveryTo: json['deliveryTo'],
      orderItems: json['orderItems'],
      orderId: json['orderId'],
      payout: (json['payout'] as num?)?.toDouble() ?? (json['distanceKm'] != null && (json['distanceKm'] as num) > 0 ? ((json['distanceKm'] as num).toDouble() * 15.0) : 75.0),
      pointsEarned: json['pointsEarned'] as int?,
    );
  }
}
