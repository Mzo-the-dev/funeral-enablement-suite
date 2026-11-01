import { Body, Controller, Get, Post } from '@nestjs/common';

import { DatabaseService } from '../database/database.service';
import { RegisterDto } from './dto/register.dto';
import { VerifyRegistrationDto } from './dto/verify-registration.dto';
import { RegistrationService } from './registration.service';

@Controller()
export class RegistrationController {
  constructor(
    private readonly database: DatabaseService,
    private readonly registrations: RegistrationService,
  ) {}

  @Get('health')
  async health(): Promise<{ status: string; database: string }> {
    await this.database.query('SELECT 1');
    return { status: 'ok', database: 'connected' };
  }

  @Post('registrations')
  register(@Body() body: RegisterDto): Promise<Record<string, unknown>> {
    return this.registrations.register(body);
  }

  @Post('registrations/verify')
  verify(@Body() body: VerifyRegistrationDto): Promise<{ status: string; message: string }> {
    return this.registrations.verify(body);
  }
}
