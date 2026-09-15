import { Router } from "express";
import {
  getPayroll,
  getPayrollStats,
  generatePayroll,
  processBatchPayroll,
  exportPayroll,
  getPayrollFilters,
  updatePayrollStatus,
  getMyPayroll,
  exportPayrollPdf,
} from "../controllers/payroll.controller";
import { validate } from "../../middlewares/validate.middleware";
import {
  generatePayrollSchema,
  processBatchPayrollSchema,
  updatePayrollStatusSchema,
} from "../schemas/payroll.schema";

const router = Router();

router.get("/", getPayroll);
router.get("/my", getMyPayroll);
router.get("/stats", getPayrollStats);
router.get("/filters", getPayrollFilters);
router.get("/export", exportPayroll);
router.post("/generate", validate(generatePayrollSchema), generatePayroll);
router.post("/process-batch", validate(processBatchPayrollSchema), processBatchPayroll);
router.patch("/:id/status", validate(updatePayrollStatusSchema), updatePayrollStatus);
router.get("/:id/pdf", exportPayrollPdf);

export default router;
