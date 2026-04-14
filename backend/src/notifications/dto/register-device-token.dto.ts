import { IsIn, IsNotEmpty, IsString, MinLength } from 'class-validator';

export class RegisterDeviceTokenDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(16)
  token!: string;

  @IsString()
  @IsIn(['android', 'ios', 'web', 'unknown'])
  platform!: string;
}
