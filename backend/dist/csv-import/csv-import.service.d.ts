import { PrismaService } from '../database/prisma.service';
import { ImportStudentsCsvDto } from './dto/import-students-csv.dto';
export declare class CsvImportService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    previewStudentsCsv(dto: ImportStudentsCsvDto): {
        totalRows: number;
        rows: {
            studentCode: string;
            fullName: string;
            grade: string;
        }[];
    };
    commitStudentsCsv(dto: ImportStudentsCsvDto): Promise<{
        inserted: number;
        skipped: number;
    }>;
    private parseRows;
}
