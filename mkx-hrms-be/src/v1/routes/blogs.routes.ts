import { Router } from "express";
import {
  getBlogs,
  getBlogStats,
  getBlogFilters,
  getBlogById,
  exportBlogs,
  createBlog,
  updateBlog,
  deleteBlog,
} from "../controllers/blogs.controller";
import { validate } from "../../middlewares/validate.middleware";
import { createBlogSchema, updateBlogSchema } from "../schemas/blogs.schema";

const router = Router();

router.get("/", getBlogs);
router.get("/stats", getBlogStats);
router.get("/filters", getBlogFilters);
router.get("/export", exportBlogs);
router.get("/:id", getBlogById);
router.post("/", validate(createBlogSchema), createBlog);
router.put("/:id", validate(updateBlogSchema), updateBlog);
router.delete("/:id", deleteBlog);

export default router;
