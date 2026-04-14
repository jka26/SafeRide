-- Add backend-tracked onboarding status
ALTER TABLE "User"
ADD COLUMN "onboardingCompleted" BOOLEAN NOT NULL DEFAULT false;

-- Preserve access for existing users by treating historical accounts as onboarded.
UPDATE "User"
SET "onboardingCompleted" = true;
