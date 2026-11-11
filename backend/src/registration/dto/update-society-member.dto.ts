import { IsDateString, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class UpdateSocietyMemberDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(80)
  memberNumber?: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  givenName?: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  surname?: string;

  @IsOptional()
  @IsDateString()
  joinedAt?: string;
}