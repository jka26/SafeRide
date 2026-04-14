import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class CompleteParentOnboardingDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  childName!: string;

  @IsString()
  @IsNotEmpty()
  grade!: string;

  @IsString()
  @IsNotEmpty()
  stopName!: string;

  @IsString()
  @IsNotEmpty()
  emergencyContactName!: string;

  @IsString()
  @IsNotEmpty()
  emergencyContactPhone!: string;
}
