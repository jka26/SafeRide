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
exports.BusesController = void 0;
const common_1 = require("@nestjs/common");
const buses_service_1 = require("./buses.service");
const roles_decorator_1 = require("../common/auth/roles.decorator");
const roles_enum_1 = require("../common/auth/roles.enum");
const create_bus_dto_1 = require("./dto/create-bus.dto");
const update_bus_dto_1 = require("./dto/update-bus.dto");
let BusesController = class BusesController {
    busesService;
    constructor(busesService) {
        this.busesService = busesService;
    }
    create(dto) {
        return this.busesService.create(dto);
    }
    findAll() {
        return this.busesService.findAll();
    }
    findOne(id) {
        return this.busesService.findOne(id);
    }
    update(id, dto) {
        return this.busesService.update(id, dto);
    }
    remove(id) {
        return this.busesService.remove(id);
    }
};
exports.BusesController = BusesController;
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_bus_dto_1.CreateBusDto]),
    __metadata("design:returntype", void 0)
], BusesController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BusesController.prototype, "findAll", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BusesController.prototype, "findOne", null);
__decorate([
    (0, common_1.Patch)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, update_bus_dto_1.UpdateBusDto]),
    __metadata("design:returntype", void 0)
], BusesController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BusesController.prototype, "remove", null);
exports.BusesController = BusesController = __decorate([
    (0, common_1.Controller)('buses'),
    (0, roles_decorator_1.Roles)(roles_enum_1.AppRole.ADMIN),
    __metadata("design:paramtypes", [buses_service_1.BusesService])
], BusesController);
//# sourceMappingURL=buses.controller.js.map