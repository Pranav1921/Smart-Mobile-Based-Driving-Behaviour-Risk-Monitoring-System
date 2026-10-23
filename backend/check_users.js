const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany({
    include: { driverProfile: true }
  });
  console.log(`Found ${users.length} users:`);
  for (const u of users) {
    console.log(`- ID: ${u.id} | Email: "${u.email}" | Role: ${u.role} | Name: ${u.firstName} ${u.lastName} | Zone: ${u.zone}`);
    if (u.driverProfile) {
      console.log(`  DriverProfile: ID: ${u.driverProfile.id} | Status: ${u.driverProfile.status} | Code: ${u.driverProfile.id.slice(0,8).toUpperCase()}`);
    }
  }
}

main().catch(console.error).finally(() => prisma.$disconnect());
