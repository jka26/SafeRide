import { IsLatitude, IsLongitude } from 'class-validator';

export class ReportLocationDto {
  @IsLatitude()
  latitude!: number;

  @IsLongitude()
  longitude!: number;
}
