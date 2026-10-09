import { PrismaClient, Role, DriverType } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function createMockDriver() {
  console.log('🔄 Connecting to Database to create mock test user...');

  try {
    // 1. Ensure Default Organization exists
    const org = await prisma.organization.upsert({
      where: { id: '00000000-0000-0000-0000-000000000001' },
      update: {},
      create: {
        id: '00000000-0000-0000-0000-000000000001',
        name: 'Smart Driving Command Center',
      },
    });

    const email = 'driver.test@smartdrive.ai';
    const rawPassword = 'password123';
    const passwordHash = await bcrypt.hash(rawPassword, 10);

    // 2. Create or Update User
    const user = await prisma.user.upsert({
      where: { email },
      update: {
        passwordHash,
        role: Role.DRIVER,
        firstName: 'Pranav',
        lastName: 'Kumar',
        phoneNumber: '+91 98451 23098',
        zone: 'puttur_taluk',
      },
      create: {
        email,
        passwordHash,
        firstName: 'Pranav',
        lastName: 'Kumar',
        role: Role.DRIVER,
        phoneNumber: '+91 98451 23098',
        organizationId: org.id,
        zone: 'puttur_taluk',
      },
    });

    // 3. Create or Update Driver Profile
    const driver = await prisma.driver.upsert({
      where: { userId: user.id },
      update: {
        licenseNumber: 'KA1920260012345',
        licenseExpiry: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000 * 5),
        emergencyContactName: 'Ramesh Kumar',
        emergencyContactPhone: '+91 94481 00000',
        safetyScore: 94.5,
        riskScore: 5.5,
        status: 'ACTIVE',
        driverType: DriverType.TACTICAL,
        xp: 2450,
        level: 5,
        streak: 12,
      },
      create: {
        userId: user.id,
        licenseNumber: 'KA1920260012345',
        licenseExpiry: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000 * 5),
        emergencyContactName: 'Ramesh Kumar',
        emergencyContactPhone: '+91 94481 00000',
        safetyScore: 94.5,
        riskScore: 5.5,
        status: 'ACTIVE',
        driverType: DriverType.TACTICAL,
        xp: 2450,
        level: 5,
        streak: 12,
      },
    });

    console.log('\n======================================================');
    console.log('🎉 MOCK TEST ACCOUNT SUCCESSFULLY CREATED IN DATABASE');
    console.log('======================================================');
    console.log(`📧 Email:       ${user.email}`);
    console.log(`🔑 Password:    ${rawPassword}`);
    console.log(`👤 Name:        ${user.firstName} ${user.lastName}`);
    console.log(`🛡️ Role:        ${user.role}`);
    console.log(`📱 Phone:       ${user.phoneNumber}`);
    console.log(`🆔 Driver ID:   ${driver.id}`);
    console.log(`⭐ Safety Score: ${driver.safetyScore}% | Status: ${driver.status}`);
    console.log('======================================================\n');
  } catch (error) {
    console.error('❌ Error creating mock driver in database:', error);
  } finally {
    await prisma.$disconnect();
  }
}

createMockDriver();
