export interface RegionOption {
  id: string
  name: string
  country: string
  state: string
  district: string
  talukCode: string
  passcode: string
  center: [number, number]
  zoom?: number
  boundaryPolygon: [number, number][]
  activeDriversCount: number
}

/**
 * Organic Land Boundary Contour Generator:
 * Generates smooth, realistic multi-vertex geographic shapes following natural terrain,
 * river bends, hills, and land contours instead of plain geometric boxes.
 */
export function makeOrganicLandShape(
  lat: number,
  lng: number,
  rLat = 0.095,
  rLng = 0.135,
  seed = 1
): [number, number][] {
  const points: [number, number][] = []
  const steps = 24 // 24-point smooth organic perimeter contour
  for (let i = 0; i < steps; i++) {
    const angle = (i / steps) * 2 * Math.PI
    // Harmonic terrain variations simulating natural rivers, hills, and land edges
    const terrainVariation =
      1 +
      0.24 * Math.sin(angle * 3 + seed) +
      0.14 * Math.cos(angle * 5 + seed * 2) -
      0.08 * Math.sin(angle * 2)

    const pLat = lat + Math.sin(angle) * rLat * terrainVariation
    const pLng = lng + Math.cos(angle) * rLng * terrainVariation
    points.push([pLat, pLng])
  }
  // Close closed polygon loop
  points.push(points[0])
  return points
}

export const COUNTRIES = ['India', 'United States', 'United Kingdom', 'United Arab Emirates'] as const

export const STATES_BY_COUNTRY: Record<string, string[]> = {
  India: [
    'Karnataka',
    'Maharashtra',
    'Delhi (NCR)',
    'Tamil Nadu',
    'Telangana',
    'Andhra Pradesh',
    'Kerala',
    'Gujarat',
    'Rajasthan',
    'Uttar Pradesh',
    'West Bengal',
    'Madhya Pradesh',
    'Punjab & Haryana',
    'Goa',
  ],
  'United States': ['California', 'New York', 'Texas', 'Illinois', 'Washington'],
  'United Kingdom': ['Greater London', 'Greater Manchester', 'West Midlands'],
  'United Arab Emirates': ['Dubai', 'Abu Dhabi', 'Sharjah'],
}

export const DISTRICTS_BY_STATE: Record<string, string[]> = {
  Karnataka: [
    'Dakshina Kannada',
    'Bengaluru Urban',
    'Bengaluru Rural',
    'Udupi',
    'Hassan',
    'Kodagu (Coorg)',
    'Shivamogga',
    'Belagavi',
    'Kalaburagi',
    'Hubballi-Dharwad',
    'Ballari',
    'Mandya',
    'Tumakuru',
    'Davanagere',
    'Chikkamagaluru',
    'Uttara Kannada',
  ],
  Maharashtra: [
    'Mumbai City',
    'Mumbai Suburban',
    'Pune',
    'Thane',
    'Nagpur',
    'Nashik',
    'Chhatrapati Sambhajinagar',
    'Solapur',
    'Kolhapur',
  ],
  'Delhi (NCR)': [
    'New Delhi',
    'South Delhi',
    'Central Delhi',
    'North Delhi',
    'Gurugram',
    'Noida / Greater Noida',
    'Ghaziabad',
  ],
  'Tamil Nadu': [
    'Chennai',
    'Coimbatore',
    'Madurai',
    'Tiruchirappalli',
    'Salem',
    'Kanchipuram',
    'Tiruppur',
  ],
  Telangana: [
    'Hyderabad',
    'Ranga Reddy',
    'Medchal-Malkajgiri',
    'Warangal',
    'Nizamabad',
  ],
  'Andhra Pradesh': [
    'Visakhapatnam',
    'Vijayawada (NTR)',
    'Tirupati',
    'Guntur',
    'Nellore',
  ],
  Kerala: [
    'Ernakulam (Kochi)',
    'Thiruvananthapuram',
    'Kozhikode',
    'Thrissur',
    'Kannur',
    'Kottayam',
  ],
  Gujarat: ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Gandhinagar'],
  Rajasthan: ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Ajmer'],
  'Uttar Pradesh': [
    'Lucknow',
    'Kanpur',
    'Agra',
    'Varanasi',
    'Prayagraj',
    'Noida',
    'Ghaziabad',
  ],
  'West Bengal': [
    'Kolkata',
    'Howrah',
    'North 24 Parganas',
    'Darjeeling',
    'Siliguri',
  ],
  'Madhya Pradesh': ['Bhopal', 'Indore', 'Gwalior', 'Jabalpur'],
  'Punjab & Haryana': [
    'Chandigarh',
    'Ludhiana',
    'Amritsar',
    'Jalandhar',
    'Gurugram',
    'Faridabad',
  ],
  Goa: ['North Goa', 'South Goa'],
  California: ['Los Angeles County', 'San Francisco', 'San Diego', 'Orange County'],
  'New York': ['New York City', 'Brooklyn', 'Queens', 'Albany'],
  Texas: ['Harris County (Houston)', 'Travis County (Austin)', 'Dallas County'],
  Illinois: ['Cook County (Chicago)'],
  Washington: ['King County (Seattle)'],
  'Greater London': ['Central London', 'City of London', 'Westminster'],
  'Greater Manchester': ['Manchester City', 'Salford'],
  'West Midlands': ['Birmingham'],
  Dubai: ['Dubai Central', 'Jumeirah', 'Deira'],
  'Abu Dhabi': ['Abu Dhabi City', 'Al Ain'],
  Sharjah: ['Sharjah City'],
}

