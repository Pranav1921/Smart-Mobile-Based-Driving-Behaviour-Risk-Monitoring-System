import { Driver } from '@/types';

/**
 * Normalizes a region string to its canonical keyword token.
 */
export function extractRegionToken(val?: string | null): string {
  if (!val) return '';
  const lower = val.toLowerCase().replace(/[^a-z0-9]/g, '');
  if (lower.includes('kadaba')) return 'kadaba';
  if (lower.includes('puttur')) return 'puttur';
  if (lower.includes('mangalore') || lower.includes('mangaluru')) return 'mangalore';
  if (lower.includes('bantwal')) return 'bantwal';
  if (lower.includes('sullia')) return 'sullia';
  if (lower.includes('belthangady')) return 'belthangady';
  if (lower.includes('moodbidri')) return 'moodbidri';
  if (lower.includes('udupi')) return 'udupi';
  if (lower.includes('bengaluru') || lower.includes('bangalore')) return 'bengaluru';
  if (lower.includes('mysuru') || lower.includes('mysore')) return 'mysuru';
  if (lower.includes('mumbai')) return 'mumbai';
  if (lower.includes('pune')) return 'pune';
  if (lower.includes('chennai')) return 'chennai';
  if (lower.includes('hyderabad')) return 'hyderabad';
  if (lower.includes('delhi')) return 'delhi';
  if (lower.includes('kochi') || lower.includes('ernakulam')) return 'kochi';
  return lower;
}

/**
 * Strict Regional Isolation:
 * Ensures drivers from one region (e.g., Kadaba) can NEVER be seen or accessed
 * by admins of another region (e.g., Puttur), and vice-versa.
 */
export function isDriverInRegion(driver: Partial<Driver> | any, adminRegionId?: string | null): boolean {
  if (!adminRegionId || adminRegionId === 'all' || adminRegionId === 'super_admin' || adminRegionId === 'global') {
    return true;
  }

  const adminToken = extractRegionToken(adminRegionId);
  if (!adminToken || adminToken === 'all' || adminToken === 'karnataka') return true;

  // 1. Check all explicit region & zone fields on driver
  const rawFields = [
    driver.regionId,
    driver.region,
    driver.zone,
    driver.user?.zone,
    driver.locationName,
    driver.companyCode,
    driver.fleet,
    driver.user?.region,
    driver.address,
  ].filter(Boolean) as string[];

  const combinedStr = rawFields.join(' ').toLowerCase();

  // District / state level hierarchy
  const dkTaluks = ['puttur', 'kadaba', 'mangalore', 'bantwal', 'sullia', 'belthangady', 'moodbidri'];
  if (adminToken.includes('dakshina') || adminToken === 'dk') {
    return dkTaluks.some(t => combinedStr.includes(t)) || !combinedStr;
  }

  const driverToken = extractRegionToken(combinedStr);

  if (driverToken) {
    // Strict isolation: driver belongs to this region only if tokens match exactly
    return driverToken === adminToken;
  }

  // 2. Fallback to Geographic coordinate bounding boxes if no text region token is set
  const lat = driver.location?.lat ?? driver.latitude;
  const lng = driver.location?.lng ?? driver.longitude;

  if (typeof lat === 'number' && typeof lng === 'number' && lat !== 0 && lng !== 0 && !isNaN(lat) && !isNaN(lng)) {
    if (adminToken === 'puttur') {
      return lat >= 12.72 && lat <= 12.84 && lng >= 75.14 && lng <= 75.26;
    }
    if (adminToken === 'kadaba') {
      return lat >= 12.68 && lat <= 12.80 && lng >= 75.26 && lng <= 75.42;
    }
    if (adminToken === 'mangalore') {
      return lat >= 12.80 && lat <= 13.02 && lng >= 74.78 && lng <= 74.96;
    }
    if (adminToken === 'bantwal') {
      return lat >= 12.84 && lat <= 12.95 && lng >= 74.98 && lng <= 75.10;
    }
    if (adminToken === 'sullia') {
      return lat >= 12.50 && lat <= 12.65 && lng >= 75.32 && lng <= 75.48;
    }
    if (adminToken === 'belthangady') {
      return lat >= 12.94 && lat <= 13.06 && lng >= 75.20 && lng <= 75.34;
    }
    if (adminToken === 'moodbidri') {
      return lat >= 13.02 && lat <= 13.14 && lng >= 74.94 && lng <= 75.06;
    }
    // Dakshina Kannada district-wide cluster (Lat: 12.4 to 13.2, Lng: 74.7 to 75.7)
    if (adminToken.includes('dakshina') || adminToken === 'dk') {
      return lat >= 12.4 && lat <= 13.2 && lng >= 74.7 && lng <= 75.7;
    }
  }

  return false;
}

/**
 * Retrieves the currently selected admin region ID from localStorage.
 */
export function getActiveAdminRegionId(): string | null {
  try {
    const saved = localStorage.getItem('smartdrive_selected_region') || localStorage.getItem('fg_selected_region');
    if (saved) {
      const parsed = JSON.parse(saved);
      return parsed.id || parsed.talukCode || parsed.name || null;
    }
    const adminUser = localStorage.getItem('smartdrive_admin_user');
    if (adminUser) {
      const parsed = JSON.parse(adminUser);
      return parsed.region || null;
    }
  } catch (_) {}
  return null;
}
