import { IsNotEmpty, IsString } from 'class-validator';

export class CompleteDriverOnboardingDto {
  @IsString()
  @IsNotEmpty()
  busNumber!: string;

  @IsString()
  @IsNotEmpty()
  routeName!: string;

  @IsString()
  @IsNotEmpty()
  emergencyContactName!: string;

  @IsString()
  @IsNotEmpty()
  emergencyContactPhone!: string;
}
