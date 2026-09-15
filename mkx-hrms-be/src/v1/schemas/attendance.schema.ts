import { z } from "zod";

export const updateAttendanceStatusSchema = z.object({
  body: z.object({
    status: z.enum(["Present", "Late", "Absent", "Remote", "On Leave"]).optional(),
    check_in: z.string().nullable().optional(),
    check_out: z.string().nullable().optional(),
    location: z.string().optional(),
    work_hours: z.string().nullable().optional(),
  }),
});

export const punchAttendanceSchema = z.object({
  body: z.object({
    employee_id: z.union([z.string(), z.number()]).optional(),
    action: z.enum(["check-in", "check-out"]),
    location: z.string().optional(),
    date: z.string().optional(),
    time: z.string().optional(),
    timezone: z.string().optional(),
  }),
});

export const triggerDailyAttendanceCronSchema = z.object({
  body: z.object({}).loose().optional(),
});
