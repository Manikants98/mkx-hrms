import { Router } from "express";
import authRoutes from "./auth.routes";
import userRoutes from "./users.routes";
import employeesRoutes from "./employees.routes";
import attendanceRoutes from "./attendance.routes";
import leavesRoutes from "./leaves.routes";
import payrollRoutes from "./payroll.routes";
import recruitmentRoutes from "./recruitment.routes";
import reportsRoutes from "./reports.routes";
import dashboardRoutes from "./dashboard.routes";
import settingsRoutes from "./settings.routes";
import blogsRoutes from "./blogs.routes";
import mastersRoutes from "./masters.routes";
import jobPostingsRoutes from "./job-postings.routes";
import contactRoutes from "./contact.routes";
import aiRoutes from "./ai.routes";
import notificationsRoutes from "./notifications.routes";
import { requireAuth } from "../../middlewares/auth.middleware";

const router = Router();

// ==========================================
// PUBLIC ROUTES (No Auth Required)
// ==========================================
router.use("/auth", authRoutes);
router.use("/blogs", blogsRoutes);
router.use("/job-postings", jobPostingsRoutes);
router.use("/contact", contactRoutes);
router.use("/leaves", leavesRoutes); // Granular auth inside leaves.routes.ts

// ==========================================
// AUTHENTICATION BARRIER
// ==========================================
// All routes below this line will require a valid JWT token
router.use(requireAuth);

// ==========================================
// PRIVATE ROUTES (Protected)
// ==========================================
router.use("/users", userRoutes);
router.use("/employees", employeesRoutes);
router.use("/attendance", attendanceRoutes);
router.use("/payroll", payrollRoutes);
router.use("/recruitment", recruitmentRoutes);
router.use("/reports", reportsRoutes);
router.use("/dashboard", dashboardRoutes);
router.use("/hr/dashboard", dashboardRoutes);
router.use("/settings", settingsRoutes);
router.use("/masters", mastersRoutes);
router.use("/ai", aiRoutes);
router.use("/notifications", notificationsRoutes);

export default router;
