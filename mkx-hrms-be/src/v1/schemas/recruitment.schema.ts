import { z } from "zod";

export const createCandidateSchema = z.object({
  body: z.object({
    name: z.string().min(1, "Name is required"),
    email: z.email("Invalid email address"),
    phone: z.string().optional(),
    position: z.string().min(1, "Position is required"),
    department: z.string().min(1, "Department is required"),
    experience: z.string().min(1, "Experience is required"),
    rating: z.union([z.string(), z.number()]).optional(),
    avatar: z.string().nullable().optional(),
    resume_url: z.string().nullable().optional(),
    source: z.string().nullable().optional(),
    job_posting_id: z.number().nullable().optional(),
  }),
});

export const updateCandidateDetailsSchema = z.object({
  body: z.object({
    name: z.string().optional(),
    email: z.email().optional(),
    phone: z.string().optional(),
    position: z.string().optional(),
    department: z.string().optional(),
    experience: z.string().optional(),
    rating: z.union([z.string(), z.number()]).optional(),
    avatar: z.string().nullable().optional(),
    resume_url: z.string().nullable().optional(),
    source: z.string().nullable().optional(),
    job_posting_id: z.number().nullable().optional(),
  }),
});

export const updateCandidateStatusSchema = z.object({
  body: z.object({
    stage: z.enum(["Screening", "Interviewing", "Offered", "Hired"]).optional(),
    status: z.enum(["Active", "In Review", "Offered", "Rejected"]).optional(),
  }),
});

export const onboardCandidateSchema = z.object({
  body: z.record(z.string(), z.unknown()).optional(),
});

export const createCandidateInterviewSchema = z.object({
  body: z.object({
    interviewer_id: z.union([z.string(), z.number()]).optional(),
    scheduled_at: z.string().refine((val) => !isNaN(Date.parse(val)), "Invalid date format"),
    notes: z.string().optional(),
  }),
});

export const updateCandidateInterviewSchema = z.object({
  body: z.object({
    status: z.string().optional(),
    notes: z.string().optional(),
    rating: z.union([z.string(), z.number()]).optional(),
    scheduled_at: z
      .string()
      .refine((val) => !isNaN(Date.parse(val)), "Invalid date format")
      .optional(),
    interviewer_id: z.union([z.string(), z.number()]).optional(),
  }),
});
