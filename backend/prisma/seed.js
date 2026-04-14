const { PrismaClient, Role, TripStatus, AttendanceStatus } = require('@prisma/client');
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

  const secondParentUser = await prisma.user.upsert({
    where: { email: 'parent2@saferide.local' },
    update: {
      fullName: 'Sample Parent Two',
      role: Role.PARENT,
    },
    create: {
      email: 'parent2@saferide.local',
      passwordHash,
      role: Role.PARENT,
      fullName: 'Sample Parent Two',
    },
  });

  const secondParent = await prisma.parent.upsert({
    where: { userId: secondParentUser.id },
    update: {},
    create: { userId: secondParentUser.id },
  });

  const driver = await prisma.driver.upsert({
    where: { userId: driverUser.id },
    update: {},
    create: { userId: driverUser.id },
  });

  const studentOne = await prisma.student.upsert({
    where: { studentCode: 'SR-001' },
    update: {
      fullName: 'Student One',
      grade: 'Grade 4',
      parentId: parent.id,
      routeName: 'East Corridor',
      busLabel: 'Bus 12',
      stopName: 'Main Gate',
      dropOffTime: '3:15 PM',
      emergencyContactName: 'Ama Mensah',
      emergencyContactPhone: '+233200000001',
    },
    create: {
      studentCode: 'SR-001',
      fullName: 'Student One',
      grade: 'Grade 4',
      parentId: parent.id,
      routeName: 'East Corridor',
      busLabel: 'Bus 12',
      stopName: 'Main Gate',
      dropOffTime: '3:15 PM',
      emergencyContactName: 'Ama Mensah',
      emergencyContactPhone: '+233200000001',
    },
  });

  const studentTwo = await prisma.student.upsert({
    where: { studentCode: 'SR-002' },
    update: {
      fullName: 'Student Two',
      grade: 'Grade 2',
      parentId: parent.id,
      routeName: 'West Corridor',
      busLabel: 'Bus 07',
      stopName: 'Community Park',
      dropOffTime: '3:35 PM',
      emergencyContactName: 'Kojo Boateng',
      emergencyContactPhone: '+233200000002',
    },
    create: {
      studentCode: 'SR-002',
      fullName: 'Student Two',
      grade: 'Grade 2',
      parentId: parent.id,
      routeName: 'West Corridor',
      busLabel: 'Bus 07',
      stopName: 'Community Park',
      dropOffTime: '3:35 PM',
      emergencyContactName: 'Kojo Boateng',
      emergencyContactPhone: '+233200000002',
    },
  });

  const studentThree = await prisma.student.upsert({
    where: { studentCode: 'SR-003' },
    update: {
      fullName: 'Student Three',
      grade: 'Grade 5',
      parentId: secondParent.id,
      routeName: 'East Corridor',
      busLabel: 'Bus 12',
      stopName: 'Airport Junction',
      dropOffTime: '3:10 PM',
      emergencyContactName: 'Naa Adjeley',
      emergencyContactPhone: '+233200000003',
    },
    create: {
      studentCode: 'SR-003',
      fullName: 'Student Three',
      grade: 'Grade 5',
      parentId: secondParent.id,
      routeName: 'East Corridor',
      busLabel: 'Bus 12',
      stopName: 'Airport Junction',
      dropOffTime: '3:10 PM',
      emergencyContactName: 'Naa Adjeley',
      emergencyContactPhone: '+233200000003',
    },
  });

  const studentFour = await prisma.student.upsert({
    where: { studentCode: 'SR-004' },
    update: {
      fullName: 'Student Four',
      grade: 'Grade 1',
      parentId: secondParent.id,
      routeName: 'West Corridor',
      busLabel: 'Bus 07',
      stopName: 'North Ridge',
      dropOffTime: '3:40 PM',
      emergencyContactName: 'Yaw Tetteh',
      emergencyContactPhone: '+233200000004',
    },
    create: {
      studentCode: 'SR-004',
      fullName: 'Student Four',
      grade: 'Grade 1',
      parentId: secondParent.id,
      routeName: 'West Corridor',
      busLabel: 'Bus 07',
      stopName: 'North Ridge',
      dropOffTime: '3:40 PM',
      emergencyContactName: 'Yaw Tetteh',
      emergencyContactPhone: '+233200000004',
    },
  });

  const busEast = await prisma.bus.upsert({
    where: { plateNumber: 'GR-1207-24' },
    update: {
      capacity: 30,
      routeName: 'East Corridor',
    },
    create: {
      plateNumber: 'GR-1207-24',
      capacity: 30,
      routeName: 'East Corridor',
    },
  });

  const busWest = await prisma.bus.upsert({
    where: { plateNumber: 'GR-3304-24' },
    update: {
      capacity: 28,
      routeName: 'West Corridor',
    },
    create: {
      plateNumber: 'GR-3304-24',
      capacity: 28,
      routeName: 'West Corridor',
    },
  });

  const todayMorning = new Date();
  todayMorning.setHours(7, 30, 0, 0);

  const todayAfternoon = new Date();
  todayAfternoon.setHours(15, 0, 0, 0);

  const tomorrowMorning = new Date(todayMorning);
  tomorrowMorning.setDate(tomorrowMorning.getDate() + 1);

  // Keep demo trips deterministic on reruns.
  await prisma.trip.deleteMany({
    where: {
      name: {
        in: [
          'DEMO Morning Pickup',
          'DEMO Afternoon Dropoff',
          'DEMO Tomorrow Pickup',
        ],
      },
    },
  });

  const tripMorning = await prisma.trip.create({
    data: {
      name: 'DEMO Morning Pickup',
      busId: busEast.id,
      driverId: driver.id,
      tripDate: todayMorning,
      status: TripStatus.IN_PROGRESS,
      startedAt: new Date(todayMorning.getTime() + 5 * 60 * 1000),
      currentStopName: 'Main Gate',
      etaMinutes: 8,
    },
  });

  const tripAfternoon = await prisma.trip.create({
    data: {
      name: 'DEMO Afternoon Dropoff',
      busId: busWest.id,
      driverId: driver.id,
      tripDate: todayAfternoon,
      status: TripStatus.SCHEDULED,
    },
  });

  const tripTomorrow = await prisma.trip.create({
    data: {
      name: 'DEMO Tomorrow Pickup',
      busId: busEast.id,
      driverId: driver.id,
      tripDate: tomorrowMorning,
      status: TripStatus.SCHEDULED,
    },
  });

  await prisma.tripLocation.createMany({
    data: [
      {
        tripId: tripMorning.id,
        latitude: 5.6037,
        longitude: -0.187,
      },
      {
        tripId: tripMorning.id,
        latitude: 5.607,
        longitude: -0.18,
      },
    ],
  });

  await prisma.attendance.upsert({
    where: {
      studentId_tripId: {
        studentId: studentOne.id,
        tripId: tripMorning.id,
      },
    },
    update: {
      status: AttendanceStatus.BOARDED,
      markedById: driverUser.id,
    },
    create: {
      studentId: studentOne.id,
      tripId: tripMorning.id,
      status: AttendanceStatus.BOARDED,
      markedById: driverUser.id,
    },
  });

  await prisma.attendance.upsert({
    where: {
      studentId_tripId: {
        studentId: studentThree.id,
        tripId: tripMorning.id,
      },
    },
    update: {
      status: AttendanceStatus.PRESENT,
      markedById: driverUser.id,
    },
    create: {
      studentId: studentThree.id,
      tripId: tripMorning.id,
      status: AttendanceStatus.PRESENT,
      markedById: driverUser.id,
    },
  });

  await prisma.attendance.upsert({
    where: {
      studentId_tripId: {
        studentId: studentFour.id,
        tripId: tripAfternoon.id,
      },
    },
    update: {
      status: AttendanceStatus.BOARDED,
      markedById: driverUser.id,
    },
    create: {
      studentId: studentFour.id,
      tripId: tripAfternoon.id,
      status: AttendanceStatus.BOARDED,
      markedById: driverUser.id,
    },
  });

  await prisma.attendance.upsert({
    where: {
      studentId_tripId: {
        studentId: studentTwo.id,
        tripId: tripMorning.id,
      },
    },
    update: {
      status: AttendanceStatus.PRESENT,
      markedById: driverUser.id,
    },
    create: {
      studentId: studentTwo.id,
      tripId: tripMorning.id,
      status: AttendanceStatus.PRESENT,
      markedById: driverUser.id,
    },
  });

  await prisma.attendance.upsert({
    where: {
      studentId_tripId: {
        studentId: studentOne.id,
        tripId: tripAfternoon.id,
      },
    },
    update: {
      status: AttendanceStatus.ABSENT,
      markedById: driverUser.id,
    },
    create: {
      studentId: studentOne.id,
      tripId: tripAfternoon.id,
      status: AttendanceStatus.ABSENT,
      markedById: driverUser.id,
    },
  });

  await prisma.notification.deleteMany({
    where: {
      OR: [
        { title: { startsWith: 'Demo:' } },
        { body: { startsWith: 'Demo:' } },
      ],
    },
  });

  await prisma.notification.createMany({
    data: [
      {
        title: 'Demo: Route Update',
        body: 'Demo: East Corridor trip is 8 minutes away from Main Gate.',
        targetRole: Role.PARENT,
      },
      {
        title: 'Demo: Driver Reminder',
        body: 'Demo: Afternoon dropoff starts at 3:00 PM.',
        targetRole: Role.DRIVER,
      },
      {
        title: 'Demo: Student Attendance',
        body: 'Demo: Student One marked absent for afternoon dropoff.',
        studentId: studentOne.id,
      },
      {
        title: 'Demo: Student Boarding',
        body: 'Demo: Student One boarded morning pickup.',
        studentId: studentOne.id,
      },
      {
        title: 'Demo: Student Present',
        body: 'Demo: Student Two marked present on morning trip.',
        studentId: studentTwo.id,
      },
      {
        title: 'Demo: Student Three Present',
        body: 'Demo: Student Three marked present on morning trip.',
        studentId: studentThree.id,
      },
      {
        title: 'Demo: Student Four Boarded',
        body: 'Demo: Student Four boarded afternoon dropoff.',
        studentId: studentFour.id,
      },
    ],
  });

  console.log('Seed completed', {
    adminId: admin.id,
    driverId: driver.id,
    tripIds: [tripMorning.id, tripAfternoon.id, tripTomorrow.id],
  });
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
