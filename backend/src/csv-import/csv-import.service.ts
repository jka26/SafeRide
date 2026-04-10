import { Injectable } from '@nestjs/common';
import { parse } from 'csv-parse/sync';
import { PrismaService } from '../database/prisma.service';
import { ImportStudentsCsvDto } from './dto/import-students-csv.dto';
import { Prisma } from '@prisma/client';

type ParsedStudentRow = {
  studentCode: string;
  fullName: string;
  grade: string;
  routeName: string | null;
  busLabel: string | null;
  stopName: string | null;
  dropOffTime: string | null;
  emergencyContactName: string | null;
  emergencyContactPhone: string | null;
};

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
      routeName: row.routeName,
      busLabel: row.busLabel,
      stopName: row.stopName,
      dropOffTime: row.dropOffTime,
      emergencyContactName: row.emergencyContactName,
      emergencyContactPhone: row.emergencyContactPhone,
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

  private normalizeHeaderKey(key: string) {
    return key.trim().toLowerCase().replace(/[\s_-]+/g, '');
  }

  private normalizedRecord(record: Record<string, string>) {
    const out: Record<string, string> = {};
    for (const [k, v] of Object.entries(record)) {
      out[this.normalizeHeaderKey(k)] = (v ?? '').trim();
    }
    return out;
  }

  private firstNorm(
    norm: Record<string, string>,
    keys: string[],
  ): string | null {
    for (const key of keys) {
      const v = norm[this.normalizeHeaderKey(key)];
      if (v) {
        return v;
      }
    }
    return null;
  }

  private parseRows(csvText: string): ParsedStudentRow[] {
    const records = parse(csvText, {
      columns: true,
      skip_empty_lines: true,
      trim: true,
    }) as Record<string, string>[];

    return records
      .map((record) => {
        const n = this.normalizedRecord(record);
        const studentCode =
          this.firstNorm(n, ['studentcode', 'code', 'studentid']) ?? '';
        const fullName =
          this.firstNorm(n, ['fullname', 'name', 'studentname']) ?? '';
        const grade = this.firstNorm(n, ['grade', 'class', 'year']) ?? '';
        const routeName =
          this.firstNorm(n, ['route', 'routename', 'route_name']) ?? null;
        const busLabel =
          this.firstNorm(n, [
            'bus',
            'buslabel',
            'platenumber',
            'plate',
            'busnumber',
          ]) ?? null;
        const stopName =
          this.firstNorm(n, ['stop', 'stopname', 'busstop']) ?? null;
        const dropOffTime =
          this.firstNorm(n, [
            'dropofftime',
            'dropoff',
            'drop_off_time',
            'pmtime',
          ]) ?? null;
        const emergencyContactName =
          this.firstNorm(n, [
            'emergencycontactname',
            'emergencyname',
            'contactname',
            'guardianname',
          ]) ?? null;
        const emergencyContactPhone =
          this.firstNorm(n, [
            'emergencycontactphone',
            'emergencyphone',
            'contactphone',
            'guardianphone',
          ]) ?? null;

        return {
          studentCode,
          fullName,
          grade,
          routeName,
          busLabel,
          stopName,
          dropOffTime,
          emergencyContactName,
          emergencyContactPhone,
        };
      })
      .filter(
        (row) =>
          row.studentCode.trim() && row.fullName.trim() && row.grade.trim(),
      );
  }
}
