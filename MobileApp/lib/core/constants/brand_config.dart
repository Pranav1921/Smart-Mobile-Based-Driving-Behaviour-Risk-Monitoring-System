import 'package:flutter/material.dart';

class EnterpriseBrandConfig {
  final String id;
  final String name;
  final String logoText;
  final Color primaryColor;
  final Color secondaryColor;
  final Color darkBg;
  final String sdkNotice;

  const EnterpriseBrandConfig({
    required this.id,
    required this.name,
    required this.logoText,
    required this.primaryColor,
    required this.secondaryColor,
    required this.darkBg,
    required this.sdkNotice,
  });
}

class BrandRepository {
  static const Map<String, EnterpriseBrandConfig> brands = {
    'swiggy': EnterpriseBrandConfig(
      id: 'swiggy',
      name: 'Swiggy Fleet',
      logoText: 'SWIGGY DRIVER',
      primaryColor: Color(0xFF1E4D3B),
      secondaryColor: Color(0xFF2A6650),
      darkBg: Color(0xFF0F172A),
      sdkNotice: 'SmartDrive Telemetry active in background for Swiggy Partner App',
    ),
    'zomato': EnterpriseBrandConfig(
      id: 'zomato',
      name: 'Zomato & Blinkit',
      logoText: 'ZOMATO PARTNER',
      primaryColor: Color(0xFF1E4D3B),
      secondaryColor: Color(0xFF2A6650),
      darkBg: Color(0xFF0F172A),
      sdkNotice: 'SmartDrive Telemetry active in background for Zomato Delivery App',
    ),
    'amazon': EnterpriseBrandConfig(
      id: 'amazon',
      name: 'Amazon Logistics',
      logoText: 'AMAZON FLEX',
      primaryColor: Color(0xFF1E4D3B),
      secondaryColor: Color(0xFF2A6650),
      darkBg: Color(0xFF0F172A),
      sdkNotice: 'SmartDrive Telemetry active in background for Amazon Logistics',
    ),
    'porter': EnterpriseBrandConfig(
      id: 'porter',
      name: 'Porter Freight',
      logoText: 'PORTER PARTNER',
      primaryColor: Color(0xFF1E4D3B),
      secondaryColor: Color(0xFF2A6650),
      darkBg: Color(0xFF0F172A),
      sdkNotice: 'SmartDrive Telemetry active in background for Porter Driver App',
    ),
    'delhivery': EnterpriseBrandConfig(
      id: 'delhivery',
      name: 'Delhivery Express',
      logoText: 'DELHIVERY CARGO',
      primaryColor: Color(0xFF1E4D3B),
      secondaryColor: Color(0xFF2A6650),
      darkBg: Color(0xFF0F172A),
      sdkNotice: 'SmartDrive Telemetry active in background for Delhivery Driver',
    ),
    'bluedart': EnterpriseBrandConfig(
      id: 'bluedart',
      name: 'BlueDart DHL',
      logoText: 'BLUEDART DHL',
      primaryColor: Color(0xFF1E4D3B),
      secondaryColor: Color(0xFF2A6650),
      darkBg: Color(0xFF0F172A),
      sdkNotice: 'SmartDrive Telemetry active in background for BlueDart Express',
    ),
  };

  static EnterpriseBrandConfig getBrand(String? brandId) {
    if (brandId != null && brands.containsKey(brandId.toLowerCase())) {
      return brands[brandId.toLowerCase()]!;
    }
    return brands['swiggy']!;
  }
}
