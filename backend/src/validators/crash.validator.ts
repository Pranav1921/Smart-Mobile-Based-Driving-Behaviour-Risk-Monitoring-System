import { z } from 'zod';
import { Severity, EmergencyStatus } from '@prisma/client';

export const reportCrashSchema = z.object({
  body: z.object({
    tripId: z.string().uuid().optional(),
    vehicleId: z
      .string()
      .uuid({ message: 'Target vehicle reference must be a valid UUID' }),
    latitude: z
      .number()
      .min(-90, { message: 'Latitude bound error (-90 to 90)' })
      .max(90),
    longitude: z
      .number()
      .min(-180, { message: 'Longitude bound error (-180 to 180)' })
      .max(180),
    sensorValues: z.object({
      accel_x: z.number(),
      accel_y: z.number(),
      accel_z: z.number(),
      gyro_x: z.number().optional(),
      gyro_y: z.number().optional(),
      gyro_z: z.number().optional(),
    }),
    severity: z.nativeEnum(Severity, {
      message: 'Invalid severity configuration level',
    }),
    timestamp: z.string().optional(),
  }),
});

export const updateCrashStatusSchema = z.object({
  body: z.object({
    status: z.nativeEnum(EmergencyStatus, {
      message: 'Invalid dispatch emergency state status value',
    }),
  }),
});
