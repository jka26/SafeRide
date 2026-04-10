import { Controller, Delete, Get, Param, Post } from '@nestjs/common';
import { ParentsService } from './parents.service';
import { Roles } from '../common/auth/roles.decorator';
import { AppRole } from '../common/auth/roles.enum';
import { CurrentUser } from '../common/auth/current-user.decorator';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';

@Controller('parents')
@Roles(AppRole.PARENT)
export class ParentsController {
  constructor(private readonly parentsService: ParentsService) {}

  @Get('me')
  me(@CurrentUser() user: AuthenticatedUser) {
    return this.parentsService.getMe(user);
  }

  @Post('me/students/:studentId')
  linkStudent(
    @Param('studentId') studentId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.parentsService.linkStudent(user, studentId);
  }

  @Delete('me/students/:studentId')
  unlinkStudent(
    @Param('studentId') studentId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.parentsService.unlinkStudent(user, studentId);
  }
}
