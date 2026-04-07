import { createApp } from "./app";
import { config } from "./config";
import { startStaleWorkerScheduler } from "./services/StaleWorkerService";
import { logger } from "./utils/logger";

const app = createApp();

startStaleWorkerScheduler();

app.listen(config.port, () => {
  logger.info(`Backend server listening on port ${config.port}`);
});
