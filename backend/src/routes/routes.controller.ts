import { Controller, Get } from '@nestjs/common';
import { RoutesService } from './routes.service';
import { Roles } from '../common/auth/roles.decorator';
import { AppRole } from '../common/auth/roles.enum';

@Controller('routes')
@Roles(AppRole.ADMIN, AppRole.DRIVER, AppRole.PARENT)
export class RoutesController {
  constructor(private readonly routesService: RoutesService) {}

  @Get()
  list() {
    return this.routesService.listSummaries();
  }
}
