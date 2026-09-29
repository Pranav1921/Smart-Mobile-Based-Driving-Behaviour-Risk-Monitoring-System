import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { userRepository } from '../repositories/user.repository';
import { driverRepository } from '../repositories/driver.repository';
import { organizationRepository } from '../repositories/organization.repository';
import { Role, User, DriverType } from '@prisma/client';
import { logger } from '../config/logger';
import {
  BadRequestError,
  UnauthorizedError,
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from '../utils/app-error';

const ACCESS_SECRET =
  process.env.JWT_ACCESS_SECRET ||
  'super-secret-access-key-smartdrive-ai-2026';
const REFRESH_SECRET =
  process.env.JWT_REFRESH_SECRET ||
  'super-secret-refresh-key-smartdrive-ai-2026';
const ACCESS_EXPIRY = process.env.JWT_ACCESS_EXPIRY || '15m';
const REFRESH_EXPIRY = process.env.JWT_REFRESH_EXPIRY || '7d';

export interface TokenPayload {
  userId: string;
  email: string;
  role: Role;
  organizationId: string | null;
  zone: string | null;
}

export class AuthService {
  generateTokens(payload: TokenPayload) {
    const accessToken = jwt.sign({ ...payload }, ACCESS_SECRET, {
      expiresIn: ACCESS_EXPIRY as any,
    });
    const refreshToken = jwt.sign({ ...payload }, REFRESH_SECRET, {
      expiresIn: REFRESH_EXPIRY as any,
    });
    return { accessToken, refreshToken };
  }

  async register(data: {
    email: string;
    password?: string;
    firstName: string;
    lastName: string;
    role?: Role;
    organizationId?: string;
    organizationName?: string;
    phone?: string;
    phoneNumber?: string;
    zone?: string;
    licenseNumber?: string;
    licenseExpiry?: string | Date;
    emergencyContactName?: string;
    emergencyContactPhone?: string;
    driverType?: string;
  }): Promise<{ user: User | null; accessToken: string; refreshToken: string }> {
    const existing = await userRepository.findByEmail(data.email);
    if (existing) {
      throw new ConflictError('Email is already registered');
    }

    const plainPassword = data.password || 'SmartDrive2026!';
    const passwordHash = await bcrypt.hash(plainPassword, 10);

    let orgId = data.organizationId || null;

    if (!orgId && data.organizationName) {
      const org = await organizationRepository.create(data.organizationName);
      orgId = org.id;
    }

    if (data.role !== Role.SUPER_ADMIN && !orgId) {
      throw new BadRequestError('Organization mapping is required for this role');
    }

    const user = await userRepository.create({
      email: data.email,
      passwordHash,
      firstName: data.firstName,
      lastName: data.lastName,
      phoneNumber: data.phoneNumber || data.phone || null,
      role: data.role,
      zone: data.zone || 'puttur_taluk',
      organization: orgId ? { connect: { id: orgId } } : undefined,
    });

    if (data.role === Role.DRIVER) {
      if (!data.licenseNumber || !data.licenseExpiry) {
        throw new BadRequestError(
          'License registration details are mandatory for driver profiles'
        );
      }

      const newDriver = await driverRepository.create({
        user: { connect: { id: user.id } },
        licenseNumber: data.licenseNumber,
        licenseExpiry: new Date(data.licenseExpiry),
        emergencyContactName: data.emergencyContactName || '',
        emergencyContactPhone: data.emergencyContactPhone || '',
        status: 'PENDING_APPROVAL',
        driverType: (data.driverType as any) || 'TACTICAL',
      });

      try {
        const { socketManager } = await import('../sockets/socket.manager');
        const fullName = `${data.firstName || ''} ${data.lastName || ''}`.trim() || 'New Driver';
        socketManager.emitToDashboards('new_driver_request', {
          id: newDriver.id,
          driverId: newDriver.id,
          name: fullName,
          email: data.email,
          phoneNumber: data.phoneNumber || data.phone || '',
          zone: data.zone || 'puttur_taluk',
          licenseNumber: data.licenseNumber,
          createdAt: new Date().toISOString(),
          status: 'PENDING_APPROVAL',
          user: {
            id: user.id,
            email: user.email,
            firstName: data.firstName,
            lastName: data.lastName,
            phoneNumber: data.phoneNumber || data.phone,
            zone: data.zone || 'puttur_taluk',
          },
        });
      } catch (_) {}
    }

    const fullUser = await userRepository.findById(user.id);
    const tokens = this.generateTokens({
      userId: user.id,
      email: user.email,
      role: user.role,
      organizationId: user.organizationId,
      zone: (user as any).zone,
    });

    return { user: fullUser, ...tokens };
  }

  async applyDriver(data: {
    name: string;
    email: string;
    phoneNumber?: string;
    regionId?: string;
    zone?: string;
    licenseNumber: string;
    vehicleType?: string;
    vehicleName?: string;
    vehiclePlateNumber?: string;
    vehiclePlate?: string;
    emergencyName?: string;
    emergencyPhone?: string;
    emergencyContactName?: string;
    emergencyContactPhone?: string;
    familyRelationship?: string;
  }) {
    const existing = await userRepository.findByEmail(data.email);

    // Name splitting
    const parts = (data.name || 'Driver Candidate').trim().split(' ');
    const firstName = parts[0];
    const lastName = parts.slice(1).join(' ') || '';

    const region = (data.zone || data.regionId || 'Karnataka, Dakshina Kannada, Puttur').trim();
    const applicationId = `REQ-2026-${Math.floor(1000 + Math.random() * 9000)}`;

    const vehicleType = data.vehicleType || 'Scooter';
    const vehicleName = data.vehicleName || 'Tata Ace Gold EV';
    const vehiclePlateNumber = (data.vehiclePlateNumber || data.vehiclePlate || 'KA-19-PT-2026').toUpperCase();

    const applicationBadges = [
      'must_change_password',
      `application_id:${applicationId}`,
      `applied_vehicle:${vehicleType}`,
      `applied_vehicle_name:${vehicleName}`,
      `applied_vehicle_plate:${vehiclePlateNumber}`,
      `emergency_relation:${data.familyRelationship || 'Parent'}`,
    ];

    let user: any;
    let driver: any;

    if (existing) {
      const existingDriver = await driverRepository.findByUserId(existing.id);
      if (existingDriver) {
        if (existingDriver.status === 'ACTIVE' || existingDriver.status === 'active') {
          throw new ConflictError('An active driver profile already exists with this email address.');
        }
        // Update pending application with latest details
        driver = await driverRepository.update(existingDriver.id, {
          licenseNumber: data.licenseNumber,
          emergencyContactName: data.emergencyContactName || data.emergencyName || 'Family / Parent',
          emergencyContactPhone: data.emergencyContactPhone || data.emergencyPhone || '',
          status: 'PENDING_APPROVAL',
          driverType: DriverType.TACTICAL,
          badges: applicationBadges,
        });
        user = await userRepository.update(existing.id, {
          firstName,
          lastName,
          phoneNumber: data.phoneNumber || existing.phoneNumber,
          zone: region,
        });
      } else {
        // Orphaned user account without driver record (recovers from previous error)
        user = await userRepository.update(existing.id, {
          firstName,
          lastName,
          phoneNumber: data.phoneNumber || existing.phoneNumber,
          zone: region,
        });
        driver = await driverRepository.create({
          user: { connect: { id: user.id } },
          licenseNumber: data.licenseNumber,
          licenseExpiry: new Date(Date.now() + 1000 * 60 * 60 * 24 * 365 * 5),
          emergencyContactName: data.emergencyContactName || data.emergencyName || 'Family / Parent',
          emergencyContactPhone: data.emergencyContactPhone || data.emergencyPhone || '',
          status: 'PENDING_APPROVAL',
          driverType: DriverType.TACTICAL,
          badges: applicationBadges,
        });
      }
    } else {
      // Placeholder password hash until admin approves
      const tempInitialPass = `Pending#${Math.floor(1000 + Math.random() * 9000)}`;
      const passwordHash = await bcrypt.hash(tempInitialPass, 10);

      user = await userRepository.create({
        email: data.email,
        passwordHash,
        firstName,
        lastName,
        phoneNumber: data.phoneNumber || '',
        role: Role.DRIVER,
        zone: region,
      });

      driver = await driverRepository.create({
        user: { connect: { id: user.id } },
        licenseNumber: data.licenseNumber,
        licenseExpiry: new Date(Date.now() + 1000 * 60 * 60 * 24 * 365 * 5),
        emergencyContactName: data.emergencyContactName || data.emergencyName || 'Family / Parent',
        emergencyContactPhone: data.emergencyContactPhone || data.emergencyPhone || '',
        status: 'PENDING_APPROVAL',
        driverType: DriverType.TACTICAL,
        badges: applicationBadges,
      });
    }

    // Notify all connected admin dashboards in real time
    try {
      const { socketManager } = await import('../sockets/socket.manager');
      const fullName = `${firstName} ${lastName}`.trim();
      const payload = {
        id: driver.id,
        driverId: driver.id,
        applicationId,
        trackingId: applicationId,
        name: fullName,
        email: data.email,
        phoneNumber: data.phoneNumber || '',
        zone: region,
        region,
        licenseNumber: data.licenseNumber,
        vehicleType,
        vehicleName,
        vehiclePlateNumber,
        emergencyContactName: data.emergencyContactName || data.emergencyName || '',
        emergencyContactPhone: data.emergencyContactPhone || data.emergencyPhone || '',
        familyRelationship: data.familyRelationship || 'Parent',
        createdAt: new Date().toISOString(),
        status: 'PENDING_APPROVAL',
        user: {
          id: user.id,
          email: user.email,
          firstName,
          lastName,
          phoneNumber: user.phoneNumber,
          zone: user.zone,
        },
      };
      socketManager.emitToDashboards('new_driver_request', payload);
      logger.info(`[ONBOARDING REQUEST] Real-time alert dispatched for ${fullName} (${data.email}) in ${region}`);
    } catch (socketErr) {
      logger.error(`Failed to dispatch real-time request event: ${socketErr}`);
    }

    return {
      status: 'PENDING_APPROVAL',
      applicationId,
      trackingId: applicationId,
      message: 'Application submitted successfully. Awaiting verification by Regional Command Center.',
      driverId: driver.id,
      region,
      zone: region,
      email: data.email,
      vehicleType,
      vehicleName,
      vehiclePlateNumber,
    };
  }

  async login(data: {
    email?: string;
    driverId?: string;
    password?: string;
  }): Promise<{ user: User; accessToken: string; refreshToken: string; mustChangePassword: boolean; status: string; zone: string; driverCode?: string }> {
    const identifier = (data.email || data.driverId || '').trim();
    if (!identifier) {
      throw new BadRequestError('Driver ID or Email is required');
    }

    const user = await userRepository.findByIdentifier(identifier);
    if (!user) {
      throw new UnauthorizedError('Invalid credentials or Driver ID not recognized');
    }

    const isMatch = await bcrypt.compare(
      data.password || '',
      user.passwordHash
    );
    if (!isMatch) {
      throw new UnauthorizedError('Invalid credentials');
    }

    const driverProfile = (user as any).driverProfile;
    const status = driverProfile?.status || 'ACTIVE';

    if (status === 'PENDING_APPROVAL') {
      throw new ForbiddenError('Your driver application is currently PENDING REGIONAL ADMIN APPROVAL. Credentials will be activated once verified on Parivahan.');
    }
    if (status === 'REJECTED') {
      throw new ForbiddenError('Your driver registration application was not approved by the regional administrator.');
    }

    // Check if initial password change is mandatory
    const badges: string[] = driverProfile?.badges || [];
    const mustChangePassword = badges.includes('must_change_password');
    const driverCodeBadge = badges.find(b => b.startsWith('driver_code:'));
    const driverCode = driverCodeBadge ? driverCodeBadge.replace('driver_code:', '') : (user as any).id.slice(0, 8).toUpperCase();

    const tokens = this.generateTokens({
      userId: user.id,
      email: user.email,
      role: user.role,
      organizationId: user.organizationId,
      zone: (user as any).zone,
    });

    return {
      user,
      ...tokens,
      mustChangePassword,
      status,
      zone: (user as any).zone || 'puttur_taluk',
      driverCode,
    };
  }

  async changeInitialPassword(data: {
    identifier?: string;
    driverId?: string;
    email?: string;
    currentPassword?: string;
    newPassword: string;
  }) {
    const rawId = (data.identifier || data.driverId || data.email || '').trim();
    if (!rawId) {
      throw new BadRequestError('User identifier (Driver ID or Email) is required');
    }
    const user = await userRepository.findByIdentifier(rawId);
    if (!user) {
      throw new NotFoundError('User account not found');
    }

    // If current password provided, verify it (flexible comparison)
    if (data.currentPassword) {
      const matchExact = await bcrypt.compare(data.currentPassword, user.passwordHash);
      const matchTrimmed = await bcrypt.compare(data.currentPassword.trim(), user.passwordHash);
      if (!matchExact && !matchTrimmed) {
        throw new UnauthorizedError('Current password is not correct');
      }
    }

    if (!data.newPassword || data.newPassword.trim().length < 6) {
      throw new BadRequestError('New password must be at least 6 characters');
    }

    const newHash = await bcrypt.hash(data.newPassword.trim(), 10);
    await userRepository.update(user.id, { passwordHash: newHash });

    // Remove must_change_password flag from driver badges
    const driver = (user as any).driverProfile || (await driverRepository.findByUserId(user.id));
    if (driver) {
      const cleanBadges = (driver.badges || []).filter((b: string) => b !== 'must_change_password');
      await driverRepository.update(driver.id, { badges: cleanBadges });
    }

    const tokens = this.generateTokens({
      userId: user.id,
      email: user.email,
      role: user.role,
      organizationId: user.organizationId,
      zone: (user as any).zone,
    });

    return {
      success: true,
      status: 'success',
      message: 'Permanent password updated successfully. Welcome to the Smart Driving System!',
      ...tokens,
    };
  }

  async refreshToken(
    token: string
  ): Promise<{ accessToken: string; refreshToken: string }> {
    try {
      const decoded = jwt.verify(token, REFRESH_SECRET) as TokenPayload;
      const user = await userRepository.findById(decoded.userId);
      if (!user) {
        throw new UnauthorizedError('User account not found');
      }

      return this.generateTokens({
        userId: user.id,
        email: user.email,
        role: user.role,
        organizationId: user.organizationId,
        zone: (user as any).zone,
      });
    } catch {
      throw new UnauthorizedError('Invalid refresh token');
    }
  }

  async getApplicationStatus(query: {
    email?: string;
    trackingId?: string;
    licenseNumber?: string;
  }) {
    const email = (query.email || '').trim().toLowerCase();
    const trackingId = (query.trackingId || '').trim();
    const licenseNumber = (query.licenseNumber || '').trim().toUpperCase();

    let user: any = null;

    if (email) {
      user = await userRepository.findByEmail(email);
    }

    if (!user && (trackingId || licenseNumber)) {
      // Find by driver license or tracking ID in badges
      const drivers = await driverRepository.findMany({
        take: 50,
      });
      const match = drivers.find((d: any) => {
        if (licenseNumber && d.licenseNumber?.toUpperCase() === licenseNumber) return true;
        if (trackingId && (d.badges || []).some((b: string) => b.includes(trackingId))) return true;
        return false;
      });
      if (match) {
        user = match.user;
      }
    }

    if (!user) {
      return {
        found: false,
        isApproved: false,
        status: 'NOT_FOUND',
        message: 'No application found for the provided details',
      };
    }

    const driver = user.driverProfile || (await driverRepository.findByUserId(user.id));
    const status = driver?.status || 'PENDING_APPROVAL';

    const badges: string[] = driver?.badges || [];
    const driverCodeBadge = badges.find((b: string) => b.startsWith('driver_code:'));
    const isVerifiedByAdmin = badges.includes('parivahan_verified') || !!driverCodeBadge;

    // Strictly approved ONLY if active AND explicitly verified/approved by admin
    const isApproved = (status === 'ACTIVE' || status === 'active') && isVerifiedByAdmin;

    if (trackingId && driver && !isApproved) {
      const hasTracking = badges.some((b: string) => b.includes(trackingId)) || driver.id === trackingId;
      if (!hasTracking) {
        return {
          found: true,
          isApproved: false,
          status: 'PENDING_APPROVAL',
          email: user.email,
          name: `${user.firstName || ''} ${user.lastName || ''}`.trim() || user.name || 'Driver',
          zone: user.zone,
          message: 'Application is currently queued and awaiting Regional Admin review.',
        };
      }
    }

    const driverCode = driverCodeBadge 
      ? driverCodeBadge.replace('driver_code:', '') 
      : (isApproved ? (driver?.licenseNumber || user.id) : undefined);

    return {
      found: true,
      isApproved,
      status,
      email: user.email,
      name: `${user.firstName || ''} ${user.lastName || ''}`.trim() || user.name || 'Driver',
      driverCode: isApproved ? driverCode : undefined,
      zone: user.zone,
      message: isApproved
        ? 'Application approved by Regional Command Center! Credentials dispatched to your email.'
        : status === 'REJECTED'
        ? 'Application was rejected by Regional Command Center.'
        : 'Application is currently queued and awaiting Regional Admin review.',
    };
  }

  async updateUserProfile(
    userId: string,
    data: { firstName?: string; lastName?: string }
  ): Promise<User> {
    const user = await userRepository.findById(userId);
    if (!user) {
      throw new UnauthorizedError('User account not found');
    }

    const payload: any = {};
    if (data.firstName) payload.firstName = data.firstName;
    if (data.lastName) payload.lastName = data.lastName;

    return userRepository.update(userId, payload);
  }
}
export const authService = new AuthService();
