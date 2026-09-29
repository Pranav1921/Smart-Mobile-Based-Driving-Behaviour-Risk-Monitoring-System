import IORedis from 'ioredis';

const REDIS_URL = process.env.REDIS_URL || 'redis://127.0.0.1:6379';
const redis = new IORedis(REDIS_URL);

redis.on('connect', () => {
  console.log('✅ Connected to Redis at', REDIS_URL);
  process.exit(0);
});

redis.on('error', (err) => {
  console.error('❌ Redis Error:', err);
  process.exit(1);
});

setTimeout(() => {
  console.log('⌛ Connection timeout');
  process.exit(1);
}, 5000);