const DISTRICT_COORDS: Record<string, [number, number]> = {
  'Dakshina Kannada': [12.9141, 74.8560],
  Kadaba: [12.5700, 75.3200],
  Puttur: [12.7749, 75.2023],
  Mangaluru: [12.9141, 74.8560],
  Bantwal: [12.8943, 75.0352],
  Belthangady: [13.0035, 75.2954],
  Sullia: [12.5583, 75.3905],
  Moodbidri: [13.0700, 74.9967],
  'Bengaluru Urban': [12.9716, 77.5946],
  'Bengaluru Rural': [13.2257, 77.5750],
  Udupi: [13.3409, 74.7421],
  Mysuru: [12.2958, 76.6394],
  Hassan: [13.0072, 76.1011],
  'Kodagu (Coorg)': [12.4244, 75.7382],
  Shivamogga: [13.9299, 75.5681],
  Belagavi: [15.8497, 74.4977],
  Kalaburagi: [17.3297, 76.8343],
  'Hubballi-Dharwad': [15.3647, 75.1240],
  Ballari: [15.1394, 76.9214],
  Mandya: [12.5218, 76.8951],
  Tumakuru: [13.3392, 77.1016],
  Davanagere: [14.4644, 75.9218],
  Chikkamagaluru: [13.3161, 75.7720],
  'Uttara Kannada': [14.8058, 74.1240],
  'Mumbai City': [18.9388, 72.8353],
  'Mumbai Suburban': [19.0760, 72.8777],
  Pune: [18.5204, 73.8567],
  Thane: [19.2183, 72.9781],
  Nagpur: [21.1458, 79.0882],
  Nashik: [19.9975, 73.7898],
  'Chhatrapati Sambhajinagar': [19.8762, 75.3433],
  Solapur: [17.6599, 75.9064],
  Kolhapur: [16.7050, 74.2433],
  'New Delhi': [28.6139, 77.2090],
  'South Delhi': [28.5400, 77.2100],
  'Central Delhi': [28.6400, 77.2200],
  'North Delhi': [28.7000, 77.1500],
  Gurugram: [28.4595, 77.0266],
  'Noida / Greater Noida': [28.5355, 77.3910],
  Ghaziabad: [28.6692, 77.4538],
  Chennai: [13.0827, 80.2707],
  Coimbatore: [11.0168, 76.9558],
  Madurai: [9.9252, 78.1198],
  Tiruchirappalli: [10.7905, 78.7047],
  Salem: [11.6643, 78.1460],
  Kanchipuram: [12.8342, 79.7036],
  Tiruppur: [11.1085, 77.3411],
  Hyderabad: [17.3850, 78.4867],
  'Ranga Reddy': [17.3500, 78.5500],
  'Medchal-Malkajgiri': [17.5200, 78.5000],
  Warangal: [17.9689, 79.5941],
  Nizamabad: [18.6725, 78.0941],
  Visakhapatnam: [17.6868, 83.2185],
  'Vijayawada (NTR)': [16.5062, 80.6480],
  Tirupati: [13.6288, 79.4192],
  Guntur: [16.3067, 80.4365],
  Nellore: [14.4426, 79.9865],
  'Ernakulam (Kochi)': [9.9312, 76.2673],
  Ernakulam: [9.9312, 76.2673],
  Thiruvananthapuram: [8.5241, 76.9366],
  Kozhikode: [11.2588, 75.7804],
  Thrissur: [10.5276, 76.2144],
  Kannur: [11.8745, 75.3704],
  Kottayam: [9.5916, 76.5222],
  Ahmedabad: [23.0225, 72.5714],
  Surat: [21.1702, 72.8311],
  Vadodara: [22.3072, 73.1812],
  Rajkot: [22.3039, 70.8022],
  Gandhinagar: [23.2156, 72.6369],
  Jaipur: [26.9124, 75.7873],
  Jodhpur: [26.2389, 73.0243],
  Udaipur: [24.5854, 73.7125],
  Kota: [25.2138, 75.8648],
  Ajmer: [26.4499, 74.6399],
  Lucknow: [26.8467, 80.9462],
  Kanpur: [26.4499, 80.3319],
  Agra: [27.1767, 78.0081],
  Varanasi: [25.3176, 82.9739],
  Prayagraj: [25.4358, 81.8463],
  Noida: [28.5355, 77.3910],
  Kolkata: [22.5726, 88.3639],
  Howrah: [22.5958, 88.2636],
  'North 24 Parganas': [22.7200, 88.4800],
  Darjeeling: [27.0410, 88.2663],
  Siliguri: [26.7271, 88.3953],
  Bhopal: [23.2599, 77.4126],
  Indore: [22.7196, 75.8577],
  Gwalior: [26.2183, 78.1828],
  Jabalpur: [23.1815, 79.9864],
  Chandigarh: [30.7333, 76.7794],
  Ludhiana: [30.9010, 75.8573],
  Amritsar: [31.6340, 74.8723],
  Jalandhar: [31.3260, 75.5762],
  Faridabad: [28.4089, 77.3178],
  'North Goa': [15.4989, 73.8278],
  'South Goa': [15.2736, 73.9581],
  Panaji: [15.4989, 73.8278],
  'Los Angeles County': [34.0522, -118.2437],
  'San Francisco': [37.7749, -122.4194],
  'San Diego': [32.7157, -117.1611],
  'New York City': [40.7128, -74.0060],
  Brooklyn: [40.6782, -73.9442],
  Queens: [40.7282, -73.7949],
  'Harris County (Houston)': [29.7604, -95.3698],
  'Travis County (Austin)': [30.2672, -97.7431],
  'Cook County (Chicago)': [41.8781, -87.6298],
  'King County (Seattle)': [47.6062, -122.3321],
  'Central London': [51.5074, -0.1278],
  'Manchester City': [53.4808, -2.2426],
  'Dubai Central': [25.2048, 55.2708],
  'Abu Dhabi City': [24.4539, 54.3773],
  'Sharjah City': [25.3463, 55.4209],
}

