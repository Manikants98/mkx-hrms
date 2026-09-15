import { z } from "zod";

export const createDepartmentSchema = z.object({
  body: z.object({
    name: z.string().min(1, "Department name is required"),
    code: z.string().optional(),
    description: z.string().nullable().optional(),
    status: z.enum(["Active", "Inactive"]).optional(),
  }),
});

export const updateDepartmentSchema = z.object({
  body: z.object({
    name: z.string().min(1).optional(),
    code: z.string().optional(),
    description: z.string().nullable().optional(),
    status: z.enum(["Active", "Inactive"]).optional(),
  }),
});

export const createRoleSchema = z.object({
  body: z.object({
    name: z.string().min(1, "Role name is required"),
    description: z.string().nullable().optional(),
    permissions: z.array(z.number()).optional(),
    status: z.enum(["Active", "Inactive"]).optional(),
  }),
});

export const updateRoleSchema = z.object({
  body: z.object({
    name: z.string().min(1).optional(),
    description: z.string().nullable().optional(),
    permissions: z.array(z.number()).optional(),
    status: z.enum(["Active", "Inactive"]).optional(),
  }),
});

export const createDesignationSchema = z.object({
  body: z.object({
    title: z.string().min(1, "Designation title is required"),
    department_id: z.union([z.string(), z.number()]).optional(),
    status: z.enum(["Active", "Inactive"]).optional(),
  }),
});

export const updateDesignationSchema = z.object({
  body: z.object({
    title: z.string().min(1).optional(),
    department_id: z.union([z.string(), z.number()]).optional(),
    status: z.enum(["Active", "Inactive"]).optional(),
  }),
});

export const createLeaveTypeSchema = z.object({
  body: z.object({
    name: z.string().min(1, "Leave type name is required"),
    description: z.string().nullable().optional(),
    days_allowed: z.union([z.string(), z.number()]),
    carry_forward: z.boolean().optional(),
    status: z.enum(["Active", "Inactive"]).optional(),
  }),
});

export const updateLeaveTypeSchema = z.object({
  body: z.object({
    name: z.string().min(1).optional(),
    description: z.string().nullable().optional(),
    days_allowed: z.union([z.string(), z.number()]).optional(),
    carry_forward: z.boolean().optional(),
    status: z.enum(["Active", "Inactive"]).optional(),
  }),
});

export const createSalaryStructureSchema = z.object({
  body: z.object({
    name: z.string().min(1, "Salary structure name is required"),
    type: z.enum(["Allowance", "Deduction"]),
    default_value: z.union([z.string(), z.number()]),
    is_taxable: z.boolean().optional(),
    status: z.enum(["Active", "Inactive"]).optional(),
  }),
});

export const updateSalaryStructureSchema = z.object({
  body: z.object({
    name: z.string().min(1).optional(),
    type: z.enum(["Allowance", "Deduction"]).optional(),
    default_value: z.union([z.string(), z.number()]).optional(),
    is_taxable: z.boolean().optional(),
    status: z.enum(["Active", "Inactive"]).optional(),
  }),
});

export const createWorkShiftSchema = z.object({
  body: z.object({
    name: z.string().min(1, "Shift name is required"),
    start_time: z.string().min(1, "Start time is required"),
    end_time: z.string().min(1, "End time is required"),
    status: z.enum(["Active", "Inactive"]).optional(),
  }),
});

export const updateWorkShiftSchema = z.object({
  body: z.object({
    name: z.string().min(1).optional(),
    start_time: z.string().min(1).optional(),
    end_time: z.string().min(1).optional(),
    status: z.enum(["Active", "Inactive"]).optional(),
  }),
});
