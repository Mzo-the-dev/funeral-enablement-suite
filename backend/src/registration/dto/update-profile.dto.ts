import { IsBase64, IsBoolean, IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  preferredName?: string;

  @IsOptional()
  @IsString()
  @IsBase64()
  @MaxLength(699052)
  avatarBase64?: string;

  @IsOptional()
  @IsIn(['image/png', 'image/jpeg', 'image/webp'])
  avatarMimeType?: string;

  @IsOptional()
  @IsBoolean()
  clearAvatar?: boolean;
}