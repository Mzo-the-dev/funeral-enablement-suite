import { IsDateString, IsIn, IsInt, IsOptional, IsString, Matches, Max, MaxLength, Min, MinLength } from 'class-validator';

export class CreateCoveredLifeDto {
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  personNumber?: number;

  @IsString()
  @MinLength(1)
  @MaxLength(160)
  displayName!: string;

  @IsOptional()
  @IsString()
  @MinLength(6)
  @MaxLength(32)
  @Matches(/^[a-zA-Z0-9 -]+$/)
  identityNumber?: string;

  @IsIn(['member', 'spouse', 'dependent'])
  relationshipCode!: string;

  @IsDateString()
  effectiveFrom!: string;

  @IsOptional()
  @IsDateString()
  effectiveTo?: string;
}