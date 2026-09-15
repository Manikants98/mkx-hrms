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

const router = Router();

router.get("/", getPayroll);
router.get("/my", getMyPayroll);
router.get("/stats", getPayrollStats);
router.get("/filters", getPayrollFilters);
router.get("/export", exportPayroll);
router.post("/generate", generatePayroll);
router.post("/process-batch", processBatchPayroll);
router.patch("/:id/status", updatePayrollStatus);
router.get("/:id/pdf", exportPayrollPdf);

export default router;
