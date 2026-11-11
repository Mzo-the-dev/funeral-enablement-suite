import { IsString, MaxLength, MinLength } from 'class-validator';

import { PlatformAdminLinkPreviewDto } from './platform-admin-link-preview.dto';

export class PlatformAdminLinkDto extends PlatformAdminLinkPreviewDto {
  @IsString()
  @MinLength(10)
  @MaxLength(500)
  reason!: string;
}