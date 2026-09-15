import { z } from "zod";

export const createBlogSchema = z.object({
  body: z.object({
    title: z.string().min(1, "Title is required"),
    slug: z.string().optional(),
    content: z.string().min(1, "Content is required"),
    excerpt: z.string().optional(),
    cover_image: z.string().nullable().optional(),
    category: z.string().min(1, "Category is required"),
    tags: z.array(z.string()).optional(),
    status: z.enum(["Draft", "Published", "Archived"]).optional(),
    author_name: z.string().optional(),
    author_id: z.union([z.string(), z.number()]).optional(),
  }),
});

export const updateBlogSchema = z.object({
  body: z.object({
    title: z.string().min(1).optional(),
    slug: z.string().optional(),
    content: z.string().min(1).optional(),
    excerpt: z.string().optional(),
    cover_image: z.string().nullable().optional(),
    category: z.string().min(1).optional(),
    tags: z.array(z.string()).optional(),
    status: z.enum(["Draft", "Published", "Archived"]).optional(),
    author_name: z.string().optional(),
    author_id: z.union([z.string(), z.number()]).optional(),
  }),
});
