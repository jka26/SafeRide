import { Controller, Get } from '@nestjs/common';
import { DashboardService } from './dashboard.service';
import { Roles } from '../common/auth/roles.decorator';
import { AppRole } from '../common/auth/roles.enum';
import { CurrentUser } from '../common/auth/current-user.decorator';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';

@Controller('dashboard')
export class DashboardController {
    constructor(private readonly dashboardService: DashboardService) { }

    /**
     * GET /api/dashboard/admin
     * System-wide operational summary (student/bus/trip/driver counts, today's trips, attendance).
     * Role: ADMIN
     */
    @Get('admin')
    @Roles(AppRole.ADMIN)
    adminSummary() {
        return this.dashboardService.getAdminSummary();
    }

    /**
     * GET /api/dashboard/driver
     * Today's assigned trips with full passenger roster + upcoming 7-day view.
     * Role: DRIVER
     */
    @Get('driver')
    @Roles(AppRole.DRIVER)
    driverDashboard(@CurrentUser() user: AuthenticatedUser) {
        return this.dashboardService.getDriverDashboard(user);
    }

    /**
     * GET /api/dashboard/parent
     * All children with attendance summaries and latest trip status.
     * Role: PARENT
     */
    @Get('parent')
    @Roles(AppRole.PARENT)
    parentDashboard(@CurrentUser() user: AuthenticatedUser) {
        return this.dashboardService.getParentDashboard(user);
    }
}
