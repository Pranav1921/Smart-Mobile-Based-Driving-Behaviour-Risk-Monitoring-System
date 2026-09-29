import {
  PrismaClient,
  Role,
} from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('STRICT PURGE: Removing all existing records...');

  // Order matters for foreign keys
  await prisma.auditLog.deleteMany({});
  await prisma.notification.deleteMany({});
  await prisma.media.deleteMany({});
  await prisma.crashReport.deleteMany({});
  await prisma.event.deleteMany({});
  await prisma.tripPoint.deleteMany({});
  await prisma.trip.deleteMany({});
  await prisma.vehicleAssignment.deleteMany({});
  await prisma.driverScore.deleteMany({});
  await prisma.driver.deleteMany({});
  await prisma.vehicle.deleteMany({});
  await prisma.settings.deleteMany({});
  await prisma.user.deleteMany({});
  await prisma.organization.deleteMany({});

  console.log('Creating Clean System Assets...');

  const orgAcme = await prisma.organization.create({
    data: {
      name: 'Acme Logistics HQ',
      settings: {
        create: {
          overspeedThreshold: 80.0,
          harshBrakingThreshold: -3.0,
          rapidAccelerationThreshold: 3.0,
          sharpTurnThreshold: 4.0,
        },
      },
    },
  });

  const passwordHash = await bcrypt.hash('SmartDrive2026!', 10);

  // 1. Create System Admin
  await prisma.user.create({
    data: {
      email: 'admin@acmelogistics.com',
      passwordHash,
      firstName: 'System',
      lastName: 'Admin',
      role: Role.FLEET_ADMIN,
      organizationId: orgAcme.id,
      zone: 'puttur_hq',
    },
  });

  console.log('DATABASE READY: 0 Drivers. 1 Admin. 0 Dummy Data.');
}

main()
  .catch((e) => {
    console.error('Failed to purge/seed database:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
