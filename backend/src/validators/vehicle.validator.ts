import { z } from 'zod';
import { VehicleType, MaintenanceStatus } from '@prisma/client';

export const createVehicleSchema = z.object({
  body: z.object({
    make: z.string().min(1, { message: 'Make description is required' }),
    model: z.string().min(1, { message: 'Model description is required' }),
    year: z
      .number()
      .int()
      .min(1900)
      .max(new Date().getFullYear() + 2),
    vehicleType: z.nativeEnum(VehicleType, {
      message: 'Invalid vehicle classification type',
    }),
    licensePlate: z
      .string()
      .min(1, { message: 'License plate identifier is required' }),
    insuranceNumber: z
      .string()
      .min(1, { message: 'Insurance number field is required' }),
    insuranceExpiry: z
      .string()
      .min(1, { message: 'Insurance expiration date is required' }),
    registrationNumber: z
      .string()
      .min(1, { message: 'Registration certificate index is required' }),
  }),
});

export const updateVehicleSchema = z.object({
  body: z.object({
    make: z.string().optional(),
    model: z.string().optional(),
    year: z.number().int().optional(),
    vehicleType: z.nativeEnum(VehicleType).optional(),
    licensePlate: z.string().optional(),
    insuranceNumber: z.string().optional(),
    insuranceExpiry: z.string().optional(),
    registrationNumber: z.string().optional(),
    maintenanceStatus: z.nativeEnum(MaintenanceStatus).optional(),
  }),
});
