import { Router } from "express";

import { healthRouter } from "./healthRoutes";
import { jobsRouter } from "./jobsRoutes";
import { locationsRouter } from "./locationsRoutes";
import { assignmentsRouter } from "./assignmentsRoutes";
import { workersRouter } from "./workersRoutes";
import { trackingRouter } from "./trackingRoutes";
import { requireAuth } from "../middleware/requireAuth";

const publicRouter = Router();
const apiRouter = Router();

publicRouter.use(healthRouter);

apiRouter.use(healthRouter);
apiRouter.use(requireAuth);
apiRouter.use("/jobs", jobsRouter);
apiRouter.use("/locations", locationsRouter);
apiRouter.use("/assignments", assignmentsRouter);
apiRouter.use("/workers", workersRouter);
apiRouter.use("/tracking", trackingRouter);

export { apiRouter, publicRouter };
