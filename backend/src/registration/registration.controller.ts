import { Body, Controller, Get, Headers, Param, Post } from '@nestjs/common';

import { DatabaseService } from '../database/database.service';
import { LoginDto } from './dto/login.dto';
import { LogoutDto } from './dto/logout.dto';
import { RegisterDto } from './dto/register.dto';
import { SocietyMembershipRequestDto } from './dto/society-membership-request.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
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

  @Post('sessions')
  login(@Body() body: LoginDto): Promise<{ sessionToken: string; expiresAt: Date }> {
    return this.registrations.login(body);
  }

  @Post('sessions/logout')
  logout(@Body() body: LogoutDto): Promise<{ status: string }> {
    return this.registrations.logout(body.sessionToken);
  }

  @Get('users/me/profile')
  myProfile(@Headers('authorization') authorization?: string): Promise<Record<string, unknown>> {
    const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
    return this.registrations.getMyProfile(sessionToken);
  }

  @Post('users/me/profile')
  updateMyProfile(
    @Body() body: UpdateProfileDto,
    @Headers('authorization') authorization?: string,
  ): Promise<Record<string, unknown>> {
    const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
    return this.registrations.updateMyProfile(sessionToken, body);
  }

  @Get('spaces/types')
  spaceTypes(): Promise<{ code: string; display_name: string }[]> {
    return this.registrations.listSpaceTypes();
  }

  @Get('spaces/discoverable')
  discoverableSpaces(): Promise<{
    space_id: string;
    display_name: string;
    space_code: string;
    public_description: string | null;
  }[]> {
    return this.registrations.listDiscoverableSpaces();
  }

  @Get('spaces/mine')
  mySpaces(@Headers('authorization') authorization?: string): Promise<{
    space_id: string;
    display_name: string;
    society_name: string;
    space_code: string;
    role_code: string;
    member_number: string | null;
    joined_at: string | null;
    covered_life_count: number;
  }[]> {
    const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
    return this.registrations.listMySpaces(sessionToken);
  }

  @Get('spaces/:spaceId/dashboard')
  societyDashboard(
    @Param('spaceId') spaceId: string,
    @Headers('authorization') authorization?: string,
  ): Promise<Record<string, unknown>> {
    const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
    return this.registrations.getSocietyDashboard(spaceId, sessionToken);
  }

  @Post('spaces/:spaceId/join-requests')
  requestSocietyMembership(
    @Param('spaceId') spaceId: string,
    @Body() body: SocietyMembershipRequestDto,
    @Headers('authorization') authorization?: string,
  ): Promise<{ status: string }> {
    const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
    return this.registrations.submitSocietyMembershipRequest(spaceId, sessionToken, body.memberNumber);
  }

  @Post('spaces/:spaceId/membership-requests/:requestId/approve')
  approveMembershipRequest(
    @Param('spaceId') spaceId: string,
    @Param('requestId') requestId: string,
    @Headers('authorization') authorization?: string,
  ): Promise<{ status: string }> {
    const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
    return this.registrations.approveSocietyMembershipRequest(spaceId, requestId, sessionToken);
  }

  @Post('spaces/:spaceId/funeral-cases/:caseId/approve')
  approveFuneralCase(
    @Param('spaceId') spaceId: string,
    @Param('caseId') caseId: string,
    @Headers('authorization') authorization?: string,
  ): Promise<{ status: string }> {
    const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
    return this.registrations.approveFuneralCase(spaceId, caseId, sessionToken);
  }
}
