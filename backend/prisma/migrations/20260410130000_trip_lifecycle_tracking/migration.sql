-- CreateEnum
CREATE TYPE "TripStatus" AS ENUM ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');

-- AlterTable
ALTER TABLE "Trip" ADD COLUMN "status" "TripStatus" NOT NULL DEFAULT 'SCHEDULED';
ALTER TABLE "Trip" ADD COLUMN "startedAt" TIMESTAMP(3);
ALTER TABLE "Trip" ADD COLUMN "endedAt" TIMESTAMP(3);
ALTER TABLE "Trip" ADD COLUMN "currentStopName" TEXT;
ALTER TABLE "Trip" ADD COLUMN "etaMinutes" INTEGER;

-- CreateTable
CREATE TABLE "TripLocation" (
    "id" TEXT NOT NULL,
    "tripId" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "recordedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TripLocation_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Trip_status_idx" ON "Trip"("status");
CREATE INDEX "TripLocation_tripId_recordedAt_idx" ON "TripLocation"("tripId", "recordedAt");

-- AddForeignKey
ALTER TABLE "TripLocation" ADD CONSTRAINT "TripLocation_tripId_fkey" FOREIGN KEY ("tripId") REFERENCES "Trip"("id") ON DELETE CASCADE ON UPDATE CASCADE;
