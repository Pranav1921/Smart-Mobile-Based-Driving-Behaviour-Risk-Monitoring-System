import { z } from 'zod';

export const updateProfileSchema = z.object({
  body: z.object({
    firstName: z.string().optional(),
    lastName: z.string().optional(),
    name: z.string().optional(),
    phoneNumber: z.string().optional(),
    email: z.string().email().optional(),
    zone: z.string().optional(),
    region: z.string().optional(),
    licenseNumber: z.string().optional(),
    licenseExpiry: z.string().optional(),
    emergencyContactName: z.string().optional(),
    emergencyContactPhone: z.string().optional(),
    status: z.string().optional(),
    driverType: z.enum(['TACTICAL', 'STANDARD']).optional(),
    vehicleName: z.string().optional(),
    vehiclePlate: z.string().optional(),
    vehicleType: z.string().optional(),
    safetyScore: z.number().optional(),
  }),
});

export const assignVehicleSchema = z.object({
  body: z.object({
    vehicleId: z
      .string()
      .uuid({ message: 'Target vehicle reference must be a valid UUID' }),
  }),
});
