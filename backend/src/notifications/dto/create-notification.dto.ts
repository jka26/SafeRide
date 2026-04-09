import { IsEnum, IsOptional, IsString } from 'class-validator';
import { Role } from '@prisma/client';

export class CreateNotificationDto {
    @IsString()
    title: string;

    @IsString()
    body: string;

    @IsOptional()
    @IsString()
    studentId?: string;

    @IsOptional()
    @IsEnum(Role)
    targetRole?: Role;
}
