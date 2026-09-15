import { z } from "zod";

export const createJobPostingSchema = z.object({
  body: z.object({
    title: z.string().min(1, "Title is required"),
    department_id: z.union([z.string(), z.number()]).optional(),
    location: z.string().optional(),
    employment_type: z.string().optional(),
    experience_level: z.string().optional(),
    salary_range: z.string().optional(),
    description: z.string().optional(),
    vacancies: z.union([z.string(), z.number()]).optional(),
    status: z.string().optional(),
  }),
});

export const updateJobPostingSchema = z.object({
  body: z.object({
    title: z.string().optional(),
    department_id: z.union([z.string(), z.number()]).optional(),
    location: z.string().optional(),
    employment_type: z.string().optional(),
    experience_level: z.string().optional(),
    salary_range: z.string().optional(),
    description: z.string().optional(),
    vacancies: z.union([z.string(), z.number()]).optional(),
    status: z.string().optional(),
  }),
});
