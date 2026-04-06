import cors from "cors";
import express from "express";
import helmet from "helmet";

import { apiRouter } from "./api";

export function createApp() {
  const app = express();

  app.use(cors());
  app.use(helmet());
  app.use(express.json());

  app.use("/", apiRouter);
  app.use("/api", apiRouter);

  return app;
}
