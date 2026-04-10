import { PartialType } from '@nestjs/mapped-types';
import {
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';
import { TripStatus } from '@prisma/client';
import { CreateTripDto } from './create-trip.dto';

export class UpdateTripDto extends PartialType(CreateTripDto) {
  @IsOptional()
  @IsEnum(TripStatus)
  status?: TripStatus;

  @IsOptional()
  @IsString()
  currentStopName?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(24 * 60)
  etaMinutes?: number;

  @IsOptional()
  @IsDateString()
  startedAt?: string;

  @IsOptional()
  @IsDateString()
  endedAt?: string;
}
