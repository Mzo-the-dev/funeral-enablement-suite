import { IsString, MaxLength, MinLength } from 'class-validator';

export class SocietyMembershipRequestDto {
  @IsString()
  @MinLength(1)
  @MaxLength(80)
  memberNumber!: string;
}