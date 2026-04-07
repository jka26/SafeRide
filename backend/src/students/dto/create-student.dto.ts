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
}
