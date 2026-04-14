import { IsIn, IsNotEmpty, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export class ReportEmergencyDto {
  @IsString()
  @IsNotEmpty()
  @IsIn(['accident', 'medical', 'security', 'other'])
  type!: 'accident' | 'medical' | 'security' | 'other';

  @IsOptional()
  @IsString()
  tripId?: string;

  @IsOptional()
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude?: number;

  @IsOptional()
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude?: number;
}
