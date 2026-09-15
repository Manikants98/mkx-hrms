import { Router } from "express";
import {
  getCandidates,
  getRecruitmentStats,
  exportCandidates,
  createCandidate,
  onboardCandidate,
  getRecruitmentFilters,
  updateCandidateStatus,
  deleteCandidate,
  getCandidateById,
  createCandidateInterview,
  updateCandidateInterview,
  deleteCandidateInterview,
  updateCandidateDetails,
} from "../controllers/recruitment.controller";
import { validate } from "../../middlewares/validate.middleware";
import {
  createCandidateSchema,
  updateCandidateDetailsSchema,
  updateCandidateStatusSchema,
  onboardCandidateSchema,
  createCandidateInterviewSchema,
  updateCandidateInterviewSchema,
} from "../schemas/recruitment.schema";

const router = Router();

router.get("/candidates", getCandidates);
router.get("/stats", getRecruitmentStats);
router.get("/filters", getRecruitmentFilters);
router.get("/export", exportCandidates);
router.get("/candidates/:id", getCandidateById);
router.post("/candidates", validate(createCandidateSchema), createCandidate);
router.put("/candidates/:id", validate(updateCandidateDetailsSchema), updateCandidateDetails);
router.post("/candidates/:id/onboard", validate(onboardCandidateSchema), onboardCandidate);
router.patch("/candidates/:id/status", validate(updateCandidateStatusSchema), updateCandidateStatus);
router.delete("/candidates/:id", deleteCandidate);

router.post("/candidates/:candidate_id/interviews", validate(createCandidateInterviewSchema), createCandidateInterview);
router.put("/interviews/:interview_id", validate(updateCandidateInterviewSchema), updateCandidateInterview);
router.delete("/interviews/:interview_id", deleteCandidateInterview);

export default router;
