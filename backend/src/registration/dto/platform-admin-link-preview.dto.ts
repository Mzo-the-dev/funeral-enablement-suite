import { IsString, MaxLength, MinLength } from 'class-validator';

export class PlatformAdminLinkPreviewDto {
  @IsString()
  @MinLength(3)
  @MaxLength(254)
  identity!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(80)
  societyCode!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(80)
  memberNumber!: string;
}