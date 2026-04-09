import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { AttendanceService } from './attendance.service';
import { MarkAttendanceDto } from './dto/mark-attendance.dto';
import { Roles } from '../common/auth/roles.decorator';
import { AppRole } from '../common/auth/roles.enum';
import { CurrentUser } from '../common/auth/current-user.decorator';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';

@Controller('attendance')
export class AttendanceController {
    constructor(private readonly attendanceService: AttendanceService) { }

    /**
     * POST /api/attendance
     * Mark a student present or absent on a trip.
     * Allowed: ADMIN, DRIVER (must be assigned to the trip).
     */
    @Post()
    @Roles(AppRole.ADMIN, AppRole.DRIVER)
    mark(
        @Body() dto: MarkAttendanceDto,
        @CurrentUser() user: AuthenticatedUser,
    ) {
        return this.attendanceService.markAttendance(dto, user);
    }

    /**
     * GET /api/attendance/trip/:tripId
     * Retrieve all attendance records for a specific trip.
     * Allowed: ADMIN, DRIVER (must be assigned to the trip).
     */
    @Get('trip/:tripId')
    @Roles(AppRole.ADMIN, AppRole.DRIVER)
    getByTrip(
        @Param('tripId') tripId: string,
        @CurrentUser() user: AuthenticatedUser,
    ) {
        return this.attendanceService.getAttendanceByTrip(tripId, user);
    }

    /**
     * GET /api/attendance/student/:studentId
     * Retrieve all attendance history for a student.
     * Allowed: ADMIN, the student's own PARENT.
     */
    @Get('student/:studentId')
    @Roles(AppRole.ADMIN, AppRole.PARENT)
    getByStudent(
        @Param('studentId') studentId: string,
        @CurrentUser() user: AuthenticatedUser,
    ) {
        return this.attendanceService.getAttendanceByStudent(studentId, user);
    }
}
