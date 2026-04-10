import { Body, Controller, Get, Param, Patch } from '@nestjs/common';
import { UsersService } from './users.service';
import { Roles } from '../common/auth/roles.decorator';
import { AppRole } from '../common/auth/roles.enum';
import { CurrentUser } from '../common/auth/current-user.decorator';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  profile(@CurrentUser() user: AuthenticatedUser) {
    return user;
  }

  @Patch('me')
  updateProfile(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateProfileDto,
  ) {
    return this.usersService.updateProfile(user, dto);
  }

  @Get()
  @Roles(AppRole.ADMIN)
  list() {
    return this.usersService.listForAdmin();
  }

  @Get(':id')
  @Roles(AppRole.ADMIN)
  findOne(@Param('id') id: string) {
    return this.usersService.findOneForAdmin(id);
  }
}
