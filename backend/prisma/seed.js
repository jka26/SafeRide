const { PrismaClient, Role } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  const adminEmail = 'admin@saferide.local';
  const driverEmail = 'driver@saferide.local';
  const parentEmail = 'parent@saferide.local';
  const passwordHash = await bcrypt.hash('Password123!', 10);

  const admin = await prisma.user.upsert({
    where: { email: adminEmail },
    update: {},
    create: {
      email: adminEmail,
      passwordHash,
      role: Role.ADMIN,
      fullName: 'System Admin',
    },
  });

  const driverUser = await prisma.user.upsert({
    where: { email: driverEmail },
    update: {},
    create: {
      email: driverEmail,
      passwordHash,
      role: Role.DRIVER,
      fullName: 'Sample Driver',
    },
  });

  const parentUser = await prisma.user.upsert({
    where: { email: parentEmail },
    update: {},
    create: {
      email: parentEmail,
      passwordHash,
      role: Role.PARENT,
      fullName: 'Sample Parent',
    },
  });

  const parent = await prisma.parent.upsert({
    where: { userId: parentUser.id },
    update: {},
    create: { userId: parentUser.id },
  });

  await prisma.driver.upsert({
    where: { userId: driverUser.id },
    update: {},
    create: { userId: driverUser.id },
  });

  await prisma.student.createMany({
    data: [
      {
        studentCode: 'SR-001',
        fullName: 'Student One',
        grade: 'Grade 4',
        parentId: parent.id,
      },
      {
        studentCode: 'SR-002',
        fullName: 'Student Two',
        grade: 'Grade 2',
        parentId: parent.id,
      },
    ],
    skipDuplicates: true,
  });

  console.log('Seed completed', { adminId: admin.id });
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
