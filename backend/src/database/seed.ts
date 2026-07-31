import {
  PrismaClient,
  Role,
  VehicleType,
  MaintenanceStatus,
} from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding Database...');

  // Delete previous seed mappings (to support clean re-runs)
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

  // Create Acme Logistics organization
  const orgAcme = await prisma.organization.create({
    data: {
      name: 'Acme Logistics Corp',
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

  // Create Beta Deliveries organization without variable assignment (unused warning fix)
  await prisma.organization.create({
    data: {
      name: 'Beta Delivery Services',
      settings: {
        create: {
          overspeedThreshold: 90.0,
          harshBrakingThreshold: -2.8,
          rapidAccelerationThreshold: 3.2,
          sharpTurnThreshold: 4.5,
        },
      },
    },
  });

  const passwordHash = await bcrypt.hash('FleetGuard2026!', 10);

  // 1. Create Super Admin
  await prisma.user.create({
    data: {
      email: 'superadmin@fleetguard.ai',
      passwordHash,
      firstName: 'Super',
      lastName: 'Admin',
      role: Role.SUPER_ADMIN,
    },
  });

  // 2. Create Acme Fleet Admin
  await prisma.user.create({
    data: {
      email: 'admin@acmelogistics.com',
      passwordHash,
      firstName: 'Acme',
      lastName: 'Admin',
      role: Role.FLEET_ADMIN,
      organizationId: orgAcme.id,
    },
  });

  // 3. Create Acme Fleet Manager
  await prisma.user.create({
    data: {
      email: 'manager@acmelogistics.com',
      passwordHash,
      firstName: 'John',
      lastName: 'Manager',
      role: Role.FLEET_MANAGER,
      organizationId: orgAcme.id,
    },
  });

  // 4. Create Drivers for Acme
  const driverUser1 = await prisma.user.create({
    data: {
      email: 'driver1@acmelogistics.com',
      passwordHash,
      firstName: 'David',
      lastName: 'Driver',
      role: Role.DRIVER,
      organizationId: orgAcme.id,
    },
  });

  const driverProfile1 = await prisma.driver.create({
    data: {
      userId: driverUser1.id,
      licenseNumber: 'DL-US-99120',
      licenseExpiry: new Date('2030-12-31'),
      emergencyContactName: 'Sarah Driver',
      emergencyContactPhone: '+1-555-0199',
      status: 'ACTIVE',
      safetyScore: 95.0,
      riskScore: 5.0,
      xp: 2450,
      level: 3,
      streak: 5,
      badges: ['smooth_operator', 'speed_sentinel']
    },
  });

  const driverUser2 = await prisma.user.create({
    data: {
      email: 'driver2@acmelogistics.com',
      passwordHash,
      firstName: 'Sarah',
      lastName: 'Speedy',
      role: Role.DRIVER,
      organizationId: orgAcme.id,
    },
  });

  // Save profile without variable assignment (unused warning fix)
  await prisma.driver.create({
    data: {
      userId: driverUser2.id,
      licenseNumber: 'DL-US-48210',
      licenseExpiry: new Date('2029-06-30'),
      emergencyContactName: 'Mark Speedy',
      emergencyContactPhone: '+1-555-0211',
      status: 'ACTIVE',
      safetyScore: 78.0,
      riskScore: 22.0,
      xp: 890,
      level: 1,
      streak: 1,
      badges: ['focus_champion']
    },
  });

  // Create Vehicles
  const vehicle1 = await prisma.vehicle.create({
    data: {
      organizationId: orgAcme.id,
      make: 'Tesla',
      model: 'Model Y',
      year: 2024,
      vehicleType: VehicleType.CAR,
      licensePlate: 'FG-101-AI',
      insuranceNumber: 'INS-ACME-4001',
      insuranceExpiry: new Date('2027-01-01'),
      registrationNumber: 'REG-FG-991',
      maintenanceStatus: MaintenanceStatus.HEALTHY,
    },
  });

  // Save vehicle without variable assignment (unused warning fix)
  await prisma.vehicle.create({
    data: {
      organizationId: orgAcme.id,
      make: 'Ford',
      model: 'Transit Van',
      year: 2023,
      vehicleType: VehicleType.VAN,
      licensePlate: 'FG-202-AI',
      insuranceNumber: 'INS-ACME-4002',
      insuranceExpiry: new Date('2026-09-01'),
      registrationNumber: 'REG-FG-992',
      maintenanceStatus: MaintenanceStatus.HEALTHY,
    },
  });

  // Assign vehicle1 to driverProfile1
  await prisma.vehicleAssignment.create({
    data: {
      driverId: driverProfile1.id,
      vehicleId: vehicle1.id,
      assignedAt: new Date(),
    },
  });

  console.log('Database Seeding Completed Successfully.');
}

main()
  .catch((e) => {
    console.error('Failed to seed database:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
