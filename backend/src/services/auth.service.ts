import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { userRepository } from '../repositories/user.repository';
import { driverRepository } from '../repositories/driver.repository';
import { organizationRepository } from '../repositories/organization.repository';
import { Role, User } from '@prisma/client';
import {
  BadRequestError,
  UnauthorizedError,
  ConflictError,
} from '../utils/app-error';

const ACCESS_SECRET =
  process.env.JWT_ACCESS_SECRET ||
  'super-secret-access-key-fleetguard-ai-2026';
const REFRESH_SECRET =
  process.env.JWT_REFRESH_SECRET ||
  'super-secret-refresh-key-fleetguard-ai-2026';
const ACCESS_EXPIRY = process.env.JWT_ACCESS_EXPIRY || '15m';
const REFRESH_EXPIRY = process.env.JWT_REFRESH_EXPIRY || '7d';

export interface TokenPayload {
  userId: string;
  email: string;
  role: Role;
  organizationId: string | null;
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
    role: Role;
    organizationName?: string;
    organizationId?: string;
    licenseNumber?: string;
    licenseExpiry?: string | Date;
    emergencyContactName?: string;
    emergencyContactPhone?: string;
  }): Promise<{ user: User | null; accessToken: string; refreshToken: string }> {
    const existing = await userRepository.findByEmail(data.email);
    if (existing) {
      throw new ConflictError('Email is already registered');
    }

    const plainPassword = data.password || 'FleetGuard2026!';
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
      role: data.role,
      organization: orgId ? { connect: { id: orgId } } : undefined,
    });

    if (data.role === Role.DRIVER) {
      if (!data.licenseNumber || !data.licenseExpiry) {
        throw new BadRequestError(
          'License registration details are mandatory for driver profiles'
        );
      }

      await driverRepository.create({
        user: { connect: { id: user.id } },
        licenseNumber: data.licenseNumber,
        licenseExpiry: new Date(data.licenseExpiry),
        emergencyContactName: data.emergencyContactName || '',
        emergencyContactPhone: data.emergencyContactPhone || '',
        status: 'ACTIVE',
      });
    }

    const fullUser = await userRepository.findById(user.id);
    const tokens = this.generateTokens({
      userId: user.id,
      email: user.email,
      role: user.role,
      organizationId: user.organizationId,
    });

    return { user: fullUser, ...tokens };
  }

  async login(data: {
    email: string;
    password?: string;
  }): Promise<{ user: User; accessToken: string; refreshToken: string }> {
    const user = await userRepository.findByEmail(data.email);
    if (!user) {
      throw new UnauthorizedError('Invalid credentials');
    }

    const isMatch = await bcrypt.compare(
      data.password || '',
      user.passwordHash
    );
    if (!isMatch) {
      throw new UnauthorizedError('Invalid credentials');
    }

    const tokens = this.generateTokens({
      userId: user.id,
      email: user.email,
      role: user.role,
      organizationId: user.organizationId,
    });

    return { user, ...tokens };
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
      });
    } catch {
      throw new UnauthorizedError('Invalid refresh token');
    }
  }
}
export const authService = new AuthService();
