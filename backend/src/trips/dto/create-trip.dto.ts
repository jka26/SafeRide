import { IsDateString, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateTripDto {
  @IsString()
  @MinLength(2)
  name!: string;

  @IsString()
  busId!: string;

  @IsOptional()
  @IsString()
  driverId?: string;

  @IsDateString()
  tripDate!: string;
}
