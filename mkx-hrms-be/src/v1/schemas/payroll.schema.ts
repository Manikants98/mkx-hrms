import { z } from "zod";

export const generatePayrollSchema = z.object({
  body: z.object({
    month: z.union([z.string(), z.number()]).optional(),
    year: z.union([z.string(), z.number()]).optional(),
    department_id: z.union([z.string(), z.number()]).optional(),
    employee_ids: z.array(z.union([z.string(), z.number()])).optional(),
    preview: z.boolean().optional(),
  }),
});

export const processBatchPayrollSchema = z.object({
  body: z.object({
    payroll_ids: z.array(z.union([z.string(), z.number()])),
    status: z.enum(["Pending", "Processed", "On Hold", "Paid"]).optional(),
  }),
});

export const updatePayrollStatusSchema = z.object({
  body: z.object({
    status: z.enum(["Pending", "Processed", "On Hold", "Paid"]),
  }),
});
