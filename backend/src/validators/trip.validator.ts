import { z } from 'zod';

export const startTripSchema = z.object({
  body: z.object({
    vehicleId: z
      .string()
      .uuid({ message: 'Target vehicle reference must be a valid UUID' }),
  }),
});

export const locationUpdateSchema = z.object({
  body: z.object({
    latitude: z
      .number()
      .min(-90, { message: 'Latitude bound error (-90 to 90)' })
      .max(90),
    longitude: z
      .number()
      .min(-180, { message: 'Longitude bound error (-180 to 180)' })
      .max(180),
    speed: z
      .number()
      .min(0, { message: 'Velocity speed index must be non-negative' }),
    heading: z
      .number()
      .min(0, { message: 'Heading tracking angle must fall inside (0-360)' })
      .max(360),
    altitude: z.number().optional(),
    timestamp: z.string().optional(),
  }),
});
