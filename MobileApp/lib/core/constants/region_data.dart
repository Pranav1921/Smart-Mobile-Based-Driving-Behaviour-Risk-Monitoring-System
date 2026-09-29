class RegionOption {
  final String id;
  final String name;
  final String district;
  final String state;
  final String country;
  final double lat;
  final double lng;

  const RegionOption({
    required this.id,
    required this.name,
    required this.district,
    required this.state,
    this.country = 'India',
    required this.lat,
    required this.lng,
  });
}

class CountryOption {
  final String code;
  final String name;
  final String flag;
  final List<StateOption> states;

  const CountryOption({
    required this.code,
    required this.name,
    required this.flag,
    required this.states,
  });
}

class StateOption {
  final String code;
  final String name;
  final List<DistrictOption> districts;

  const StateOption({
    required this.code,
    required this.name,
    required this.districts,
  });
}

class DistrictOption {
  final String name;
  final List<HubOption> hubs;

  const DistrictOption({
    required this.name,
    required this.hubs,
  });
}

class HubOption {
  final String id;
  final String name;
  final String code;
  final double lat;
  final double lng;

  const HubOption({
    required this.id,
    required this.name,
    required this.code,
    required this.lat,
    required this.lng,
  });
}

class RegionRepository {
  static const List<CountryOption> hierarchy = [
    CountryOption(
      code: 'IN',
      name: 'India',
      flag: '🇮🇳',
      states: [
        StateOption(
          code: 'KA',
          name: 'Karnataka',
          districts: [
            DistrictOption(
              name: 'Dakshina Kannada',
              hubs: [
                HubOption(id: 'puttur_taluk', name: 'Puttur Command Hub', code: 'PTR-01', lat: 12.7749, lng: 75.2023),
                HubOption(id: 'kadaba_taluk', name: 'Kadaba Logistics Hub', code: 'KDB-02', lat: 12.5700, lng: 75.3200),
                HubOption(id: 'bantwal_taluk', name: 'Bantwal Transport Hub', code: 'BTW-03', lat: 12.8950, lng: 75.0340),
                HubOption(id: 'belthangady_taluk', name: 'Belthangady Sector', code: 'BLT-04', lat: 12.9980, lng: 75.2570),
                HubOption(id: 'sullia_taluk', name: 'Sullia Fleet Depot', code: 'SLA-05', lat: 12.5620, lng: 75.3880),
                HubOption(id: 'mangaluru_taluk', name: 'Mangaluru Central Hub', code: 'MLR-HQ', lat: 12.9141, lng: 74.8560),
              ],
            ),
            DistrictOption(
              name: 'Bengaluru Urban',
              hubs: [
                HubOption(id: 'bengaluru_central', name: 'Bengaluru Central Depot', code: 'BLR-01', lat: 12.9716, lng: 77.5946),
                HubOption(id: 'electronic_city', name: 'Electronic City Tech Hub', code: 'BLR-02', lat: 12.8452, lng: 77.6602),
                HubOption(id: 'whitefield_depot', name: 'Whitefield Industrial Depot', code: 'BLR-03', lat: 12.9698, lng: 77.7500),
                HubOption(id: 'peenya_industrial', name: 'Peenya Logistics Sector', code: 'BLR-04', lat: 13.0285, lng: 77.5197),
              ],
            ),
            DistrictOption(
              name: 'Udupi',
              hubs: [
                HubOption(id: 'udupi_taluk', name: 'Udupi Transit Hub', code: 'UDP-01', lat: 13.3409, lng: 74.7421),
                HubOption(id: 'manipal_hub', name: 'Manipal Fleet Center', code: 'MNP-02', lat: 13.3525, lng: 74.7864),
                HubOption(id: 'kundapura_hub', name: 'Kundapura Sector', code: 'KND-03', lat: 13.6268, lng: 74.6917),
              ],
            ),
            DistrictOption(
              name: 'Mysuru',
              hubs: [
                HubOption(id: 'mysuru_central', name: 'Mysuru Central Hub', code: 'MYS-01', lat: 12.2958, lng: 76.6394),
                HubOption(id: 'nanjangud_depot', name: 'Nanjangud Industrial Hub', code: 'MYS-02', lat: 12.1190, lng: 76.6810),
              ],
            ),
          ],
        ),
        StateOption(
          code: 'MH',
          name: 'Maharashtra',
          districts: [
            DistrictOption(
              name: 'Mumbai Suburban',
              hubs: [
                HubOption(id: 'andheri_freight', name: 'Andheri Freight Terminal', code: 'BOM-01', lat: 19.1136, lng: 72.8697),
                HubOption(id: 'bkc_express', name: 'BKC Express Station', code: 'BOM-02', lat: 19.0660, lng: 72.8688),
                HubOption(id: 'navi_mumbai_depot', name: 'Navi Mumbai Depot', code: 'BOM-03', lat: 19.0330, lng: 73.0297),
              ],
            ),
            DistrictOption(
              name: 'Pune',
              hubs: [
                HubOption(id: 'pune_central', name: 'Pune Cargo Station', code: 'PNQ-01', lat: 18.5204, lng: 73.8567),
                HubOption(id: 'hinjawadi_hub', name: 'Hinjawadi Tech Depot', code: 'PNQ-02', lat: 18.5913, lng: 73.7389),
              ],
            ),
          ],
        ),
        StateOption(
          code: 'TN',
          name: 'Tamil Nadu',
          districts: [
            DistrictOption(
              name: 'Chennai',
              hubs: [
                HubOption(id: 'chennai_port', name: 'Chennai Port Terminal', code: 'MAA-01', lat: 13.0827, lng: 80.2707),
                HubOption(id: 'guindy_industrial', name: 'Guindy Industrial Hub', code: 'MAA-02', lat: 13.0067, lng: 80.2023),
              ],
            ),
            DistrictOption(
              name: 'Coimbatore',
              hubs: [
                HubOption(id: 'coimbatore_central', name: 'Coimbatore Central Depot', code: 'CJB-01', lat: 11.0168, lng: 76.9558),
              ],
            ),
          ],
        ),
        StateOption(
          code: 'KL',
          name: 'Kerala',
          districts: [
            DistrictOption(
              name: 'Kasaragod',
              hubs: [
                HubOption(id: 'kasaragod_hub', name: 'Kasaragod North Hub', code: 'KSD-01', lat: 12.5102, lng: 74.9852),
                HubOption(id: 'kanhangad_sector', name: 'Kanhangad Sector', code: 'KSD-02', lat: 12.3080, lng: 75.0930),
              ],
            ),
            DistrictOption(
              name: 'Ernakulam (Kochi)',
              hubs: [
                HubOption(id: 'kochi_port_hub', name: 'Kochi Logistics Hub', code: 'COK-01', lat: 9.9312, lng: 76.2673),
              ],
            ),
          ],
        ),
        StateOption(
          code: 'DL',
          name: 'Delhi NCR',
          districts: [
            DistrictOption(
              name: 'Central Delhi',
              hubs: [
                HubOption(id: 'connaught_hub', name: 'Central Delhi Operations', code: 'DEL-01', lat: 28.6315, lng: 77.2167),
              ],
            ),
            DistrictOption(
              name: 'Gurugram',
              hubs: [
                HubOption(id: 'cyber_city_fleet', name: 'Cyber City Fleet Center', code: 'GGN-01', lat: 28.4595, lng: 77.0266),
              ],
            ),
          ],
        ),
      ],
    ),
    CountryOption(
      code: 'AE',
      name: 'United Arab Emirates',
      flag: '🇦🇪',
      states: [
        StateOption(
          code: 'DXB',
          name: 'Dubai',
          districts: [
            DistrictOption(
              name: 'Dubai Central',
              hubs: [
                HubOption(id: 'jebel_ali_port', name: 'Jebel Ali Port Logistics', code: 'DXB-01', lat: 25.0113, lng: 55.0612),
                HubOption(id: 'deira_terminal', name: 'Deira Freight Center', code: 'DXB-02', lat: 25.2697, lng: 55.3095),
              ],
            ),
          ],
        ),
        StateOption(
          code: 'AUH',
          name: 'Abu Dhabi',
          districts: [
            DistrictOption(
              name: 'Abu Dhabi Capital',
              hubs: [
                HubOption(id: 'khalifa_port', name: 'Khalifa Port Depot', code: 'AUH-01', lat: 24.8167, lng: 54.7167),
              ],
            ),
          ],
        ),
      ],
    ),
    CountryOption(
      code: 'US',
      name: 'United States',
      flag: '🇺🇸',
      states: [
        StateOption(
          code: 'CA',
          name: 'California',
          districts: [
            DistrictOption(
              name: 'Los Angeles',
              hubs: [
                HubOption(id: 'la_port_terminal', name: 'Port of LA Logistics', code: 'LAX-01', lat: 33.7432, lng: -118.2673),
              ],
            ),
            DistrictOption(
              name: 'San Francisco Bay',
              hubs: [
                HubOption(id: 'oakland_freight', name: 'Oakland Freight Depot', code: 'OAK-01', lat: 37.8044, lng: -122.2712),
              ],
            ),
          ],
        ),
        StateOption(
          code: 'TX',
          name: 'Texas',
          districts: [
            DistrictOption(
              name: 'Houston Metro',
              hubs: [
                HubOption(id: 'houston_ship_channel', name: 'Houston Port Logistics', code: 'HOU-01', lat: 29.7604, lng: -95.3698),
              ],
            ),
          ],
        ),
      ],
    ),
    CountryOption(
      code: 'GB',
      name: 'United Kingdom',
      flag: '🇬🇧',
      states: [
        StateOption(
          code: 'ENG',
          name: 'England',
          districts: [
            DistrictOption(
              name: 'Greater London',
              hubs: [
                HubOption(id: 'london_gateway', name: 'London Gateway Port', code: 'LON-01', lat: 51.5074, lng: -0.1278),
              ],
            ),
          ],
        ),
      ],
    ),
  ];

