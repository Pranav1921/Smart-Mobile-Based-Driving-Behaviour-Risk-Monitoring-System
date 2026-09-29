const BASE_URL = 'http://localhost:3000';

const testCandidates = [
  {
    name: 'Aarav Sharma',
    email: `aarav.scooter.${Date.now()}@testdrive.in`,
    phoneNumber: '+91 98451 23001',
    vehicleType: 'scooter',
    licenseNumber: 'KA21 20210001024',
    zone: 'Karnataka, Dakshina Kannada, Puttur',
    familyRelationship: 'Mother',
    emergencyContactName: 'Sunita Sharma',
    emergencyContactPhone: '+91 98451 99001',
  },
  {
    name: 'Vikramaditya Rao',
    email: `vikram.bike.${Date.now()}@testdrive.in`,
    phoneNumber: '+91 98452 34002',
    vehicleType: 'bike',
    licenseNumber: 'KA19 20200004412',
    zone: 'Karnataka, Dakshina Kannada, Mangaluru',
    familyRelationship: 'Father',
    emergencyContactName: 'Gopal Rao',
    emergencyContactPhone: '+91 98452 99002',
  },
  {
    name: 'Manjunath Gowda',
    email: `manju.auto.${Date.now()}@testdrive.in`,
    phoneNumber: '+91 98453 45003',
    vehicleType: '3_wheeler',
    licenseNumber: 'KA20 20190008890',
    zone: 'Karnataka, Udupi, Manipal',
    familyRelationship: 'Brother',
    emergencyContactName: 'Ramesh Gowda',
    emergencyContactPhone: '+91 98453 99003',
  },
  {
    name: 'Suresh Babu Kumar',
    email: `suresh.cab.${Date.now()}@testdrive.in`,
    phoneNumber: '+91 98454 56004',
    vehicleType: 'cab',
    licenseNumber: 'KA01 20180003321',
    zone: 'Karnataka, Bengaluru Urban, Indiranagar',
    familyRelationship: 'Spouse',
    emergencyContactName: 'Lakshmi Kumar',
    emergencyContactPhone: '+91 98454 99004',
  },
  {
    name: 'Praveen Shetty',
    email: `praveen.van.${Date.now()}@testdrive.in`,
    phoneNumber: '+91 98455 67005',
    vehicleType: 'delivery_van',
    licenseNumber: 'KA21 20220005509',
    zone: 'Karnataka, Dakshina Kannada, Puttur',
    familyRelationship: 'Uncle',
    emergencyContactName: 'Mohan Shetty',
    emergencyContactPhone: '+91 98455 99005',
  }
];

async function runVehicleOnboardingTest() {
  console.log('================================================================');
  console.log('  SMARTDRIVE END-TO-END VEHICLE ONBOARDING & VERIFICATION SUITE  ');
  console.log('================================================================\n');

  console.log('▶ STEP 1: Registering 5 Realistic Candidates (2W, 3W, 4W)...');
  const registered = [];

  for (const cand of testCandidates) {
    try {
      const res = await fetch(`${BASE_URL}/api/auth/driver-apply`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(cand)
      });
      const data: any = await res.json();
      if (res.ok && data.status === 'success') {
        console.log(`  [OK] ${cand.name} registered as [${cand.vehicleType.toUpperCase()}] -> App ID: ${data.data?.applicationId}`);
        registered.push({ ...cand, driverId: data.data?.driverId, appId: data.data?.applicationId });
      } else {
        console.error(`  [FAIL] ${cand.name}:`, data.message || data);
      }
    } catch (err: any) {
      console.error(`  [ERROR] Failed to submit ${cand.name}:`, err.message);
    }
  }

  console.log(`\n▶ STEP 2: Logging in as Regional Transport Command Admin...`);
  let token = '';
  try {
    const loginRes = await fetch(`${BASE_URL}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'admin@acmelogistics.com',
        password: 'SmartDrive2026!'
      })
    });
    const loginData: any = await loginRes.json();
    if (loginRes.ok) {
      token = loginData.data?.accessToken;
      console.log(`  [OK] Admin authenticated. Token received.`);
    } else {
      console.error('  [FAIL] Admin login failed:', loginData.message);
    }
  } catch (err: any) {
    console.error('  [ERROR] Admin login connection error:', err.message);
  }

  if (token) {
    console.log(`\n▶ STEP 3: Querying Driver Requests via Admin API...`);
    try {
      const driversRes = await fetch(`${BASE_URL}/api/drivers`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const driversData: any = await driversRes.json();
      const list = driversData.data || [];
      console.log(`  Total Drivers in System: ${list.length}`);
      const pending = list.filter((d: any) => d.status === 'PENDING_APPROVAL');
      console.log(`  Pending Approval Applications: ${pending.length}`);
      
      console.log('\n  -- RECENT PENDING APPLICANTS IN QUEUE --');
      pending.slice(0, 5).forEach((d: any, idx: number) => {
        const vehicleBadge = d.badges?.find((b: string) => b.startsWith('applied_vehicle:'))?.split(':')[1] || d.driverType;
        console.log(`  ${idx + 1}. ${d.user?.firstName} ${d.user?.lastName} | Vehicle: [${vehicleBadge}] | Zone: ${d.user?.zone}`);
      });
    } catch (err: any) {
      console.error('  [ERROR] Failed to fetch drivers list:', err.message);
    }

    if (registered.length > 0) {
      const target = registered[0];
      console.log(`\n▶ STEP 4: Simulating One-Click Approval & Email Dispatch for: ${target.name}...`);
      try {
        const approveRes = await fetch(`${BASE_URL}/api/drivers/${target.driverId}/approve`, {
          method: 'POST',
          headers: { 
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}` 
          }
        });
        const approveData: any = await approveRes.json();
        if (approveRes.ok) {
          console.log(`  [OK] Approval Successful!`);
          console.log(`  - Driver Code: ${approveData.data?.driverCode || 'Generated'}`);
          console.log(`  - Credentials Email Status: ${approveData.message}`);
        } else {
          console.error(`  [FAIL] Approval failed:`, approveData.message);
        }
      } catch (err: any) {
        console.error('  [ERROR] Approval request error:', err.message);
      }
    }
  }

  console.log('\n================================================================');
  console.log('                  TEST RUN COMPLETE!                           ');
  console.log('================================================================');
  console.log('Now open the Admin Dashboard (http://localhost:5173/requests) or');
  console.log('Mobile App to see the live vector symbols & wheel badges in action.');
}

runVehicleOnboardingTest();