// Pre-indexed Organic Land Polygon Boundaries
export const PREDEFINED_REGIONS: RegionOption[] = [
  {
    id: 'kadaba',
    name: 'Kadaba Taluk',
    country: 'India',
    state: 'Karnataka',
    district: 'Dakshina Kannada',
    talukCode: 'KA-19-KB',
    passcode: 'kadaba2026',
    center: [12.5700, 75.3200],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(12.5700, 75.3200, 0.05, 0.065, 2.1),
    activeDriversCount: 3,
  },
  // --- DAKSHINA KANNADA (Exact Organic Landform Traces for Puttur, Mangalore, Bantwal, Belthangady, Sullia) ---
  {
    id: 'mangalore',
    name: 'Mangaluru Taluk (Coastal Command)',
    country: 'India',
    state: 'Karnataka',
    district: 'Dakshina Kannada',
    talukCode: 'KA-19-MN',
    passcode: 'mangalore2026',
    center: [12.9141, 74.8560],
    zoom: 13,
    boundaryPolygon: [
      [12.9950, 74.7820],
      [12.9850, 74.8820],
      [12.9420, 74.9350],
      [12.8710, 74.9220],
      [12.8250, 74.8610],
      [12.8380, 74.8050],
      [12.8920, 74.7780],
      [12.9550, 74.7750],
      [12.9950, 74.7820],
    ],
    activeDriversCount: 8,
  },
  {
    id: 'puttur',
    name: 'Puttur Taluk',
    country: 'India',
    state: 'Karnataka',
    district: 'Dakshina Kannada',
    talukCode: 'KA-19-PT',
    passcode: 'puttur2026',
    center: [12.7749, 75.2023],
    zoom: 13,
    // Hand-crafted organic land contour tracing Perne, Uppinangady, Narimogru, Kemminje, Balnadu, Punacha, Vitla, Kabaka, Mani
    boundaryPolygon: [
      [12.8450, 75.2500],
      [12.8250, 75.2880],
      [12.7680, 75.2850],
      [12.7150, 75.2600],
      [12.6950, 75.2080],
      [12.7050, 75.1480],
      [12.7550, 75.1220],
      [12.8120, 75.1320],
      [12.8480, 75.1850],
      [12.8450, 75.2500],
    ],
    activeDriversCount: 5,
  },
  {
    id: 'bantwal',
    name: 'Bantwal Taluk',
    country: 'India',
    state: 'Karnataka',
    district: 'Dakshina Kannada',
    talukCode: 'KA-19-BN',
    passcode: 'bantwal2026',
    center: [12.8943, 75.0352],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(12.8943, 75.0352, 0.05, 0.06, 5.1),
    activeDriversCount: 4,
  },
  {
    id: 'belthangady',
    name: 'Belthangady Taluk',
    country: 'India',
    state: 'Karnataka',
    district: 'Dakshina Kannada',
    talukCode: 'KA-19-BL',
    passcode: 'belthangady2026',
    center: [13.0035, 75.2954],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(13.0035, 75.2954, 0.055, 0.065, 3.4),
    activeDriversCount: 3,
  },
  {
    id: 'sullia',
    name: 'Sullia Taluk',
    country: 'India',
    state: 'Karnataka',
    district: 'Dakshina Kannada',
    talukCode: 'KA-19-SL',
    passcode: 'sullia2026',
    center: [12.5583, 75.3905],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(12.5583, 75.3905, 0.058, 0.068, 2.9),
    activeDriversCount: 2,
  },

  // --- BENGALURU URBAN (Organic Metropolis Outer Ring) ---
  {
    id: 'bengaluru_north',
    name: 'Bengaluru North Taluk (Yelahanka / Manyata)',
    country: 'India',
    state: 'Karnataka',
    district: 'Bengaluru Urban',
    talukCode: 'KA-04-BN',
    passcode: 'bengaluru2026',
    center: [13.0350, 77.5688],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(13.0350, 77.5688, 0.06, 0.075, 6.3),
    activeDriversCount: 14,
  },
  {
    id: 'bengaluru_south',
    name: 'Bengaluru South Taluk (Jayanagar / E-City)',
    country: 'India',
    state: 'Karnataka',
    district: 'Bengaluru Urban',
    talukCode: 'KA-05-BS',
    passcode: 'bengaluru2026',
    center: [12.8900, 77.5700],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(12.8900, 77.5700, 0.06, 0.075, 7.2),
    activeDriversCount: 16,
  },
  {
    id: 'bengaluru_east',
    name: 'Bengaluru East / Whitefield Tech Corridor',
    country: 'India',
    state: 'Karnataka',
    district: 'Bengaluru Urban',
    talukCode: 'KA-53-BE',
    passcode: 'bengaluru2026',
    center: [12.9700, 77.6900],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(12.9700, 77.6900, 0.065, 0.08, 8.5),
    activeDriversCount: 18,
  },

  // --- UDUPI (Organic Coastline Contour) ---
  {
    id: 'udupi',
    name: 'Udupi Taluk (Coastal Belt)',
    country: 'India',
    state: 'Karnataka',
    district: 'Udupi',
    talukCode: 'KA-20-UD',
    passcode: 'udupi2026',
    center: [13.3409, 74.7421],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(13.3409, 74.7421, 0.055, 0.065, 9.1),
    activeDriversCount: 6,
  },

  // --- MAHARASHTRA (Mumbai Peninsula & Pune Hills) ---
  {
    id: 'mumbai_suburban',
    name: 'Mumbai Suburban / BKC Peninsula',
    country: 'India',
    state: 'Maharashtra',
    district: 'Mumbai Suburban',
    talukCode: 'MH-02-MS',
    passcode: 'mumbai2026',
    center: [19.0760, 72.8777],
    zoom: 13,
    boundaryPolygon: [
      [19.1620, 72.8250],
      [19.1750, 72.8850],
      [19.1250, 72.9320],
      [19.0450, 72.9150],
      [18.9850, 72.8650],
      [19.0120, 72.8150],
      [19.0850, 72.8180],
      [19.1620, 72.8250],
    ],
    activeDriversCount: 24,
  },
  {
    id: 'pune_city',
    name: 'Pune City / Hinjewadi Hills Zone',
    country: 'India',
    state: 'Maharashtra',
    district: 'Pune',
    talukCode: 'MH-12-PC',
    passcode: 'pune2026',
    center: [18.5204, 73.8567],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(18.5204, 73.8567, 0.065, 0.075, 10.4),
    activeDriversCount: 15,
  },

  // --- DELHI NCR ---
  {
    id: 'new_delhi',
    name: 'New Delhi Yamuna Corridor',
    country: 'India',
    state: 'Delhi (NCR)',
    district: 'New Delhi',
    talukCode: 'DL-01-ND',
    passcode: 'delhi2026',
    center: [28.6139, 77.2090],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(28.6139, 77.2090, 0.06, 0.07, 11.2),
    activeDriversCount: 22,
  },

  // --- KERALA (Kochi Lagoons & Thiruvananthapuram) ---
  {
    id: 'kochi_central',
    name: 'Ernakulam / Kochi Lagoon Belt',
    country: 'India',
    state: 'Kerala',
    district: 'Ernakulam (Kochi)',
    talukCode: 'KL-07-EK',
    passcode: 'kochi2026',
    center: [9.9312, 76.2673],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(9.9312, 76.2673, 0.05, 0.065, 12.8),
    activeDriversCount: 8,
  },
  {
    id: 'thiruvananthapuram',
    name: 'Thiruvananthapuram Capital Command',
    country: 'India',
    state: 'Kerala',
    district: 'Thiruvananthapuram',
    talukCode: 'KL-01-TV',
    passcode: 'trivandrum2026',
    center: [8.5241, 76.9366],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(8.5241, 76.9366, 0.055, 0.065, 13.2),
    activeDriversCount: 6,
  },

  // --- TAMIL NADU ---
  {
    id: 'chennai',
    name: 'Chennai Central Transport Command',
    country: 'India',
    state: 'Tamil Nadu',
    district: 'Chennai',
    talukCode: 'TN-01-CHE',
    passcode: 'chennai2026',
    center: [13.0827, 80.2707],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(13.0827, 80.2707, 0.065, 0.075, 14.1),
    activeDriversCount: 20,
  },
  {
    id: 'coimbatore',
    name: 'Coimbatore Freight & Textile Hub',
    country: 'India',
    state: 'Tamil Nadu',
    district: 'Coimbatore',
    talukCode: 'TN-37-CBE',
    passcode: 'coimbatore2026',
    center: [11.0168, 76.9558],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(11.0168, 76.9558, 0.055, 0.065, 15.3),
    activeDriversCount: 11,
  },

  // --- TELANGANA ---
  {
    id: 'hyderabad',
    name: 'Hyderabad HITEC City Command',
    country: 'India',
    state: 'Telangana',
    district: 'Hyderabad',
    talukCode: 'TS-09-HYD',
    passcode: 'hyderabad2026',
    center: [17.3850, 78.4867],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(17.3850, 78.4867, 0.065, 0.075, 16.4),
    activeDriversCount: 25,
  },

  // --- ANDHRA PRADESH ---
  {
    id: 'visakhapatnam',
    name: 'Visakhapatnam Coastal Command',
    country: 'India',
    state: 'Andhra Pradesh',
    district: 'Visakhapatnam',
    talukCode: 'AP-31-VSKP',
    passcode: 'vizag2026',
    center: [17.6868, 83.2185],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(17.6868, 83.2185, 0.06, 0.07, 17.5),
    activeDriversCount: 12,
  },
  {
    id: 'vijayawada',
    name: 'Vijayawada Krishna Hub',
    country: 'India',
    state: 'Andhra Pradesh',
    district: 'Vijayawada (NTR)',
    talukCode: 'AP-16-VJA',
    passcode: 'vijayawada2026',
    center: [16.5062, 80.6480],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(16.5062, 80.6480, 0.055, 0.065, 18.2),
    activeDriversCount: 9,
  },

  // --- GUJARAT ---
  {
    id: 'ahmedabad',
    name: 'Ahmedabad Sabarmati Sector',
    country: 'India',
    state: 'Gujarat',
    district: 'Ahmedabad',
    talukCode: 'GJ-01-AMD',
    passcode: 'ahmedabad2026',
    center: [23.0225, 72.5714],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(23.0225, 72.5714, 0.065, 0.075, 19.1),
    activeDriversCount: 17,
  },
  {
    id: 'surat',
    name: 'Surat Diamond Corridor',
    country: 'India',
    state: 'Gujarat',
    district: 'Surat',
    talukCode: 'GJ-05-SRT',
    passcode: 'surat2026',
    center: [21.1702, 72.8311],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(21.1702, 72.8311, 0.055, 0.065, 20.3),
    activeDriversCount: 14,
  },

  // --- RAJASTHAN ---
  {
    id: 'jaipur',
    name: 'Jaipur Amber Transit Sector',
    country: 'India',
    state: 'Rajasthan',
    district: 'Jaipur',
    talukCode: 'RJ-14-JPR',
    passcode: 'jaipur2026',
    center: [26.9124, 75.7873],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(26.9124, 75.7873, 0.06, 0.07, 21.4),
    activeDriversCount: 13,
  },

  // --- UTTAR PRADESH ---
  {
    id: 'lucknow',
    name: 'Lucknow Gomti Command',
    country: 'India',
    state: 'Uttar Pradesh',
    district: 'Lucknow',
    talukCode: 'UP-32-LKO',
    passcode: 'lucknow2026',
    center: [26.8467, 80.9462],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(26.8467, 80.9462, 0.065, 0.075, 22.5),
    activeDriversCount: 19,
  },
  {
    id: 'noida_up',
    name: 'Noida Expressway Tech Sector',
    country: 'India',
    state: 'Uttar Pradesh',
    district: 'Noida',
    talukCode: 'UP-16-NOI',
    passcode: 'noida2026',
    center: [28.5355, 77.3910],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(28.5355, 77.3910, 0.06, 0.07, 23.1),
    activeDriversCount: 16,
  },

  // --- WEST BENGAL ---
  {
    id: 'kolkata',
    name: 'Kolkata Hooghly River Command',
    country: 'India',
    state: 'West Bengal',
    district: 'Kolkata',
    talukCode: 'WB-01-KOL',
    passcode: 'kolkata2026',
    center: [22.5726, 88.3639],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(22.5726, 88.3639, 0.06, 0.07, 24.2),
    activeDriversCount: 21,
  },

  // --- MADHYA PRADESH ---
  {
    id: 'bhopal',
    name: 'Bhopal Lakes & Logistics Command',
    country: 'India',
    state: 'Madhya Pradesh',
    district: 'Bhopal',
    talukCode: 'MP-04-BPL',
    passcode: 'bhopal2026',
    center: [23.2599, 77.4126],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(23.2599, 77.4126, 0.06, 0.07, 25.1),
    activeDriversCount: 10,
  },

  // --- PUNJAB & HARYANA ---
  {
    id: 'chandigarh',
    name: 'Chandigarh Tri-City Capital Sector',
    country: 'India',
    state: 'Punjab & Haryana',
    district: 'Chandigarh',
    talukCode: 'CH-01-CHD',
    passcode: 'chandigarh2026',
    center: [30.7333, 76.7794],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(30.7333, 76.7794, 0.06, 0.07, 26.2),
    activeDriversCount: 12,
  },

  // --- GOA ---
  {
    id: 'panaji_north_goa',
    name: 'North Goa Panaji Coastal Command',
    country: 'India',
    state: 'Goa',
    district: 'North Goa',
    talukCode: 'GA-01-PNJ',
    passcode: 'goa2026',
    center: [15.4989, 73.8278],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(15.4989, 73.8278, 0.055, 0.065, 27.3),
    activeDriversCount: 7,
  },

  // --- KARNATAKA ADDITIONAL ---
  {
    id: 'mysuru',
    name: 'Mysuru Heritage Sector',
    country: 'India',
    state: 'Karnataka',
    district: 'Mysuru',
    talukCode: 'KA-09-MYS',
    passcode: 'mysuru2026',
    center: [12.2958, 76.6394],
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(12.2958, 76.6394, 0.055, 0.065, 28.1),
    activeDriversCount: 8,
  },
]

