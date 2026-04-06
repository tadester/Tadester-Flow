import { z } from "zod";

export const trackingPingSchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  accuracy_meters: z.number().min(0),
  timestamp: z.string().datetime(),
});

export type TrackingPingInput = z.infer<typeof trackingPingSchema>;
