const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');
const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany();
  for (const u of users) {
    const isSmartDrive = await bcrypt.compare('SmartDrive2026!', u.passwordHash);
    const isAdmin123 = await bcrypt.compare('admin123', u.passwordHash);
    const isPuttur = await bcrypt.compare('puttur2026', u.passwordHash);
    console.log(`${u.email} (${u.role}): SmartDrive2026!=${isSmartDrive}, admin123=${isAdmin123}, puttur2026=${isPuttur}`);
  }
}

main().catch(console.error).finally(() => prisma.$disconnect());