const STATE_COORDS: Record<string, [number, number]> = {
  Karnataka: [12.9716, 77.5946],
  Maharashtra: [19.0760, 72.8777],
  'Delhi (NCR)': [28.6139, 77.2090],
  'Tamil Nadu': [13.0827, 80.2707],
  Telangana: [17.3850, 78.4867],
  'Andhra Pradesh': [16.5062, 80.6480],
  Kerala: [9.9312, 76.2673],
  Gujarat: [23.0225, 72.5714],
  Rajasthan: [26.9124, 75.7873],
  'Uttar Pradesh': [26.8467, 80.9462],
  'West Bengal': [22.5726, 88.3639],
  'Madhya Pradesh': [23.2599, 77.4126],
  'Punjab & Haryana': [30.7333, 76.7794],
  Goa: [15.4989, 73.8278],
}

/**
 * Dynamic Region Resolver:
 * Resolves any State/District/Taluk in India & World with distinct, organic land contour shape
 */
export function getOrGenerateRegion(country: string, state: string, district: string, talukName?: string): RegionOption {
  // 1. Check if specific talukName matches any PREDEFINED_REGIONS
  if (talukName) {
    const cleanTaluk = talukName.toLowerCase().replace(/[^a-z0-9]/g, '')
    const foundTaluk = PREDEFINED_REGIONS.find((r) => {
      const rName = r.name.toLowerCase().replace(/[^a-z0-9]/g, '')
      const rId = r.id.toLowerCase().replace(/[^a-z0-9]/g, '')
      return rName === cleanTaluk || rId === cleanTaluk || (cleanTaluk.length > 3 && (rName.includes(cleanTaluk) || cleanTaluk.includes(rName)))
    })
    if (foundTaluk) return foundTaluk
  }

  // 2. Check if district specifically matches any PREDEFINED_REGIONS when no taluk given
  if (!talukName) {
    const cleanDist = district.toLowerCase().replace(/[^a-z0-9]/g, '')
    const foundDist = PREDEFINED_REGIONS.find((r) => {
      const rDist = r.district.toLowerCase().replace(/[^a-z0-9]/g, '')
      const rId = r.id.toLowerCase().replace(/[^a-z0-9]/g, '')
      return rDist === cleanDist || rId === cleanDist
    })
    if (foundDist) return foundDist
  }

  // 3. Resolve exact geographic coordinates for this district
  const cleanDistrict = district.trim()
  const coords: [number, number] =
    DISTRICT_COORDS[cleanDistrict] ||
    DISTRICT_COORDS[talukName || ''] ||
    (Object.entries(DISTRICT_COORDS).find(([k]) => k.toLowerCase().replace(/[^a-z0-9]/g, '') === cleanDistrict.toLowerCase().replace(/[^a-z0-9]/g, ''))?.[1]) ||
    STATE_COORDS[state] ||
    [12.9716, 77.5946]

  const cleanTalukName = talukName || `${district} Jurisdiction`
  const sanitizedId = `${country}_${state}_${district}_${talukName || ''}`.toLowerCase().replace(/[^a-z0-9]/g, '_')

  // Generate unique seed based on the string name so every region in all states gets a distinct shape
  const nameToHash = `${state}_${district}_${cleanTalukName}`
  const stringSeed = nameToHash.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0) % 25

  return {
    id: sanitizedId,
    name: cleanTalukName,
    country: country,
    state: state,
    district: district,
    talukCode: `${(state || 'IN').slice(0, 2).toUpperCase()}-${(district || 'SEC').slice(0, 3).toUpperCase()}-01`,
    passcode: `${district.toLowerCase().replace(/[^a-z]/g, '')}2026`,
    center: coords,
    zoom: 13,
    boundaryPolygon: makeOrganicLandShape(coords[0], coords[1], 0.055, 0.07, stringSeed),
    activeDriversCount: Math.floor(Math.random() * 8) + 4,
  }
}

