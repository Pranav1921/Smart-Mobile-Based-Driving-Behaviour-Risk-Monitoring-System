import { PrismaClient, Role, VehicleType, MaintenanceStatus, TripStatus, EventType, Severity } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting Smart Driving Database Seed...');

  // 1. Create Organization
  const org = await prisma.organization.upsert({
    where: { id: '00000000-0000-0000-0000-000000000001' },
    update: {},
    create: {
      id: '00000000-0000-0000-0000-000000000001',
      name: 'Smart Driving Command Center',
    },
  });
  console.log(`✅ Organization created: ${org.name}`);

  // 2. Settings
  await prisma.settings.upsert({
    where: { organizationId: org.id },
    update: {},
    create: {
      organizationId: org.id,
      overspeedThreshold: 80.0,
      harshBrakingThreshold: -3.0,
      rapidAccelerationThreshold: 3.0,
      sharpTurnThreshold: 4.0,
    },
  });

  const passwordHash = await bcrypt.hash('SmartDrive2026!', 10);

  // 3. Fleet Admin User
  const adminUser = await prisma.user.upsert({
    where: { email: 'admin@smartdrive.ai' },
    update: {},
    create: {
      email: 'admin@smartdrive.ai',
      passwordHash,
      firstName: 'Mohammed',
      lastName: 'Afzal',
      role: Role.FLEET_ADMIN,
      organizationId: org.id,
    },
  });
  console.log(`✅ Fleet Admin created: ${adminUser.email}`);

  // 4. Driver Users & Profiles
  const driversData = [
    {
      email: 'suresh.nayak@smartdrive.ai',
      firstName: 'Suresh',
      lastName: 'Nayak',
      license: 'KA1920210049281',
      score: 84.2,
      risk: 15.8,
      status: 'ON_TRIP',
      xp: 1450,
      level: 4,
      streak: 7,
    },
    {
      email: 'rajesh.kumar@smartdrive.ai',
      firstName: 'Rajesh',
      lastName: 'Kumar',
      license: 'KA2020210010294',
      score: 92.5,
      risk: 7.5,
      status: 'ACTIVE',
      xp: 2300,
      level: 6,
      streak: 14,
    },
    {
      email: 'anita.sharma@smartdrive.ai',
      firstName: 'Anita',
      lastName: 'Sharma',
      license: 'MH1220200088192',
      score: 96.0,
      risk: 4.0,
      status: 'ACTIVE',
      xp: 3100,
      level: 8,
      streak: 21,
    },
    {
      email: 'vikram.singh@smartdrive.ai',
      firstName: 'Vikram',
      lastName: 'Singh',
      license: 'DL0120190099120',
      score: 78.4,
      risk: 21.6,
      status: 'ACTIVE',
      xp: 980,
      level: 3,
      streak: 2,
    },
    {
      email: 'priya.patel@smartdrive.ai',
      firstName: 'Priya',
      lastName: 'Patel',
      license: 'GJ0620220055410',
      score: 89.1,
      risk: 10.9,
      status: 'ACTIVE',
      xp: 1890,
      level: 5,
      streak: 9,
    },
  ];

  const createdDrivers = [];

  for (const d of driversData) {
    const user = await prisma.user.upsert({
      where: { email: d.email },
      update: {},
      create: {
        email: d.email,
        passwordHash,
        firstName: d.firstName,
        lastName: d.lastName,
        role: Role.DRIVER,
        organizationId: org.id,
      },
    });

    const driver = await prisma.driver.upsert({
      where: { userId: user.id },
      update: {
        safetyScore: d.score,
        riskScore: d.risk,
        status: d.status,
      },
      create: {
        userId: user.id,
        licenseNumber: d.license,
        licenseExpiry: new Date('2028-12-31'),
        emergencyContactName: 'Emergency Support',
        emergencyContactPhone: '+919876543210',
        safetyScore: d.score,
        riskScore: d.risk,
        status: d.status,
        xp: d.xp,
        level: d.level,
        streak: d.streak,
        badges: ['Safe Driver', 'Night Owl', 'Eco Cruiser'],
      },
    });

    createdDrivers.push({ user, driver });
  }
  console.log(`✅ Seeded ${createdDrivers.length} drivers`);

  // 5. Vehicles
  const vehiclesData = [
    {
      make: 'Tata',
      model: 'Ace Gold Diesel',
      year: 2023,
      type: VehicleType.PICKUP,
      plate: 'KA-19-MN-4092',
    },
    {
      make: 'Mahindra',
      model: 'Treo Zor EV',
      year: 2024,
      type: VehicleType.SCOOTER,
      plate: 'KA-20-EV-1024',
    },
    {
      make: 'Eicher',
      model: 'Pro 2049',
      year: 2022,
      type: VehicleType.TRUCK,
      plate: 'MH-12-FG-8819',
    },
    {
      make: 'Ashok Leyland',
      model: 'Bada Dost i4',
      year: 2023,
      type: VehicleType.VAN,
      plate: 'DL-01-AX-9912',
    },
    {
      make: 'TVS',
      model: 'iQube Cargo',
      year: 2024,
      type: VehicleType.MOTORCYCLE,
      plate: 'GJ-06-FG-5541',
    },
  ];

  const createdVehicles = [];

  for (const v of vehiclesData) {
    const vehicle = await prisma.vehicle.upsert({
      where: { licensePlate: v.plate },
      update: {},
      create: {
        organizationId: org.id,
        make: v.make,
        model: v.model,
        year: v.year,
        vehicleType: v.type,
        licensePlate: v.plate,
        insuranceNumber: `INS-${Math.floor(100000 + Math.random() * 900000)}`,
        insuranceExpiry: new Date('2027-06-30'),
        registrationNumber: `REG-${Math.floor(100000 + Math.random() * 900000)}`,
        maintenanceStatus: MaintenanceStatus.HEALTHY,
      },
    });
    createdVehicles.push(vehicle);
  }
  console.log(`✅ Seeded ${createdVehicles.length} vehicles`);

  // 6. Vehicle Assignments
  for (let i = 0; i < createdDrivers.length; i++) {
    await prisma.vehicleAssignment.create({
      data: {
        driverId: createdDrivers[i].driver.id,
        vehicleId: createdVehicles[i].id,
      },
    });
  }

  // 7. Ongoing & Completed Trips
  const trip1 = await prisma.trip.create({
    data: {
      driverId: createdDrivers[0].driver.id,
      vehicleId: createdVehicles[0].id,
      organizationId: org.id,
      status: TripStatus.ONGOING,
      startTime: new Date(Date.now() - 3600 * 1000 * 2),
      distance: 42.5,
      duration: 7200,
      avgSpeed: 45.2,
      maxSpeed: 78.5,
    },
  });

  const trip2 = await prisma.trip.create({
    data: {
      driverId: createdDrivers[1].driver.id,
      vehicleId: createdVehicles[1].id,
      organizationId: org.id,
      status: TripStatus.COMPLETED,
      startTime: new Date(Date.now() - 3600 * 1000 * 24),
      endTime: new Date(Date.now() - 3600 * 1000 * 22),
      distance: 85.0,
      duration: 7200,
      avgSpeed: 52.1,
      maxSpeed: 82.0,
    },
  });

  // 8. Events
  await prisma.event.createMany({
    data: [
      {
        tripId: trip1.id,
        driverId: createdDrivers[0].driver.id,
        organizationId: org.id,
        eventType: EventType.HARSH_BRAKING,
        severity: Severity.HIGH,
        latitude: 12.9141,
        longitude: 74.856,
        timestamp: new Date(Date.now() - 1800 * 1000),
        sensorValues: { speed: 64, decel: -4.2 },
      },
      {
        tripId: trip1.id,
        driverId: createdDrivers[0].driver.id,
        organizationId: org.id,
        eventType: EventType.OVERSPEED,
        severity: Severity.MEDIUM,
        latitude: 12.9201,
        longitude: 74.862,
        timestamp: new Date(Date.now() - 900 * 1000),
        sensorValues: { speed: 88, limit: 80 },
      },
      {
        tripId: trip2.id,
        driverId: createdDrivers[1].driver.id,
        organizationId: org.id,
        eventType: EventType.SHARP_TURN,
        severity: Severity.LOW,
        latitude: 12.935,
        longitude: 74.84,
        timestamp: new Date(Date.now() - 3600 * 1000 * 23),
        sensorValues: { lateralG: 0.65 },
      },
    ],
  });

  console.log('✨ Seed execution finished successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Error seeding database:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
