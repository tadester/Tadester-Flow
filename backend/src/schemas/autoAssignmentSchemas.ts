import { z } from "zod";

export const autoAssignJobsSchema = z.object({
  jobId: z.string().uuid().optional(),
});

export type AutoAssignJobsInput = z.infer<typeof autoAssignJobsSchema>;
