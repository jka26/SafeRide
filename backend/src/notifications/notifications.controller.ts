import {
    Body,
    Controller,
    Delete,
    Get,
    Param,
    Patch,
    Post,
} from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { CreateNotificationDto } from './dto/create-notification.dto';
import { Roles } from '../common/auth/roles.decorator';
import { AppRole } from '../common/auth/roles.enum';
import { CurrentUser } from '../common/auth/current-user.decorator';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';

@Controller('notifications')
export class NotificationsController {
    constructor(private readonly notificationsService: NotificationsService) { }

    /**
     * POST /api/notifications
     * Create a notification (ADMIN only).
     */
    @Post()
    @Roles(AppRole.ADMIN)
    create(
        @Body() dto: CreateNotificationDto,
        @CurrentUser() user: AuthenticatedUser,
    ) {
        return this.notificationsService.create(dto, user);
    }

    /**
     * GET /api/notifications
     * Fetch notifications visible to the current user (role-filtered).
     */
    @Get()
    findAll(@CurrentUser() user: AuthenticatedUser) {
        return this.notificationsService.findForUser(user);
    }

    /**
     * PATCH /api/notifications/:id/read
     * Mark a notification as read.
     */
    @Patch(':id/read')
    markRead(@Param('id') id: string, @CurrentUser() user: AuthenticatedUser) {
        return this.notificationsService.markRead(id, user);
    }

    /**
     * DELETE /api/notifications/:id
     * Delete a notification (ADMIN only).
     */
    @Delete(':id')
    @Roles(AppRole.ADMIN)
    remove(@Param('id') id: string, @CurrentUser() user: AuthenticatedUser) {
        return this.notificationsService.remove(id, user);
    }
}
