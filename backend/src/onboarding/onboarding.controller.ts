import { Body, Controller, Post } from '@nestjs/common';
import { Roles } from '../common/auth/roles.decorator';
import { AppRole } from '../common/auth/roles.enum';
import { CurrentUser } from '../common/auth/current-user.decorator';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';
import { OnboardingService } from './onboarding.service';
import { CompleteParentOnboardingDto } from './dto/complete-parent-onboarding.dto';
import { CompleteDriverOnboardingDto } from './dto/complete-driver-onboarding.dto';

@Controller('onboarding')
export class OnboardingController {
  constructor(private readonly onboardingService: OnboardingService) {}

  @Post('parent')
  @Roles(AppRole.PARENT)
  completeParent(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CompleteParentOnboardingDto,
  ) {
    return this.onboardingService.completeParent(user, dto);
  }

  @Post('driver')
  @Roles(AppRole.DRIVER)
  completeDriver(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CompleteDriverOnboardingDto,
  ) {
    return this.onboardingService.completeDriver(user, dto);
  }
}
