import { Body, Controller, Post } from '@nestjs/common';
import { CsvImportService } from './csv-import.service';
import { Roles } from '../common/auth/roles.decorator';
import { AppRole } from '../common/auth/roles.enum';
import { ImportStudentsCsvDto } from './dto/import-students-csv.dto';

@Controller('csv-import')
@Roles(AppRole.ADMIN)
export class CsvImportController {
  constructor(private readonly csvImportService: CsvImportService) {}

  @Post('students/preview')
  preview(@Body() dto: ImportStudentsCsvDto) {
    return this.csvImportService.previewStudentsCsv(dto);
  }

  @Post('students/commit')
  commit(@Body() dto: ImportStudentsCsvDto) {
    return this.csvImportService.commitStudentsCsv(dto);
  }
}
