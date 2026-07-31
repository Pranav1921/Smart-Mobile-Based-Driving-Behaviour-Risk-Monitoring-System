import { z } from 'zod';
import { EventType } from '@prisma/client';

export const logEventSchema = z.object({
  body: z.object({
    tripId: z.string().uuid().optional(),
    eventType: z.nativeEnum(EventType, {
      message: 'Invalid incident action classification',
    }),
    latitude: z
      .number()
      .min(-90, { message: 'Latitude bound error (-90 to 90)' })
      .max(90),
    longitude: z
      .number()
      .min(-180, { message: 'Longitude bound error (-180 to 180)' })
      .max(180),
    sensorValues: z.any().optional(),
    timestamp: z.string().optional(),
  }),
});