  static const List<RegionOption> regions = [
    RegionOption(
      id: 'puttur_taluk',
      name: 'Puttur Taluk',
      district: 'Dakshina Kannada',
      state: 'Karnataka',
      lat: 12.7749,
      lng: 75.2023,
    ),
    RegionOption(
      id: 'mangaluru_taluk',
      name: 'Mangaluru Taluk',
      district: 'Dakshina Kannada',
      state: 'Karnataka',
      lat: 12.9141,
      lng: 74.8560,
    ),
    RegionOption(
      id: 'bantwal_taluk',
      name: 'Bantwal Taluk',
      district: 'Dakshina Kannada',
      state: 'Karnataka',
      lat: 12.8950,
      lng: 75.0340,
    ),
    RegionOption(
      id: 'kadaba',
      name: 'Kadaba Taluk',
      district: 'Dakshina Kannada',
      state: 'Karnataka',
      lat: 12.5700,
      lng: 75.3200,
    ),
    RegionOption(
      id: 'bengaluru_central',
      name: 'Bengaluru Central',
      district: 'Bengaluru Urban',
      state: 'Karnataka',
      lat: 12.9716,
      lng: 77.5946,
    ),
    RegionOption(
      id: 'udupi_taluk',
      name: 'Udupi Taluk',
      district: 'Udupi',
      state: 'Karnataka',
      lat: 13.3409,
      lng: 74.7421,
    ),
  ];

  static RegionOption getRegion(String? id) {
    if (id != null) {
      final match = regions.firstWhere(
        (r) => r.id == id || r.name.toLowerCase() == id.toLowerCase(),
        orElse: () => regions[0],
      );
      return match;
    }
    return regions[0];
  }
}
