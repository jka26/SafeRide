const { PrismaClient, Role } = require('@prisma/client');

const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany({
    select: { id: true, role: true },
  });

  const driverUserIds = users
    .filter((u) => u.role === Role.DRIVER)
    .map((u) => u.id);
  const parentUserIds = users
    .filter((u) => u.role === Role.PARENT)
    .map((u) => u.id);

  const existingDrivers = await prisma.driver.findMany({
    select: { userId: true },
    where: { userId: { in: driverUserIds } },
  });
  const existingParents = await prisma.parent.findMany({
    select: { userId: true },
    where: { userId: { in: parentUserIds } },
  });

  const existingDriverSet = new Set(existingDrivers.map((d) => d.userId));
  const existingParentSet = new Set(existingParents.map((p) => p.userId));

  const missingDriverUserIds = driverUserIds.filter((id) => !existingDriverSet.has(id));
  const missingParentUserIds = parentUserIds.filter((id) => !existingParentSet.has(id));

  let createdDrivers = 0;
  let createdParents = 0;

  if (missingDriverUserIds.length > 0) {
    const result = await prisma.driver.createMany({
      data: missingDriverUserIds.map((userId) => ({ userId })),
      skipDuplicates: true,
    });
    createdDrivers = result.count;
  }

  if (missingParentUserIds.length > 0) {
    const result = await prisma.parent.createMany({
      data: missingParentUserIds.map((userId) => ({ userId })),
      skipDuplicates: true,
    });
    createdParents = result.count;
  }

  console.log(
    JSON.stringify(
      {
        totalUsers: users.length,
        driverUsers: driverUserIds.length,
        parentUsers: parentUserIds.length,
        createdDrivers,
        createdParents,
      },
      null,
      2,
    ),
  );
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
