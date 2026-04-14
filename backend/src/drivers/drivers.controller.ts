import { Controller, Get } from '@nestjs/common';
import { DriversService } from './drivers.service';
import { Roles } from '../common/auth/roles.decorator';
import { AppRole } from '../common/auth/roles.enum';

@Controller('drivers')
@Roles(AppRole.ADMIN)
export class DriversController {
  constructor(private readonly driversService: DriversService) {}

  @Get()
  list() {
    return this.driversService.listForAdmin();
  }
}
