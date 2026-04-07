import { AppRole } from '../../common/auth/roles.enum';
export declare class SignUpDto {
    email: string;
    password: string;
    fullName: string;
    role: AppRole;
}
