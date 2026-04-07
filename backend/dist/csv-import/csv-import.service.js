"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.CsvImportService = void 0;
const common_1 = require("@nestjs/common");
const sync_1 = require("csv-parse/sync");
const prisma_service_1 = require("../database/prisma.service");
let CsvImportService = class CsvImportService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    previewStudentsCsv(dto) {
        const rows = this.parseRows(dto.csvText);
        return {
            totalRows: rows.length,
            rows,
        };
    }
    async commitStudentsCsv(dto) {
        const rows = this.parseRows(dto.csvText);
        if (!rows.length) {
            return { inserted: 0, skipped: 0 };
        }
        const data = rows.map((row) => ({
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
    parseRows(csvText) {
        const records = (0, sync_1.parse)(csvText, {
            columns: true,
            skip_empty_lines: true,
            trim: true,
        });
        return records
            .map((record) => ({
            studentCode: record.studentCode ?? '',
            fullName: record.fullName ?? '',
            grade: record.grade ?? '',
        }))
            .filter((row) => row.studentCode.trim() && row.fullName.trim() && row.grade.trim());
    }
};
exports.CsvImportService = CsvImportService;
exports.CsvImportService = CsvImportService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], CsvImportService);
//# sourceMappingURL=csv-import.service.js.map