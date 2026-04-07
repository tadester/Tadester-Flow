import { logger } from "./logger";

export function enqueueBackgroundTask(
  taskName: string,
  task: () => Promise<void>,
): void {
  setImmediate(() => {
    task().catch((error: unknown) => {
      const message = error instanceof Error ? error.message : "Unknown background task error.";
      logger.error(`${taskName} failed: ${message}`);
    });
  });
}
