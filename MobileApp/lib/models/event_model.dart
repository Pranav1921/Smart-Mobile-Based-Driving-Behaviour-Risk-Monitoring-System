class SafetyEvent {
  final String id;
  final String type; // Harsh Braking, Overspeed, Rapid Acceleration, Sharp Turn, Phone Usage, Pothole, Crash
  final DateTime timestamp;
  final String severity; // Low, Medium, High
  final double latitude;
  final double longitude;
  final double triggerValue; // G-force value or speed exceeded
  final String aiTip;

  SafetyEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.triggerValue,
    required this.aiTip,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'severity': severity,
      'latitude': latitude,
      'longitude': longitude,
      'triggerValue': triggerValue,
      'aiTip': aiTip,
    };
  }

  factory SafetyEvent.fromJson(Map<String, dynamic> json) {
    return SafetyEvent(
      id: json['id'] ?? '',
      type: json['type'] ?? 'Unknown',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      severity: json['severity'] ?? 'Medium',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      triggerValue: (json['triggerValue'] as num?)?.toDouble() ?? 0.0,
      aiTip: json['aiTip'] ?? '',
    );
  }
}
