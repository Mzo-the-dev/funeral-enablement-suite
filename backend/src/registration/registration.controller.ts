import { Body, Controller, Get, Headers, Param, Post } from '@nestjs/common';

import { DatabaseService } from '../database/database.service';
import { LoginDto } from './dto/login.dto';
import { LogoutDto } from './dto/logout.dto';
import { RegisterDto } from './dto/register.dto';
import { CreateCoveredLifeDto } from './dto/create-covered-life.dto';
import { CreateFuneralCaseDto } from './dto/create-funeral-case.dto';
import { CreateSocietyMemberDto } from './dto/create-society-member.dto';
import { SocietyMembershipRequestDto } from './dto/society-membership-request.dto';
import { UpdateCoveredLifeDto } from './dto/update-covered-life.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UpdateSocietyMemberDto } from './dto/update-society-member.dto';
import { PlatformAdminLinkDto } from './dto/platform-admin-link.dto';
import { PlatformAdminLinkPreviewDto } from './dto/platform-admin-link-preview.dto';
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

  @Post('platform-admin/member-link-preview')
  previewPlatformAdminMemberLink(
    @Body() body: PlatformAdminLinkPreviewDto,
    @Headers('authorization') authorization?: string,
  ): Promise<Record<string, unknown>> {
    const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
    return this.registrations.previewPlatformAdminMemberLink(sessionToken, body);
  }

  @Post('platform-admin/member-links')
  repairPlatformAdminMemberLink(
    @Body() body: PlatformAdminLinkDto,
    @Headers('authorization') authorization?: string,
  ): Promise<Record<string, unknown>> {
    const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
    return this.registrations.repairPlatformAdminMemberLink(sessionToken, body);
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

  @Get('spaces/:spaceId/members')
  activeSocietyMembers(
    @Param('spaceId') spaceId: string,
    @Headers('authorization') authorization?: string,
  ): Promise<Record<string, unknown>[]> {
    const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
    return this.registrations.listActiveSocietyMembers(spaceId, sessionToken);
  }

  @Get('spaces/:spaceId/covered-lives')
  myCoveredLives(
    @Param('spaceId') spaceId: string,
    @Headers('authorization') authorization?: string,
  ): Promise<Record<string, unknown>> {
    const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
    return this.registrations.getMyCoveredLives(spaceId, sessionToken);
  }

  @Post('spaces/:spaceId/covered-lives')
  createMyCoveredLife(
    @Param('spaceId') spaceId: string,
    @Body() body: CreateCoveredLifeDto,
    @Headers('authorization') authorization?: string,
  ): Promise<Record<string, unknown>> {
    const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
    return this.registrations.createCoveredLife(spaceId, undefined, sessionToken, body);
  }

  @Get('spaces/:spaceId/members/:memberId')
    societyMember(
      @Param('spaceId') spaceId: string,
      @Param('memberId') memberId: string,
      @Headers('authorization') authorization?: string,
    ): Promise<Record<string, unknown>> {
      const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
      return this.registrations.getSocietyMember(spaceId, memberId, sessionToken);
    }

    @Get('spaces/:spaceId/members/:memberId/history')
    societyMemberHistory(
      @Param('spaceId') spaceId: string,
      @Param('memberId') memberId: string,
      @Headers('authorization') authorization?: string,
    ): Promise<Record<string, unknown>[]> {
      const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
      return this.registrations.getSocietyMemberHistory(spaceId, memberId, sessionToken);
    }

    @Post('spaces/:spaceId/members')
    createSocietyMember(
      @Param('spaceId') spaceId: string,
      @Body() body: CreateSocietyMemberDto,
      @Headers('authorization') authorization?: string,
    ): Promise<Record<string, unknown>> {
      const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
      return this.registrations.createSocietyMember(spaceId, sessionToken, body);
    }

    @Post('spaces/:spaceId/members/:memberId/update')
    updateSocietyMember(
      @Param('spaceId') spaceId: string,
      @Param('memberId') memberId: string,
      @Body() body: UpdateSocietyMemberDto,
      @Headers('authorization') authorization?: string,
    ): Promise<Record<string, unknown>> {
      const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
      return this.registrations.updateSocietyMember(spaceId, memberId, sessionToken, body);
    }

    @Post('spaces/:spaceId/members/:memberId/deactivate')
    deactivateSocietyMember(
      @Param('spaceId') spaceId: string,
      @Param('memberId') memberId: string,
      @Headers('authorization') authorization?: string,
    ): Promise<{ status: string }> {
      const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
      return this.registrations.deactivateSocietyMember(spaceId, memberId, sessionToken);
    }

    @Post('spaces/:spaceId/members/:memberId/covered-lives')
    createCoveredLife(
      @Param('spaceId') spaceId: string,
      @Param('memberId') memberId: string,
      @Body() body: CreateCoveredLifeDto,
      @Headers('authorization') authorization?: string,
    ): Promise<Record<string, unknown>> {
      const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
      return this.registrations.createCoveredLife(spaceId, memberId, sessionToken, body);
    }

    @Post('spaces/:spaceId/members/:memberId/covered-lives/:coveredLifeId/update')
    updateCoveredLife(
      @Param('spaceId') spaceId: string,
      @Param('memberId') memberId: string,
      @Param('coveredLifeId') coveredLifeId: string,
      @Body() body: UpdateCoveredLifeDto,
      @Headers('authorization') authorization?: string,
    ): Promise<Record<string, unknown>> {
      const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
      return this.registrations.updateCoveredLife(spaceId, memberId, coveredLifeId, sessionToken, body);
    }

    @Post('spaces/:spaceId/members/:memberId/covered-lives/:coveredLifeId/deactivate')
    deactivateCoveredLife(
      @Param('spaceId') spaceId: string,
      @Param('memberId') memberId: string,
      @Param('coveredLifeId') coveredLifeId: string,
      @Headers('authorization') authorization?: string,
    ): Promise<{ status: string }> {
      const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
      return this.registrations.deactivateCoveredLife(spaceId, memberId, coveredLifeId, sessionToken);
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

  @Post('spaces/:spaceId/funeral-cases/:caseId/complete-payout')
  completeFuneralCasePayout(
    @Param('spaceId') spaceId: string,
    @Param('caseId') caseId: string,
    @Headers('authorization') authorization?: string,
  ): Promise<{ status: string }> {
    const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
    return this.registrations.completeFuneralCasePayout(spaceId, caseId, sessionToken);
  }

  @Post('spaces/:spaceId/funeral-cases')
  registerFuneralCase(
    @Param('spaceId') spaceId: string,
    @Body() body: CreateFuneralCaseDto,
    @Headers('authorization') authorization?: string,
  ): Promise<Record<string, unknown>> {
    const sessionToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
    return this.registrations.registerFuneralCase(spaceId, sessionToken, body);
  }
}
