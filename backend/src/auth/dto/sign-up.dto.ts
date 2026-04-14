import { IsEmail, IsIn, IsString, MinLength } from 'class-validator';
import { AppRole } from '../../common/auth/roles.enum';

export class SignUpDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(8)
  password!: string;

  @IsString()
  @MinLength(2)
  fullName!: string;

  @IsIn([AppRole.PARENT, AppRole.DRIVER])
  role!: AppRole.PARENT | AppRole.DRIVER;
}
