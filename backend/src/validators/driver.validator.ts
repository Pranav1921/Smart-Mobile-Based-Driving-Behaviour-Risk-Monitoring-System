import { z } from 'zod';

export const updateProfileSchema = z.object({
  body: z.object({
    licenseNumber: z.string().optional(),
    licenseExpiry: z.string().optional(),
    emergencyContactName: z.string().optional(),
    emergencyContactPhone: z.string().optional(),
    status: z.enum(['ACTIVE', 'INACTIVE', 'ON_TRIP']).optional(),
  }),
});

export const assignVehicleSchema = z.object({
  body: z.object({
    vehicleId: z
      .string()
      .uuid({ message: 'Target vehicle reference must be a valid UUID' }),
  }),
});
