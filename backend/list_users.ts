import { prisma } from './src/database/client';

async function list() {
  try {
    const users = await prisma.user.findMany({
      include: { driverProfile: true }
    });
    console.log('All Users:');
    users.forEach(u => {
      console.log(`- ${u.firstName} ${u.lastName} (${u.email}) | Role: ${u.role} | Zone: ${u.zone} | Has Driver Profile: ${!!u.driverProfile}`);
    });
  } catch (err) {
    console.error(err);
  } finally {
    await prisma.$disconnect();
  }
}

list();
