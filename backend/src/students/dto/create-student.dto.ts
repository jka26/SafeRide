import { IsOptional, IsString, MinLength } from 'class-validator';

export class CreateStudentDto {
  @IsString()
  @MinLength(2)
  studentCode!: string;

  @IsString()
  @MinLength(2)
  fullName!: string;

  @IsString()
  grade!: string;

  @IsOptional()
  @IsString()
  parentId?: string;

  @IsOptional()
  @IsString()
  routeName?: string;

  @IsOptional()
  @IsString()
  busLabel?: string;

  @IsOptional()
  @IsString()
  stopName?: string;

  @IsOptional()
  @IsString()
  dropOffTime?: string;

  @IsOptional()
  @IsString()
  emergencyContactName?: string;

  @IsOptional()
  @IsString()
  emergencyContactPhone?: string;
}
