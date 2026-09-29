import { Driver, Vehicle, FleetEvent } from '@/types';

const API_BASE_URL = window.location.hostname === 'localhost'
  ? 'http://localhost:3000/api'
  : `http://${window.location.hostname}:3000/api`;

async function getValidJwtToken(forceRefresh = false): Promise<string | null> {
  let token = localStorage.getItem('smartdrive_jwt_token') || 
              localStorage.getItem('smartdrive_real_backend_token') || 
              localStorage.getItem('fg_real_backend_token');

  // Check if token is a mock string or missing
  const isMockToken = !token || token.startsWith('auth_') || token.split('.').length !== 3;

  if (isMockToken || forceRefresh) {
    try {
      const loginRes = await fetch(`${API_BASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: 'admin@smartdrive.ai', password: 'SmartDrive2026!' }),
      });
      if (loginRes.ok) {
        const loginJson = await loginRes.json();
        token = loginJson.data?.accessToken || loginJson.accessToken || null;
        if (token) {
          localStorage.setItem('smartdrive_jwt_token', token);
          localStorage.setItem('smartdrive_real_backend_token', token);
          localStorage.setItem('fg_real_backend_token', token);
        }
      }
    } catch (err) {
      console.warn('[API] Token refresh failed:', err);
    }
  }
  return token;
}

async function fetchWithAuth(url: string, options: RequestInit = {}): Promise<Response> {
  let token = await getValidJwtToken(false);
  const headers = new Headers(options.headers || {});
  headers.set('Content-Type', 'application/json');
  if (token) {
    headers.set('Authorization', `Bearer ${token}`);
  }

  let res = await fetch(url, { ...options, headers });

  // If unauthorized (expired or invalid token), refresh token and retry once
  if (res.status === 401) {
    token = await getValidJwtToken(true);
    if (token) {
      headers.set('Authorization', `Bearer ${token}`);
      res = await fetch(url, { ...options, headers });
    }
  }

  return res;
}

export async function fetchDriversFromApi(): Promise<Driver[]> {
  try {
    const res = await fetchWithAuth(`${API_BASE_URL}/drivers`);
    if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
    const json = await res.json();
    const list = json.data || [];
    return list.map((item: any) => transformDriverFromDb(item));
  } catch (err) {
    console.error('Failed to fetch drivers:', err);
    return [];
  }
}
export async function fetchPendingDrivers(zone?: string): Promise<any[]> {
  try {
    const url = zone && zone.toLowerCase() !== 'all' 
      ? `${API_BASE_URL}/drivers/pending?zone=${encodeURIComponent(zone)}` 
      : `${API_BASE_URL}/drivers/pending?zone=all`;
    const res = await fetchWithAuth(url);
    if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
    const json = await res.json();
    return json.data || [];
  } catch (err) {
    console.error('Failed to fetch pending drivers:', err);
    return [];
  }
}

export async function verifyDriverLicense(licenseNumber: string): Promise<any> {
  try {
    const res = await fetchWithAuth(`${API_BASE_URL}/drivers/verify-license`, {
      method: 'POST',
      body: JSON.stringify({ licenseNumber }),
    });
    if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
    const json = await res.json();
    return json.data;
  } catch (err) {
    console.error('Failed to verify license:', err);
    throw err;
  }
}

export async function approveDriverApplication(id: string): Promise<any> {
  try {
    const res = await fetchWithAuth(`${API_BASE_URL}/drivers/${id}/approve`, {
      method: 'POST',
    });
    if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
    const json = await res.json();
    return json.data;
  } catch (err) {
    console.error('Failed to approve driver:', err);
    throw err;
  }
}

export async function rejectDriverApplication(id: string, reason?: string): Promise<any> {
  try {
    const res = await fetchWithAuth(`${API_BASE_URL}/drivers/${id}/reject`, {
      method: 'POST',
      body: JSON.stringify({ reason }),
    });
    if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
    const json = await res.json();
    return json.data;
  } catch (err) {
    console.error('Failed to reject driver:', err);
    throw err;
  }
}

export async function fetchVehiclesFromApi(): Promise<Vehicle[]> {
  try {
    const res = await fetchWithAuth(`${API_BASE_URL}/vehicles`);
    if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
    const json = await res.json();
    const list = json.data || [];

    return list.map((v: any) => ({
      id: v.id,
      name: `${v.make} ${v.model}`,
      type: (v.vehicleType?.toLowerCase() || 'pickup') as any,
      registration: v.licensePlate,
      health: 100,
      insuranceValid: 'Valid',
    }));
  } catch (err) {
    return [];
  }
}

export async function fetchEventsFromApi(): Promise<FleetEvent[]> {
  try {
    const res = await fetchWithAuth(`${API_BASE_URL}/events`);
    if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
    const json = await res.json();
    const list = json.data || [];

    return list.map((e: any) => ({
      id: e.id,
      driverId: e.driverId,
      driverName: e.driver?.user ? `${e.driver.user.firstName} ${e.driver.user.lastName}` : (e.driverName || 'Field Agent'),
      vehicleReg: e.vehicleReg || 'KA-19-LIVE',
      type: (e.eventType?.toLowerCase() || 'overspeed') as any,
      severity: (e.severity?.toLowerCase() || 'medium') as any,
      location: { lat: e.latitude || 12.7749, lng: e.longitude || 75.2023 },
      locationName: e.locationName || 'Active Sector',
      time: new Date(e.timestamp || Date.now()).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      value: e.value || e.details || '',
    }));
  } catch (err) {
    return [];
  }
}

export async function fetchCrashReportById(id: string): Promise<any> {
  try {
    const res = await fetchWithAuth(`${API_BASE_URL}/crashes/${id}`);
    if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
    const json = await res.json();
    return json.data;
  } catch (err) {
    console.warn('Crash API fetch failed:', err);
    return null;
  }
}

export async function deleteDriverFromApi(id: string): Promise<boolean> {
  try {
    const res = await fetchWithAuth(`${API_BASE_URL}/drivers/${id}`, {
      method: 'DELETE',
    });
    return res.ok;
  } catch (err) {
    console.error('Failed to delete driver:', err);
    return false;
  }
}

export async function fetchDriverProfile(id: string): Promise<any> {
  try {
    const res = await fetchWithAuth(`${API_BASE_URL}/drivers/${id}`);
    if (!res.ok) return null;
    const json = await res.json();
    return json.data;
  } catch (err) {
    console.warn('Driver profile fetch failed:', err);
    return null;
  }
}

export function transformDriverFromDb(d: any): Driver {
  const rawFirstName = d.user?.firstName || '';
  const rawLastName = d.user?.lastName || '';
  const cleanLastName = rawLastName.toLowerCase() === 'applicant' ? '' : rawLastName;
  const fullName = d.user ? `${rawFirstName} ${cleanLastName}`.trim() : (d.name || 'Field Agent');
  const name = fullName.replace(/\s+applicant$/i, '').trim() || rawFirstName || 'Field Agent';
  const appliedVehicle = (d.badges || []).find((b: string) => b.startsWith('applied_vehicle:'))?.replace('applied_vehicle:', '') || d.driverType || 'Scooter';
  const emergencyRelation = (d.badges || []).find((b: string) => b.startsWith('emergency_relation:'))?.replace('emergency_relation:', '') || 'Parent / Guardian';
  const driverCodeBadge = (d.badges || []).find((b: string) => b.startsWith('driver_code:'))?.replace('driver_code:', '');

  return {
    id: d.id,
    userId: d.userId,
    name,
    email: d.user?.email || d.email || '',
    phone: d.user?.phoneNumber || d.phoneNumber || '',
    licenseNumber: d.licenseNumber || '',
    emergencyContactName: d.emergencyContactName || '',
    emergencyContactPhone: d.emergencyContactPhone || '',
    emergencyRelationship: emergencyRelation,
    appliedVehicle,
    zone: d.user?.zone || d.zone || 'Regional Sector',
    employeeId: driverCodeBadge || d.licenseNumber || `AGENT-${d.id.slice(0,4)}`,
    photo: '',
    status: (d.isOnline && d.latitude && d.longitude && Math.abs(d.latitude - 12.7749) > 0.001) ? 'safe' : 'offline',
    vehicleId: 'v-live',
    vehicleName: appliedVehicle,
    industry: 'Logistics',
    fleet: 'Smart Fleet Tactical',
    safetyScore: d.safetyScore ?? 100,
    riskScore: 0,
    crashProbability: 0,
    speed: d.speed ?? 0,
    location: {
      lat: d.latitude || 0,
      lng: d.longitude || 0
    },
    locationName: d.user?.zone || d.zone || 'Active Sector',
    route: [],
    distanceToday: 0,
    tripDurationMin: 0,
    drivingHours: 0,
    trips: 0,
    battery: 100,
    internet: 100,
    gps: true,
    camera: false,
    sensors: true,
    ble: true,
    overspeedCount: 0,
    harshBrakingCount: 0,
    sharpTurnCount: 0,
    weeklyTrend: 0,
    monthlyTrend: 0,
    drivingStyle: 'Tactical',
    aggressive: 0,
    recommendation: 'Link stable.',
    heading: 0,
  };
}
