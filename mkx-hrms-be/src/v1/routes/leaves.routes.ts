import { Router } from "express";
import {
  getLeaves,
  getLeaveStats,
  exportLeaves,
  updateLeaveStatus,
  getLeaveFilters,
  createLeave,
  getMyLeaves,
  getLeaveByApprovalToken,
  processLeaveApproval,
} from "../controllers/leaves.controller";
import { validate } from "../../middlewares/validate.middleware";
import {
  createLeaveSchema,
  updateLeaveStatusSchema,
  processLeaveApprovalSchema,
} from "../schemas/leaves.schema";

const router = Router();

router.get("/approval/:token", getLeaveByApprovalToken);
router.post("/approval/:token", validate(processLeaveApprovalSchema), processLeaveApproval);

router.get("/", getLeaves);
router.get("/my", getMyLeaves);
router.post("/", validate(createLeaveSchema), createLeave);
router.get("/stats", getLeaveStats);
router.get("/filters", getLeaveFilters);
router.get("/export", exportLeaves);
router.patch("/:id/status", validate(updateLeaveStatusSchema), updateLeaveStatus);

export default router;
