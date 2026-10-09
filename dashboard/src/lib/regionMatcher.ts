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
  if (lower.includes('all') || lower.includes('global') || lower.includes('national') || lower.includes('regional')) return 'all';
  return '';
}

/**
 * Ensures drivers from one region are filtered appropriately,
 * while NEVER hiding active dead-zone, emergency, or connected fleet drivers.
 */
export function isDriverInRegion(driver: Partial<Driver> | any, adminRegionId?: string | null): boolean {
  if (!driver) return false;

  // 1. Critical safety rule: Emergency and Cellular Dead Zone drivers are ALWAYS visible to fleet command
  if (driver.status === 'emergency' || driver.isDeadZone === true || driver.alertType === 'SOS' || driver.alertType === 'CRASH') {
    return true;
  }

  if (!adminRegionId || adminRegionId === 'all' || adminRegionId === 'super_admin' || adminRegionId === 'global' || adminRegionId === 'default') {
    return true;
  }

  const adminToken = extractRegionToken(adminRegionId);
  if (!adminToken || adminToken === 'all' || adminToken === 'karnataka') return true;

  // 2. Check region & zone text fields on driver
  const rawFields = [
    driver.regionId,
    driver.region,
    driver.zone,
    driver.user?.zone,
    driver.locationName,
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
    if (driverToken === 'all' || driverToken === adminToken) return true;
  }

  // 3. Fallback to Geographic coordinate bounding boxes
  const lat = driver.location?.lat ?? driver.latitude;
  const lng = driver.location?.lng ?? driver.longitude;

  if (typeof lat === 'number' && typeof lng === 'number' && lat !== 0 && lng !== 0 && !isNaN(lat) && !isNaN(lng)) {
    if (adminToken === 'puttur') {
      return (lat >= 12.65 && lat <= 12.90 && lng >= 75.10 && lng <= 75.35) || (lat >= 12.50 && lat <= 13.15 && lng >= 75.00 && lng <= 75.60);
    }
    if (adminToken === 'kadaba') {
      return (lat >= 12.60 && lat <= 12.88 && lng >= 75.20 && lng <= 75.55);
    }
    if (adminToken === 'mangalore') {
      return (lat >= 12.75 && lat <= 13.05 && lng >= 74.75 && lng <= 75.00);
    }
    if (adminToken === 'bantwal') {
      return (lat >= 12.80 && lat <= 12.98 && lng >= 74.95 && lng <= 75.15);
    }
    if (adminToken === 'sullia') {
      return (lat >= 12.45 && lat <= 12.70 && lng >= 75.25 && lng <= 75.55);
    }
    if (adminToken === 'belthangady') {
      return (lat >= 12.90 && lat <= 13.10 && lng >= 75.15 && lng <= 75.40);
    }
    if (adminToken === 'moodbidri') {
      return (lat >= 12.98 && lat <= 13.18 && lng >= 74.90 && lng <= 75.10);
    }
    // Dakshina Kannada district-wide cluster
    if (adminToken.includes('dakshina') || adminToken === 'dk') {
      return lat >= 12.4 && lat <= 13.3 && lng >= 74.6 && lng <= 75.7;
    }
  }

  // If driver has no coordinates or no explicit mismatch, keep visible if active
  if (driver.status && driver.status !== 'offline') {
    return true;
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
