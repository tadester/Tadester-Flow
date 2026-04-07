import { z } from "zod";

export const createLocationSchema = z.object({
  name: z.string().trim().min(1),
  addressLine1: z.string().trim().min(1),
  addressLine2: z.string().trim().optional(),
  city: z.string().trim().min(1),
  region: z.string().trim().min(1),
  postalCode: z.string().trim().min(1),
  country: z.string().trim().min(1),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  geofenceRadiusMeters: z.number().int().positive(),
  status: z.enum(["active", "inactive"]).default("active"),
});

export type CreateLocationInput = z.infer<typeof createLocationSchema>;
