class DriverProfile {
  final String name;
  final String companyCode;
  final String driverId;
  final String industry; // Food Delivery, Courier, Logistics, Ride Sharing, Enterprise Fleet
  final String vehicleType; // Scooty, Motorcycle, Car, Van, Truck, Pickup
  final String vehicleName;
  final String vehiclePlateNumber;
  final double currentSafetyScore;
  final bool isOnboarded;
  final int xp;
  final int level;
  final int streak;
  final List<String> badges;

  DriverProfile({
    required this.name,
    required this.companyCode,
    required this.driverId,
    required this.industry,
    required this.vehicleType,
    required this.vehicleName,
    required this.vehiclePlateNumber,
    this.currentSafetyScore = 100.0,
    this.isOnboarded = false,
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    this.badges = const [],
  });

  DriverProfile copyWith({
    String? name,
    String? companyCode,
    String? driverId,
    String? industry,
    String? vehicleType,
    String? vehicleName,
    String? vehiclePlateNumber,
    double? currentSafetyScore,
    bool? isOnboarded,
    int? xp,
    int? level,
    int? streak,
    List<String>? badges,
  }) {
    return DriverProfile(
      name: name ?? this.name,
      companyCode: companyCode ?? this.companyCode,
      driverId: driverId ?? this.driverId,
      industry: industry ?? this.industry,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleName: vehicleName ?? this.vehicleName,
      vehiclePlateNumber: vehiclePlateNumber ?? this.vehiclePlateNumber,
      currentSafetyScore: currentSafetyScore ?? this.currentSafetyScore,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      badges: badges ?? this.badges,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'companyCode': companyCode,
      'driverId': driverId,
      'industry': industry,
      'vehicleType': vehicleType,
      'vehicleName': vehicleName,
      'vehiclePlateNumber': vehiclePlateNumber,
      'currentSafetyScore': currentSafetyScore,
      'isOnboarded': isOnboarded,
      'xp': xp,
      'level': level,
      'streak': streak,
      'badges': badges,
    };
  }

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      name: json['name'] ?? '',
      companyCode: json['companyCode'] ?? '',
      driverId: json['driverId'] ?? '',
      industry: json['industry'] ?? 'Logistics',
      vehicleType: json['vehicleType'] ?? 'Van',
      vehicleName: json['vehicleName'] ?? '',
      vehiclePlateNumber: json['vehiclePlateNumber'] ?? '',
      currentSafetyScore: (json['currentSafetyScore'] as num?)?.toDouble() ?? 100.0,
      isOnboarded: json['isOnboarded'] ?? false,
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      streak: json['streak'] ?? 0,
      badges: List<String>.from(json['badges'] ?? []),
    );
  }

  factory DriverProfile.empty() {
    return DriverProfile(
      name: '',
      companyCode: '',
      driverId: '',
      industry: 'Logistics',
      vehicleType: 'Van',
      vehicleName: '',
      vehiclePlateNumber: '',
      currentSafetyScore: 100.0,
      isOnboarded: false,
      xp: 0,
      level: 1,
      streak: 0,
      badges: const [],
    );
  }
}
