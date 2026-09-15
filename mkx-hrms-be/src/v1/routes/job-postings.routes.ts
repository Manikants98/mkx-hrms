import { Router } from "express";
import {
  getJobPostings,
  getJobPostingById,
  createJobPosting,
  updateJobPosting,
  deleteJobPosting,
} from "../controllers/job-postings.controller";

const router = Router();

router.get("/", getJobPostings);
router.get("/:id", getJobPostingById);
router.post("/", createJobPosting);
router.put("/:id", updateJobPosting);
router.delete("/:id", deleteJobPosting);

export default router;
