import { Router } from "express";
import {
  getDashboardOverview,
  getAllActivities,
  getWorkforceTrend,
  sendWish,
} from "../controllers/dashboard.controller";

const router = Router();

router.get("/", getDashboardOverview);
router.get("/overview", getDashboardOverview);
router.get("/activities", getAllActivities);
router.get("/workforce-trend", getWorkforceTrend);
router.post("/send-wish", sendWish);

export default router;
