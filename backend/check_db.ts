import { prisma } from './src/database/client';

async function check() {
  try {
    const userCount = await prisma.user.count();
    const driverCount = await prisma.driver.count();
    const organizationCount = await prisma.organization.count();
    console.log(`Users: ${userCount}`);
    console.log(`Drivers: ${driverCount}`);
    console.log(`Organizations: ${organizationCount}`);

    const drivers = await prisma.driver.findMany({ include: { user: true } });
    drivers.forEach(d => {
      console.log(`- Driver: ${d.user.firstName} ${d.user.lastName}, Zone: ${(d.user as any).zone}, ID: ${d.id}`);
    });
  } catch (err) {
    console.error(err);
  } finally {
    await prisma.$disconnect();
  }
}

check();
