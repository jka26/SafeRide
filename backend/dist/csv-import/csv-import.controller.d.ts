import { CsvImportService } from './csv-import.service';
import { ImportStudentsCsvDto } from './dto/import-students-csv.dto';
export declare class CsvImportController {
    private readonly csvImportService;
    constructor(csvImportService: CsvImportService);
    preview(dto: ImportStudentsCsvDto): {
        totalRows: number;
        rows: {
            studentCode: string;
            fullName: string;
            grade: string;
        }[];
    };
    commit(dto: ImportStudentsCsvDto): Promise<{
        inserted: number;
        skipped: number;
    }>;
}
