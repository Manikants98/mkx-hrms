import { Router } from "express";
import {
  getDepartments,
  createDepartment,
  updateDepartment,
  deleteDepartment,
  getRoles,
  getPermissions,
  createRole,
  updateRole,
  deleteRole,
  getDesignations,
  createDesignation,
  updateDesignation,
  deleteDesignation,
  getLeaveTypes,
  createLeaveType,
  updateLeaveType,
  deleteLeaveType,
  getSalaryStructures,
  createSalaryStructure,
  updateSalaryStructure,
  deleteSalaryStructure,
  getWorkShifts,
  createWorkShift,
  updateWorkShift,
  deleteWorkShift,
} from "../controllers/masters.controller";
import { validate } from "../../middlewares/validate.middleware";
import {
  createDepartmentSchema,
  updateDepartmentSchema,
  createRoleSchema,
  updateRoleSchema,
  createDesignationSchema,
  updateDesignationSchema,
  createLeaveTypeSchema,
  updateLeaveTypeSchema,
  createSalaryStructureSchema,
  updateSalaryStructureSchema,
  createWorkShiftSchema,
  updateWorkShiftSchema,
} from "../schemas/masters.schema";

const router = Router();

/**
 * Department Master Endpoints
 */
router.get("/departments", getDepartments);
router.post("/departments", validate(createDepartmentSchema), createDepartment);
router.put("/departments/:id", validate(updateDepartmentSchema), updateDepartment);
router.delete("/departments/:id", deleteDepartment);

/**
 * Role and Permission Master Endpoints
 */
router.get("/roles", getRoles);
router.post("/roles", validate(createRoleSchema), createRole);
router.put("/roles/:id", validate(updateRoleSchema), updateRole);
router.delete("/roles/:id", deleteRole);
router.get("/permissions", getPermissions);

/**
 * Designation Master Endpoints
 */
router.get("/designations", getDesignations);
router.post("/designations", validate(createDesignationSchema), createDesignation);
router.put("/designations/:id", validate(updateDesignationSchema), updateDesignation);
router.delete("/designations/:id", deleteDesignation);

/**
 * Leave Type Master Endpoints
 */
router.get("/leave-types", getLeaveTypes);
router.post("/leave-types", validate(createLeaveTypeSchema), createLeaveType);
router.put("/leave-types/:id", validate(updateLeaveTypeSchema), updateLeaveType);
router.delete("/leave-types/:id", deleteLeaveType);

/**
 * Salary Structure Master Endpoints
 */
router.get("/salary-structures", getSalaryStructures);
router.post("/salary-structures", validate(createSalaryStructureSchema), createSalaryStructure);
router.put("/salary-structures/:id", validate(updateSalaryStructureSchema), updateSalaryStructure);
router.delete("/salary-structures/:id", deleteSalaryStructure);

/**
 * Work Shift Master Endpoints
 */
router.get("/shifts", getWorkShifts);
router.post("/shifts", validate(createWorkShiftSchema), createWorkShift);
router.put("/shifts/:id", validate(updateWorkShiftSchema), updateWorkShift);
router.delete("/shifts/:id", deleteWorkShift);

export default router;
