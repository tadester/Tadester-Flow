import { z } from "zod";

export const trackingPingSchema = z
  .object({
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
    accuracy: z.number().min(0).optional(),
    accuracy_meters: z.number().min(0).optional(),
    timestamp: z.string().datetime(),
  })
  .superRefine((value, context) => {
    if (
      typeof value.accuracy === "undefined" &&
      typeof value.accuracy_meters === "undefined"
    ) {
      context.addIssue({
        code: z.ZodIssueCode.custom,
        message: "accuracy is required.",
        path: ["accuracy"],
      });
    }
  })
  .transform((value) => ({
    latitude: value.latitude,
    longitude: value.longitude,
    accuracy: value.accuracy ?? value.accuracy_meters ?? 0,
    timestamp: value.timestamp,
  }));

export type TrackingPingInput = z.infer<typeof trackingPingSchema>;
