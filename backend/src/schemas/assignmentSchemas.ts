import { z } from "zod";

export const createAssignmentSchema = z.object({
  jobId: z.string().uuid(),
  workerProfileId: z.string().uuid(),
  assignmentStatus: z
    .enum(["assigned", "accepted", "rejected", "unassigned", "completed"])
    .default("assigned"),
});

export type CreateAssignmentInput = z.infer<typeof createAssignmentSchema>;
