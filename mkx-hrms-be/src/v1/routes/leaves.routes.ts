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

// ==========================================
// PUBLIC ROUTES (No Auth Required)
// ==========================================
// These endpoints rely on secure, one-time URL tokens rather than JWT Bearer tokens
router.get("/approval/:token", getLeaveByApprovalToken);
router.post("/approval/:token", validate(processLeaveApprovalSchema), processLeaveApproval);

// ==========================================
// PRIVATE ROUTES (Protected)
// ==========================================
import { requireAuth } from "../../middlewares/auth.middleware";
router.use(requireAuth);

router.get("/", getLeaves);
router.get("/my", getMyLeaves);
router.post("/", validate(createLeaveSchema), createLeave);
router.get("/stats", getLeaveStats);
router.get("/filters", getLeaveFilters);
router.get("/export", exportLeaves);
router.patch("/:id/status", validate(updateLeaveStatusSchema), updateLeaveStatus);

export default router;
