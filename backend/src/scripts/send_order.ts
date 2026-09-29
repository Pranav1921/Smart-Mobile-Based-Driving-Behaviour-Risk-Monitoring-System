import http from 'http';

const customerName = process.argv[2] || 'Swadeshi Customer';
const items = process.argv[3] ? [process.argv[3]] : ['2x Chicken Biryani', '1x Butter Naan'];
const address = process.argv[4] || 'Hampankatta Towers, Mangalore';
const lat = parseFloat(process.argv[5]) || 12.9141;
const lng = parseFloat(process.argv[6]) || 74.8560;

const postData = JSON.stringify({
  customerName,
  items,
  amount: 349,
  deliveryLocation: {
    latitude: lat,
    longitude: lng,
    address,
  },
});

const req = http.request(
  {
    hostname: 'localhost',
    port: 3000,
    path: '/api/orders',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData),
    },
  },
  (res) => {
    let responseBody = '';
    res.on('data', (chunk) => (responseBody += chunk));
    res.on('end', () => {
      console.log('✅ New Order Created Successfully!');
      console.log(responseBody);
    });
  }
);

req.on('error', (e) => {
  console.error('❌ Failed to create order:', e.message);
});

req.write(postData);
req.end();
