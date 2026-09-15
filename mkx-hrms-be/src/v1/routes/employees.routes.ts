import { Router } from "express";
import {
  getEmployees,
  getEmployeeStats,
  exportEmployees,
  createEmployee,
  updateEmployee,
  deleteEmployee,
  getEmployeeFilters,
  getEmployeeSalaryStructures,
  assignEmployeeSalaryStructures,
  getEmployeeById,
  resetEmployeePassword,
} from "../controllers/employees.controller";
import { validate } from "../../middlewares/validate.middleware";
import {
  createEmployeeSchema,
  updateEmployeeSchema,
  assignEmployeeSalaryStructuresSchema,
} from "../schemas/employees.schema";

const router = Router();

router.get("/", getEmployees);
router.get("/stats", getEmployeeStats);
router.get("/filters", getEmployeeFilters);
router.get("/export", exportEmployees);
router.get("/:id/salary-structures", getEmployeeSalaryStructures);
router.get("/:id", getEmployeeById);
router.post(
  "/:id/salary-structures",
  validate(assignEmployeeSalaryStructuresSchema),
  assignEmployeeSalaryStructures,
);
router.post("/:id/reset-password", resetEmployeePassword);
router.post("/", validate(createEmployeeSchema), createEmployee);
router.put("/:id", validate(updateEmployeeSchema), updateEmployee);
router.delete("/:id", deleteEmployee);

export default router;
