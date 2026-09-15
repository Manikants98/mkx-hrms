import { Router } from "express";
import {
  getAttendance,
  getAttendanceStats,
  exportAttendance,
  getAttendanceFilters,
  updateAttendanceStatus,
  punchAttendance,
  getMyAttendance,
  triggerDailyAttendanceCron,
} from "../controllers/attendance.controller";
import { validate } from "../../middlewares/validate.middleware";
import {
  updateAttendanceStatusSchema,
  punchAttendanceSchema,
  triggerDailyAttendanceCronSchema,
} from "../schemas/attendance.schema";

const router = Router();

router.get("/", getAttendance);
router.get("/my", getMyAttendance);
router.get("/stats", getAttendanceStats);
router.get("/filters", getAttendanceFilters);
router.get("/export", exportAttendance);
router.patch("/:id/status", validate(updateAttendanceStatusSchema), updateAttendanceStatus);
router.post("/punch", validate(punchAttendanceSchema), punchAttendance);
router.post(
  "/generate-daily",
  validate(triggerDailyAttendanceCronSchema),
  triggerDailyAttendanceCron,
);

export default router;
