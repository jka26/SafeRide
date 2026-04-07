import { PrismaService } from '../database/prisma.service';
import { SignUpDto } from './dto/sign-up.dto';
import { LoginDto } from './dto/login.dto';
export declare class AuthService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    signUp(dto: SignUpDto): Promise<{
        email: string;
        fullName: string;
        role: import("@prisma/client").$Enums.Role;
        id: string;
    }>;
    login(dto: LoginDto): Promise<{
        token: `${string}-${string}-${string}-${string}-${string}`;
        expiresAt: Date;
        user: {
            id: string;
            email: string;
            role: import("@prisma/client").$Enums.Role;
            fullName: string;
        };
    }>;
}
