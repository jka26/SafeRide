import { IsInt, IsOptional, IsString, Max, Min, MinLength } from 'class-validator';

export class ImportStudentsCsvDto {
  @IsString()
  @MinLength(5)
  csvText!: string;

  @IsOptional()
  @IsInt()
  @Min(10)
  @Max(500)
  previewLimit?: number;
}
