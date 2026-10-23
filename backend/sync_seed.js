const { PrismaClient, Role, VehicleType, MaintenanceStatus, TripStatus } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

async function main() {
  console.log('Synchronizing users and passwords...');
  const passwordHash = await bcrypt.hash('SmartDrive2026!', 10);

  // 1. Get or create default Organization
  let org = await prisma.organization.findFirst();
  if (!org) {
    org = await prisma.organization.create({
      data: {
        id: '00000000-0000-0000-0000-000000000001',
        name: 'Smart Driving Command Center',
      }
    });
  }

  // 2. Ensure Fleet Admin
  await prisma.user.upsert({
    where: { email: 'admin@smartdrive.ai' },
    update: { passwordHash, role: Role.FLEET_ADMIN },
    create: {
      email: 'admin@smartdrive.ai',
      passwordHash,
      firstName: 'Mohammed',
      lastName: 'Afzal',
      role: Role.FLEET_ADMIN,
      organizationId: org.id,
      zone: 'all'
    }
  });
  console.log('✓ Fleet Admin synced: admin@smartdrive.ai');

  // 3. Ensure Drivers
  const driversToSync = [
    {
      email: 'suresh.nayak@smartdrive.ai',
      firstName: 'Suresh',
      lastName: 'Nayak',
      license: 'KA1920210049281',
      score: 94.2,
      risk: 5.8,
      status: 'ACTIVE',
      zone: 'Karnataka, Dakshina Kannada, Puttur'
    },
    {
      email: 'rajesh.kumar@smartdrive.ai',
      firstName: 'Rajesh',
      lastName: 'Kumar',
      license: 'KA2020210010294',
      score: 92.5,
      risk: 7.5,
      status: 'ACTIVE',
      zone: 'Karnataka, Dakshina Kannada, Mangaluru'
    },
    {
      email: 'driver.test@smartdrive.ai',
      firstName: 'Pranav',
      lastName: 'Kumar',
      license: 'KA2120220005509',
      score: 95.0,
      risk: 5.0,
      status: 'ACTIVE',
      zone: 'puttur_taluk'
    }
  ];

  for (const d of driversToSync) {
    const user = await prisma.user.upsert({
      where: { email: d.email },
      update: { passwordHash, role: Role.DRIVER, zone: d.zone },
      create: {
        email: d.email,
        passwordHash,
        firstName: d.firstName,
        lastName: d.lastName,
        role: Role.DRIVER,
        organizationId: org.id,
        zone: d.zone
      }
    });

    await prisma.driver.upsert({
      where: { userId: user.id },
      update: {
        safetyScore: d.score,
        riskScore: d.risk,
        status: d.status,
      },
      create: {
        userId: user.id,
        licenseNumber: d.license,
        licenseExpiry: new Date('2030-12-31'),
        emergencyContactName: 'Emergency Support',
        emergencyContactPhone: '+919876543210',
        safetyScore: d.score,
        riskScore: d.risk,
        status: d.status,
        xp: 2500,
        level: 5,
        streak: 12,
        badges: ['Safe Driver', 'Eco Cruiser', 'Night Owl']
      }
    });
    console.log(`✓ Driver synced: ${d.email}`);
  }

  // 4. Update ALL existing users in DB to also have SmartDrive2026! as password
  const allUsers = await prisma.user.findMany();
  for (const u of allUsers) {
    await prisma.user.update({
      where: { id: u.id },
      data: { passwordHash }
    });
  }
  console.log(`✓ Updated all ${allUsers.length} users with password: SmartDrive2026!`);
}

main().catch(console.error).finally(() => prisma.$disconnect());
