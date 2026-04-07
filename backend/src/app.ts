import cors from "cors";
import express from "express";
import helmet from "helmet";

import { errorHandler } from "./middleware/errorHandler";
import { notFoundHandler } from "./middleware/notFoundHandler";
import { apiRouter, publicRouter } from "./routes";

export function createApp() {
  const app = express();

  app.use(cors());
  app.use(helmet());
  app.use(express.json());

  app.use("/", publicRouter);
  app.use("/api", apiRouter);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
