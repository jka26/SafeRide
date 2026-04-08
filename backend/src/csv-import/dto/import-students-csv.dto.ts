import { IsString, MinLength } from 'class-validator';

export class ImportStudentsCsvDto {
  @IsString()
  @MinLength(5)
  csvText!: string;
}
