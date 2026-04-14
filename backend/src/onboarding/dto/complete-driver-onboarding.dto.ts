import { IsNotEmpty, IsString } from 'class-validator';

/** Bus/route come from admin-assigned trips; drivers only confirm safety contact. */
export class CompleteDriverOnboardingDto {
  @IsString()
  @IsNotEmpty()
  emergencyContactName!: string;

  @IsString()
  @IsNotEmpty()
  emergencyContactPhone!: string;
}
