import { AppRole } from './roles.enum';

export type AuthenticatedUser = {
  id: string;
  email: string;
  role: AppRole;
  fullName: string;
  onboardingCompleted?: boolean;
};
