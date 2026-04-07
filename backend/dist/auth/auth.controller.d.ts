import { AuthService } from './auth.service';
import { SignUpDto } from './dto/sign-up.dto';
import { LoginDto } from './dto/login.dto';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
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
    me(user: AuthenticatedUser): AuthenticatedUser;
}
