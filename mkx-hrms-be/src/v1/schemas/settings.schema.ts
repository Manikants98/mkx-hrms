import { z } from "zod";

export const updateProfileSchema = z.object({
  body: z.object({
    first_name: z.string().optional(),
    last_name: z.string().optional(),
    email: z.email().optional(),
    timezone: z.string().optional(),
    avatar: z.string().nullable().optional(),
  }),
});

export const updateNotificationPreferencesSchema = z.object({
  body: z.object({
    preferences: z.record(
      z.string(),
      z.object({
        email: z.boolean(),
        push: z.boolean(),
      })
    ),
  }),
});
