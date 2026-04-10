-- AlterEnum
ALTER TYPE "AttendanceStatus" ADD VALUE 'BOARDED';
ALTER TYPE "AttendanceStatus" ADD VALUE 'ALIGHTED';

-- AlterTable
ALTER TABLE "Student" ADD COLUMN "routeName" TEXT;
ALTER TABLE "Student" ADD COLUMN "busLabel" TEXT;
ALTER TABLE "Student" ADD COLUMN "stopName" TEXT;
ALTER TABLE "Student" ADD COLUMN "dropOffTime" TEXT;
ALTER TABLE "Student" ADD COLUMN "emergencyContactName" TEXT;
ALTER TABLE "Student" ADD COLUMN "emergencyContactPhone" TEXT;
