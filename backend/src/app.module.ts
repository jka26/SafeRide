import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { CommonModule } from './common/common.module';
import { DatabaseModule } from './database/database.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { StudentsModule } from './students/students.module';
import { BusesModule } from './buses/buses.module';
import { TripsModule } from './trips/trips.module';
import { AttendanceModule } from './attendance/attendance.module';
import { NotificationsModule } from './notifications/notifications.module';
import { CsvImportModule } from './csv-import/csv-import.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { RoutesModule } from './routes/routes.module';
import { ParentsModule } from './parents/parents.module';
import { OnboardingModule } from './onboarding/onboarding.module';
import { DriversModule } from './drivers/drivers.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    CommonModule,
    DatabaseModule,
    AuthModule,
    UsersModule,
    StudentsModule,
    BusesModule,
    TripsModule,
    AttendanceModule,
    NotificationsModule,
    CsvImportModule,
    DashboardModule,
    RoutesModule,
    ParentsModule,
    OnboardingModule,
    DriversModule,
  ],
  controllers: [AppController],
  providers: [],
})
export class AppModule {}
