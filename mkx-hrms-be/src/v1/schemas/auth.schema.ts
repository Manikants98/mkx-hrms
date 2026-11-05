import { z } from "zod";

export const loginSchema = z.object({
  body: z.object({
    email: z
      .string()
      .trim()
      .min(1, "Email is required")
      .refine((val) => !val || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(val), {
        message: "Invalid email address",
      }),
    password: z.string().min(1, "Password is required"),
  }),
});

export const verifySetPasswordTokenSchema = z.object({
  query: z.object({
    token: z.string().min(1, "Token is required"),
  }),
});

export const setPasswordSchema = z.object({
  body: z
    .object({
      token: z.string().min(1, "Token is required"),
      password: z.string().min(8, "Password must be at least 8 characters"),
      confirmPassword: z.string().min(8, "Confirm Password must be at least 8 characters"),
    })
    .refine((data) => data.password === data.confirmPassword, {
      message: "Passwords do not match",
      path: ["confirmPassword"],
    }),
});
