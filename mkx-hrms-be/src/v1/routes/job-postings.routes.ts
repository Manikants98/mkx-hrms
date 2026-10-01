import { Router } from "express";
import {
  getJobPostings,
  getJobPostingById,
  createJobPosting,
  updateJobPosting,
  deleteJobPosting,
} from "../controllers/job-postings.controller";
import { validate } from "../../middlewares/validate.middleware";
import {
  createJobPostingSchema,
  updateJobPostingSchema,
} from "../schemas/job-postings.schema";

import { requireAuth } from "../../middlewares/auth.middleware";

const router = Router();
router.get("/", getJobPostings);
router.get("/:id", getJobPostingById);
// Protected routes for creating/updating/deleting
router.use(requireAuth);

router.post("/", validate(createJobPostingSchema), createJobPosting);
router.put("/:id", validate(updateJobPostingSchema), updateJobPosting);
router.delete("/:id", deleteJobPosting);

export default router;
