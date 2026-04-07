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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.CsvImportController = void 0;
const common_1 = require("@nestjs/common");
const csv_import_service_1 = require("./csv-import.service");
const roles_decorator_1 = require("../common/auth/roles.decorator");
const roles_enum_1 = require("../common/auth/roles.enum");
const import_students_csv_dto_1 = require("./dto/import-students-csv.dto");
let CsvImportController = class CsvImportController {
    csvImportService;
    constructor(csvImportService) {
        this.csvImportService = csvImportService;
    }
    preview(dto) {
        return this.csvImportService.previewStudentsCsv(dto);
    }
    commit(dto) {
        return this.csvImportService.commitStudentsCsv(dto);
    }
};
exports.CsvImportController = CsvImportController;
__decorate([
    (0, common_1.Post)('students/preview'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [import_students_csv_dto_1.ImportStudentsCsvDto]),
    __metadata("design:returntype", void 0)
], CsvImportController.prototype, "preview", null);
__decorate([
    (0, common_1.Post)('students/commit'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [import_students_csv_dto_1.ImportStudentsCsvDto]),
    __metadata("design:returntype", void 0)
], CsvImportController.prototype, "commit", null);
exports.CsvImportController = CsvImportController = __decorate([
    (0, common_1.Controller)('csv-import'),
    (0, roles_decorator_1.Roles)(roles_enum_1.AppRole.ADMIN),
    __metadata("design:paramtypes", [csv_import_service_1.CsvImportService])
], CsvImportController);
//# sourceMappingURL=csv-import.controller.js.map