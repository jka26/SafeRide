"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UpdateBusDto = void 0;
const mapped_types_1 = require("@nestjs/mapped-types");
const create_bus_dto_1 = require("./create-bus.dto");
class UpdateBusDto extends (0, mapped_types_1.PartialType)(create_bus_dto_1.CreateBusDto) {
}
exports.UpdateBusDto = UpdateBusDto;
//# sourceMappingURL=update-bus.dto.js.map