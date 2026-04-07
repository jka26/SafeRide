import { IsInt, IsString, Min, MinLength } from 'class-validator';

export class CreateBusDto {
  @IsString()
  @MinLength(3)
  plateNumber!: string;

  @IsInt()
  @Min(1)
  capacity!: number;

  @IsString()
  @MinLength(2)
  routeName!: string;
}
