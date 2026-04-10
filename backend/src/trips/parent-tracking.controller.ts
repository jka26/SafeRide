import { Controller, Get, Param } from '@nestjs/common';
import { TripActionsService } from './trip-actions.service';
import { Roles } from '../common/auth/roles.decorator';
import { AppRole } from '../common/auth/roles.enum';
import { CurrentUser } from '../common/auth/current-user.decorator';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';

@Controller('parent/tracking')
@Roles(AppRole.PARENT)
export class ParentTrackingController {
  constructor(private readonly tripActions: TripActionsService) {}

  @Get('trips/:tripId')
  live(
    @Param('tripId') tripId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.tripActions.getLiveForParent(tripId, user);
  }
}
