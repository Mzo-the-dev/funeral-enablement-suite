import { IsDateString, IsIn, IsOptional, IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class UpdateCoveredLifeDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(160)
  displayName?: string;

  @IsOptional()
  @IsString()
  @MinLength(6)
  @MaxLength(32)
  @Matches(/^[a-zA-Z0-9 -]+$/)
  identityNumber?: string | null;

  @IsOptional()
  @IsIn(['member', 'spouse', 'dependent'])
  relationshipCode?: string;

  @IsOptional()
  @IsDateString()
  effectiveFrom?: string;

  @IsOptional()
  @IsDateString()
  effectiveTo?: string | null;
}