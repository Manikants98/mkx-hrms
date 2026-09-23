import { z } from "zod";

export const createEmployeeSchema = z.object({
  body: z.object({
    name: z.string().min(1, "Name is required"),
    email: z.email("Invalid email address"),
    first_name: z.string().optional(),
    last_name: z.string().optional(),
    role_id: z.union([z.string(), z.number()]).optional().nullable(),
    role: z.string().optional(),
    department_id: z.union([z.string(), z.number()]).optional().nullable(),
    department: z.string().optional(),
    manager_id: z.union([z.string(), z.number()]).optional().nullable(),
    manager: z.string().optional(),
    manager_name: z.string().optional(),
    shift_id: z.union([z.string(), z.number()]).optional().nullable(),
    shift: z.string().optional(),
    join_date: z.string().optional(),
    status: z.string().optional(),
    address: z.string().nullable().optional(),
    phone: z.string().nullable().optional(),
  }),
});

export const updateEmployeeSchema = z.object({
  body: z.object({
    name: z.string().optional(),
    email: z.email().optional(),
    role_id: z.union([z.string(), z.number()]).optional().nullable(),
    role: z.string().optional(),
    department_id: z.union([z.string(), z.number()]).optional().nullable(),
    department: z.string().optional(),
    manager_id: z.union([z.string(), z.number()]).optional().nullable(),
    manager: z.string().optional(),
    shift_id: z.union([z.string(), z.number()]).optional().nullable(),
    shift: z.string().optional(),
    status: z.string().optional(),
    join_date: z.string().nullable().optional(),
    birth_date: z.string().nullable().optional(),
    address: z.string().nullable().optional(),
    phone: z.string().nullable().optional(),
    avatar: z.string().nullable().optional(),
    salary_structures: z
      .array(
        z.object({
          salary_structure_id: z.union([z.string(), z.number()]),
          amount: z.union([z.string(), z.number()]),
          effective_date: z.string().optional(),
          status: z.string().optional(),
        })
      )
      .optional(),
  }),
});

export const assignEmployeeSalaryStructuresSchema = z.object({
  body: z.object({
    salary_structures: z.array(
      z.object({
        salary_structure_id: z.union([z.string(), z.number()]),
        amount: z.union([z.string(), z.number()]),
        effective_date: z.string().optional(),
        status: z.string().optional(),
      })
    ),
  }),
});
