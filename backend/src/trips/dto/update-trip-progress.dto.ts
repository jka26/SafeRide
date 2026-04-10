import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class UpdateTripProgressDto {
  @IsOptional()
  @IsString()
  currentStopName?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(24 * 60)
  etaMinutes?: number;
}
