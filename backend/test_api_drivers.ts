async function test() {
  try {
    const loginRes = await fetch('http://localhost:3000/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'admin@acmelogistics.com',
        password: 'SmartDrive2026!'
      })
    });
    const loginData: any = await loginRes.json();
    const token = loginData.data?.accessToken;
    console.log('Token acquired');

    const driversRes = await fetch('http://localhost:3000/api/drivers', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const driversData: any = await driversRes.json();
    const list = driversData.data || [];
    console.log('Drivers Count:', list.length);
    list.forEach((d: any) => {
      console.log(`- ${d.user?.firstName} ${d.user?.lastName} | Status: ${d.status} | Zone: ${d.user?.zone}`);
    });
  } catch (err: any) {
    console.error('API Error:', err.message);
  }
}

test();
