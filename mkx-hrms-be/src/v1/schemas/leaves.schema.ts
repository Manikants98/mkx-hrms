import { z } from "zod";

export const createLeaveSchema = z.object({
  body: z.object({
    employee_id: z.union([z.string(), z.number()]).optional(),
    leave_type: z.string().optional(),
    leave_type_id: z.union([z.string(), z.number()]).optional(),
    start_date: z.string().min(1, "Start date is required"),
    end_date: z.string().min(1, "End date is required"),
    reason: z.string().optional(),
  }),
});

export const updateLeaveStatusSchema = z.object({
  body: z.object({
    status: z.enum(["Approved", "Rejected", "Pending"]),
    remark: z.string().nullable().optional(),
  }),
});

export const processLeaveApprovalSchema = z.object({
  body: z.object({
    status: z.enum(["Approved", "Rejected"]),
    remark: z.string().nullable().optional(),
  }),
});
