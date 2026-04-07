import { Router } from "express";

import { requireAuth } from "../middleware/requireAuth";
import { assignmentsRouter } from "./assignmentsRoutes";
import { employeesRouter } from "./employeesRoutes";
import { healthRouter } from "./healthRoutes";
import { jobsRouter } from "./jobsRoutes";
import { locationsRouter } from "./locationsRoutes";
import { organizationsRouter } from "./organizationsRoutes";
import { publicAuthRouter } from "./publicAuthRoutes";
import { trackingRouter } from "./trackingRoutes";
import { workersRouter } from "./workersRoutes";

const publicRouter = Router();
const apiRouter = Router();

publicRouter.use(healthRouter);
publicRouter.use("/auth", publicAuthRouter);

apiRouter.use(healthRouter);
apiRouter.use(requireAuth);
apiRouter.use("/organizations", organizationsRouter);
apiRouter.use("/employees", employeesRouter);
apiRouter.use("/jobs", jobsRouter);
apiRouter.use("/locations", locationsRouter);
apiRouter.use("/assignments", assignmentsRouter);
apiRouter.use("/workers", workersRouter);
apiRouter.use("/tracking", trackingRouter);

export { apiRouter, publicRouter };