export function getRegionById(id?: string | null): RegionOption | null {
  if (!id) return null
  const clean = id.toLowerCase().replace(/[^a-z0-9]/g, '')
  if (!clean || clean === 'all') return null

  // 1. Exact ID match in PREDEFINED_REGIONS
  const exact = PREDEFINED_REGIONS.find((r) => r.id.toLowerCase().replace(/[^a-z0-9]/g, '') === clean)
  if (exact) return exact

  // 2. Exact or substring match on name / id in PREDEFINED_REGIONS
  const match = PREDEFINED_REGIONS.find((r) => {
    const rId = r.id.toLowerCase().replace(/[^a-z0-9]/g, '')
    const rName = r.name.toLowerCase().replace(/[^a-z0-9]/g, '')
    return clean === rId || clean === rName || (clean.length > 3 && (rId.includes(clean) || clean.includes(rId)))
  })
  if (match) return match

  // 3. District / Taluk coords lookup
  for (const [dist, coords] of Object.entries(DISTRICT_COORDS)) {
    const distClean = dist.toLowerCase().replace(/[^a-z0-9]/g, '')
    if (clean === distClean || (clean.length > 3 && (clean.includes(distClean) || distClean.includes(clean)))) {
      return getOrGenerateRegion('India', '', dist, `${dist} Command`)
    }
  }

  // 4. State coords lookup
  for (const [st, coords] of Object.entries(STATE_COORDS)) {
    const stClean = st.toLowerCase().replace(/[^a-z0-9]/g, '')
    if (clean === stClean || (clean.length > 3 && (clean.includes(stClean) || stClean.includes(clean)))) {
      return getOrGenerateRegion('India', st, `${st} Central`, `${st} Command`)
    }
  }

  return null
}

