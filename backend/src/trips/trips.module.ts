import { Module } from '@nestjs/common';
import { TripsController } from './trips.controller';
import { TripsService } from './trips.service';
import { DatabaseModule } from '../database/database.module';
import { TripActionsService } from './trip-actions.service';
import { DriverTripsController } from './driver-trips.controller';
import { ParentTrackingController } from './parent-tracking.controller';
import { TrackingGateway } from './tracking.gateway';

@Module({
  imports: [DatabaseModule],
  controllers: [
    TripsController,
    DriverTripsController,
    ParentTrackingController,
  ],
  providers: [TripsService, TripActionsService, TrackingGateway],
})
export class TripsModule {}
