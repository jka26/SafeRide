import { Controller, Get } from '@nestjs/common';
import { Public } from './common/auth/public.decorator';

@Controller()
export class AppController {
  @Get()
  @Public()
  getHealth() {
    return {
      service: 'saferide-backend',
      status: 'ok',
      message: 'SafeRide backend API is running',
    };
  }
}
