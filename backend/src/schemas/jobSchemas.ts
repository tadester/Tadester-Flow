import { z } from "zod";

export const createJobSchema = z.object({
  locationId: z.string().uuid(),
  title: z.string().trim().min(1),
  description: z.string().trim().optional(),
  status: z.enum(["draft", "scheduled", "in_progress", "completed", "cancelled"]),
  priority: z.enum(["low", "medium", "high", "urgent"]),
  scheduledStartAt: z.string().datetime(),
  scheduledEndAt: z.string().datetime(),
});

export const updateJobSchema = createJobSchema.partial().refine(
  (payload) => Object.keys(payload).length > 0,
  "At least one field is required.",
);

export const jobStatusSchema = z.object({
  status: z.enum(["draft", "scheduled", "in_progress", "completed", "cancelled"]),
});

export const workerJobActionSchema = z
  .object({
    action: z.enum(["start", "complete", "unable"]),
    notes: z.string().trim().max(1000).optional(),
    reason: z.string().trim().max(1000).optional(),
  })
  .superRefine((payload, context) => {
    if (payload.action === "unable" && !payload.reason) {
      context.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["reason"],
        message: "A reason is required when a job could not be completed.",
      });
    }
  });

export type CreateJobInput = z.infer<typeof createJobSchema>;
export type UpdateJobInput = z.infer<typeof updateJobSchema>;
export type JobStatusInput = z.infer<typeof jobStatusSchema>;
export type WorkerJobActionInput = z.infer<typeof workerJobActionSchema>;
