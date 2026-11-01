import {
  IsEmail,
  IsIn,
  IsObject,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

export class RegisterDto {
  @IsString()
  @MinLength(3)
  @MaxLength(80)
  @Matches(/^[a-zA-Z0-9._-]+$/, { message: 'Username may contain letters, numbers, dots, underscores, and hyphens.' })
  username!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(120)
  givenName!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(120)
  surname!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(120)
  preferredName!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(120)
  location!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(200)
  address!: string;

  @IsEmail()
  @MaxLength(254)
  email!: string;

  @IsString()
  @MinLength(9)
  @MaxLength(20)
  phone!: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password!: string;

  @IsIn(['society', 'parlour', 'family', 'supplier'])
  spaceCode!: string;

  @IsIn(['email', 'sms'])
  verificationChannel!: 'email' | 'sms';

  @IsObject()
  answers!: Record<string, unknown>;
}