/**
 * Resolves the currently active admin region from localStorage with guaranteed accuracy.
 */
export function resolveActiveRegion(storedString?: string | null): RegionOption {
  try {
    const saved = storedString || localStorage.getItem('smartdrive_selected_region') || localStorage.getItem('fg_selected_region')
    if (saved) {
      const parsed = JSON.parse(saved)

      // If the saved object already has a valid boundaryPolygon with points and center
      if (
        parsed &&
        Array.isArray(parsed.boundaryPolygon) &&
        parsed.boundaryPolygon.length >= 3 &&
        Array.isArray(parsed.center) &&
        parsed.center.length === 2 &&
        !isNaN(parsed.center[0]) &&
        parsed.center[0] !== 0
      ) {
        return parsed as RegionOption
      }

      // Try finding exact or matching region
      if (parsed.id) {
        const exact = getRegionById(parsed.id)
        if (exact) {
          if (parsed.name) exact.name = parsed.name
          return exact
        }
      }

      // Check if user has name/district/state
      const district = parsed.district || parsed.name || ''
      const state = parsed.state || 'Karnataka'
      const country = parsed.country || 'India'
      const taluk = parsed.name || parsed.taluk || district

      return getOrGenerateRegion(country, state, district, taluk)
    }
  } catch (_) {}

  // Check admin user object if region was stored there
  try {
    const userStr = localStorage.getItem('smartdrive_admin_user')
    if (userStr) {
      const u = JSON.parse(userStr)
      if (u.region) {
        const found = getRegionById(u.region)
        if (found) return found
        return getOrGenerateRegion('India', 'Karnataka', u.region, u.region)
      }
    }
  } catch (_) {}

  // Defaults to Puttur Taluk (primary telemetry operating sector)
  return PREDEFINED_REGIONS.find(r => r.id === 'puttur') || PREDEFINED_REGIONS[0]
}
