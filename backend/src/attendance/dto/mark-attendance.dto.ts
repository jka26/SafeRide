import { IsEnum, IsString } from 'class-validator';
import { AttendanceStatus } from '@prisma/client';

export class MarkAttendanceDto {
  @IsString()
  studentId: string;

  @IsString()
  tripId: string;

  @IsEnum(AttendanceStatus)
  status: AttendanceStatus;
}
