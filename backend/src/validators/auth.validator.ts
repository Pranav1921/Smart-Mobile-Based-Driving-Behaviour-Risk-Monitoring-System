import { z } from 'zod';
import { Role } from '@prisma/client';

export const registerSchema = z.object({
  body: z.object({
    email: z.string().email({ message: 'Invalid email address syntax' }),
    password: z
      .string()
      .min(6, { message: 'Password must consist of at least 6 characters' }),
    firstName: z.string().min(1, { message: 'First name is required' }),
    lastName: z.string().min(1, { message: 'Last name is required' }),
    role: z.nativeEnum(Role, { message: 'Invalid role assignment' }),
    organizationName: z.string().optional(),
    organizationId: z.string().uuid().optional(),
    licenseNumber: z.string().optional(),
    licenseExpiry: z.string().optional(),
    emergencyContactName: z.string().optional(),
    emergencyContactPhone: z.string().optional(),
  }),
});

export const loginSchema = z.object({
  body: z.object({
    email: z.string().optional(),
    driverId: z.string().optional(),
    password: z.string().min(1, { message: 'Password field cannot be empty' }),
  }),
});

export const refreshSchema = z.object({
  body: z.object({
    refreshToken: z
      .string()
      .min(1, { message: 'Refresh token field cannot be empty' }),
  }),
});
