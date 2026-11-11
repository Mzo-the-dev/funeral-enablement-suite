import { IsDateString, IsString, MaxLength, MinLength } from 'class-validator';

export class CreateSocietyMemberDto {
  @IsString()
  @MinLength(1)
  @MaxLength(80)
  memberNumber!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(120)
  givenName!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(120)
  surname!: string;

  @IsDateString()
  joinedAt!: string;
}