import 'package:url_launcher/url_launcher.dart';

enum DriverType { TACTICAL, STANDARD }

typedef DriverModel = DriverProfile;

class DriverProfile {
  final String name;
  final String email;
  final String phoneNumber;
  final String companyCode;
  final String driverId;
  final String industry;
  final String vehicleType;
  final String vehicleName;
  final String vehiclePlateNumber;
  final String regionId;
  final double currentSafetyScore;
  final bool isOnboarded;
  final int xp;
  final int level;
  final int streak;
  final List<String> badges;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String licenseNumber;
  final int yearsExperience;
  final String bloodGroup;

  // Family Information & WhatsApp Shield
  final String familyMemberName;
  final String familyRelationship;
  final String familyWhatsappNumber;
  final String familyAddress;

  // Use private fields with fallback getters to handle legacy session data gracefully
  final String? _profileImagePath;
  String get profileImagePath => _profileImagePath ?? '';

  final DriverType? _driverType;
  DriverType get driverType => _driverType ?? DriverType.TACTICAL;

  // Alias for safetyScore
  double get safetyScore => currentSafetyScore;

  DriverProfile({
    required this.name,
    this.email = '',
    this.phoneNumber = '',
    required this.companyCode,
    required this.driverId,
    required this.industry,
    required this.vehicleType,
    required this.vehicleName,
    required this.vehiclePlateNumber,
    this.regionId = 'puttur_taluk',
    this.currentSafetyScore = 100.0,
    this.isOnboarded = false,
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    this.badges = const [],
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.licenseNumber = '',
    this.yearsExperience = 0,
    this.bloodGroup = 'O+',
    this.familyMemberName = '',
    this.familyRelationship = 'Spouse / Parent',
    this.familyWhatsappNumber = '',
    this.familyAddress = '',
    String? profileImagePath,
    DriverType driverType = DriverType.TACTICAL,
  })  : _driverType = driverType,
        _profileImagePath = profileImagePath ?? '';

  DriverProfile copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? companyCode,
    String? driverId,
    String? industry,
    String? vehicleType,
    String? vehicleName,
    String? vehiclePlateNumber,
    String? regionId,
    double? currentSafetyScore,
    bool? isOnboarded,
    int? xp,
    int? streak,
    List<String>? badges,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? licenseNumber,
    int? yearsExperience,
    String? bloodGroup,
    String? familyMemberName,
    String? familyRelationship,
    String? familyWhatsappNumber,
    String? familyAddress,
    String? profileImagePath,
    DriverType? driverType,
  }) {
    return DriverProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      companyCode: companyCode ?? this.companyCode,
      driverId: driverId ?? this.driverId,
      industry: industry ?? this.industry,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleName: vehicleName ?? this.vehicleName,
      vehiclePlateNumber: vehiclePlateNumber ?? this.vehiclePlateNumber,
      regionId: regionId ?? this.regionId,
      currentSafetyScore: currentSafetyScore ?? this.currentSafetyScore,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      badges: badges ?? this.badges,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      familyMemberName: familyMemberName ?? this.familyMemberName,
      familyRelationship: familyRelationship ?? this.familyRelationship,
      familyWhatsappNumber: familyWhatsappNumber ?? this.familyWhatsappNumber,
      familyAddress: familyAddress ?? this.familyAddress,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      driverType: driverType ?? this.driverType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'companyCode': companyCode,
      'driverId': driverId,
      'industry': industry,
      'vehicleType': vehicleType,
      'vehicleName': vehicleName,
      'vehiclePlateNumber': vehiclePlateNumber,
      'regionId': regionId,
      'currentSafetyScore': currentSafetyScore,
      'isOnboarded': isOnboarded,
      'xp': xp,
      'level': level,
      'streak': streak,
      'badges': badges,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'licenseNumber': licenseNumber,
      'yearsExperience': yearsExperience,
      'bloodGroup': bloodGroup,
      'familyMemberName': familyMemberName,
      'familyRelationship': familyRelationship,
      'familyWhatsappNumber': familyWhatsappNumber,
      'familyAddress': familyAddress,
      'profileImagePath': profileImagePath,
      'driverType': driverType.name,
    };
  }

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      companyCode: json['companyCode'] ?? '',
      driverId: json['driverId'] ?? '',
      industry: json['industry'] ?? 'Logistics',
      vehicleType: json['vehicleType'] ?? 'Van',
      vehicleName: json['vehicleName'] ?? '',
      vehiclePlateNumber: json['vehiclePlateNumber'] ?? '',
      regionId: json['regionId'] ?? (json['zone'] != null && json['zone'].toString().toLowerCase().contains('kadaba') ? 'kadaba' : (json['zone'] != null && json['zone'].toString().toLowerCase().contains('puttur') ? 'puttur' : json['zone'] ?? json['region'] ?? 'puttur_taluk')),
      currentSafetyScore: (json['currentSafetyScore'] as num?)?.toDouble() ?? 100.0,
      isOnboarded: json['isOnboarded'] ?? false,
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      streak: json['streak'] ?? 0,
      badges: List<String>.from(json['badges'] ?? []),
      emergencyContactName: json['emergencyContactName'] ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      yearsExperience: json['yearsExperience'] ?? 0,
      bloodGroup: json['bloodGroup'] ?? 'O+',
      familyMemberName: json['familyMemberName'] ?? '',
      familyRelationship: json['familyRelationship'] ?? 'Spouse / Parent',
      familyWhatsappNumber: json['familyWhatsappNumber'] ?? '',
      familyAddress: json['familyAddress'] ?? '',
      profileImagePath: json['profileImagePath'] ?? '',
      driverType: json['driverType'] == 'STANDARD' ? DriverType.STANDARD : DriverType.TACTICAL,
    );
  }

  factory DriverProfile.empty() {
    return DriverProfile(
      name: '',
      email: '',
      phoneNumber: '',
      companyCode: '',
      driverId: '',
      industry: 'Logistics',
      vehicleType: 'Van',
      vehicleName: '',
      vehiclePlateNumber: '',
      regionId: 'puttur_taluk',
      currentSafetyScore: 100.0,
      isOnboarded: false,
      xp: 0,
      level: 1,
      streak: 0,
      badges: const [],
      emergencyContactName: '',
      emergencyContactPhone: '',
      licenseNumber: '',
      yearsExperience: 0,
      bloodGroup: 'O+',
      familyMemberName: '',
      familyRelationship: 'Spouse / Parent',
      familyWhatsappNumber: '',
      familyAddress: '',
      profileImagePath: '',
      driverType: DriverType.TACTICAL,
    );
  }

  /// Launch direct WhatsApp chat with driver's registered family member
  Future<bool> openFamilyWhatsapp({String? customMessage}) async {
    final rawNumber = familyWhatsappNumber.isNotEmpty ? familyWhatsappNumber : emergencyContactPhone;
    if (rawNumber.isEmpty) return false;
    final cleanNumber = rawNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final msg = Uri.encodeComponent(
      customMessage ?? "Hi ${familyMemberName.isNotEmpty ? familyMemberName : 'Family'}, I am currently on duty driving safely with the Smart Driving System. My safety score is ${currentSafetyScore.toInt()}%.",
    );
    final url = Uri.parse("https://wa.me/$cleanNumber?text=$msg");
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
