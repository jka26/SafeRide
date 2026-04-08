import { Injectable } from '@nestjs/common';
import { parse } from 'csv-parse/sync';
import { PrismaService } from '../database/prisma.service';
import { ImportStudentsCsvDto } from './dto/import-students-csv.dto';
import { Prisma } from '@prisma/client';

@Injectable()
export class CsvImportService {
  constructor(private readonly prisma: PrismaService) {}

  previewStudentsCsv(dto: ImportStudentsCsvDto) {
    const rows = this.parseRows(dto.csvText);
    return {
      totalRows: rows.length,
      rows,
    };
  }

  async commitStudentsCsv(dto: ImportStudentsCsvDto) {
    const rows = this.parseRows(dto.csvText);
    if (!rows.length) {
      return { inserted: 0, skipped: 0 };
    }

    const data: Prisma.StudentCreateManyInput[] = rows.map((row) => ({
      studentCode: row.studentCode,
      fullName: row.fullName,
      grade: row.grade,
    }));

    const result = await this.prisma.student.createMany({
      data,
      skipDuplicates: true,
    });

    return {
      inserted: result.count,
      skipped: rows.length - result.count,
    };
  }

  private parseRows(csvText: string) {
    const records = parse(csvText, {
      columns: true,
      skip_empty_lines: true,
      trim: true,
    }) as Record<string, string>[];

    return records
      .map((record) => ({
        studentCode: record.studentCode ?? '',
        fullName: record.fullName ?? '',
        grade: record.grade ?? '',
      }))
      .filter(
        (row) =>
          row.studentCode.trim() && row.fullName.trim() && row.grade.trim(),
      );
  }
}
