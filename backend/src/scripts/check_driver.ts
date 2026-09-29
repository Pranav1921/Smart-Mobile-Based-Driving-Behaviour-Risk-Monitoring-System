import { prisma } from '../database/client';

async function check() {
  const drivers = await prisma.driver.findMany({
    include: {
      user: true,
    },
  });
  console.log('=== DRIVERS IN DATABASE ===');
  for (const d of drivers) {
    console.log(JSON.stringify({
      id: d.id,
      userId: d.userId,
      name: `${d.user?.firstName} ${d.user?.lastName}`,
      userEmail: d.user?.email,
      userPhone: d.user?.phoneNumber,
      licenseNumber: d.licenseNumber,
      emergencyContactName: d.emergencyContactName,
      emergencyContactPhone: d.emergencyContactPhone,
      badges: d.badges,
    }, null, 2));
  }
  await prisma.$disconnect();
}

check().catch(console.error);
