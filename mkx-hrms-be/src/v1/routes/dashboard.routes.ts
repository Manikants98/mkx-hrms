import { Router } from "express";
import {
  getDashboardOverview,
  getAllActivities,
  getWorkforceTrend,
} from "../controllers/dashboard.controller";

const router = Router();

router.get("/overview", getDashboardOverview);
router.get("/activities", getAllActivities);
router.get("/workforce-trend", getWorkforceTrend);

export default router;
