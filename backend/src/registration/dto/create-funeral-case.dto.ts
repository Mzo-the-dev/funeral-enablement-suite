import {
  IsBoolean,
  IsDateString,
  IsIn,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

export class CreateFuneralCaseDto {
  @IsString()
  @IsOptional()
  @MaxLength(160)
  givenName?: string;

  @IsString()
  @IsOptional()
  @MaxLength(160)
  surname?: string;

  @IsString()
  @IsOptional()
  @MinLength(6)
  @MaxLength(32)
  @Matches(/^[a-zA-Z0-9 -]+$/)
  deceasedIdNumber?: string;

  @IsDateString()
  dateOfDeath!: string;

  @IsBoolean()
  useExistingBankDetails!: boolean;

  @IsString()
  @IsOptional()
  @IsIn([
    'Absa', 'African Bank', 'Bank Zero', 'Bidvest Bank', 'Capitec Bank',
    'Discovery Bank', 'FNB', 'Grindrod Bank', 'Investec', 'Nedbank',
    'Standard Bank', 'TymeBank', 'Ubank',
  ])
  bankName?: string;

  @IsString()
  @IsOptional()
  @MaxLength(160)
  accountName?: string;

  @IsString()
  @IsOptional()
  @MinLength(4)
  @MaxLength(34)
  @Matches(/^[0-9]+$/)
  accountNumber?: string;
}