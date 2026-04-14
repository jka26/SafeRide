import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { TripActionsService } from './trip-actions.service';
import { Roles } from '../common/auth/roles.decorator';
import { AppRole } from '../common/auth/roles.enum';
import { CurrentUser } from '../common/auth/current-user.decorator';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';
import { ReportLocationDto } from './dto/report-location.dto';
import { UpdateTripProgressDto } from './dto/update-trip-progress.dto';

@Controller('driver/trips')
@Roles(AppRole.DRIVER, AppRole.ADMIN)
export class DriverTripsController {
  constructor(private readonly tripActions: TripActionsService) {}

  @Post(':tripId/start')
  start(
    @Param('tripId') tripId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.tripActions.startTrip(tripId, user);
  }

  @Post(':tripId/end')
  end(
    @Param('tripId') tripId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.tripActions.endTrip(tripId, user);
  }

  @Post(':tripId/location')
  location(
    @Param('tripId') tripId: string,
    @Body() dto: ReportLocationDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.tripActions.reportLocation(
      tripId,
      user,
      dto.latitude,
      dto.longitude,
    );
  }

  @Patch(':tripId/progress')
  progress(
    @Param('tripId') tripId: string,
    @Body() dto: UpdateTripProgressDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.tripActions.updateProgress(tripId, user, dto);
  }

  @Get(':tripId/live')
  live(
    @Param('tripId') tripId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.tripActions.getLiveForOperations(tripId, user);
  }
}
