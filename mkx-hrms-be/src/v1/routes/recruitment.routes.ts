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
} from "../controllers/recruitment.controller";

const router = Router();

router.get("/candidates", getCandidates);
router.get("/stats", getRecruitmentStats);
router.get("/filters", getRecruitmentFilters);
router.get("/export", exportCandidates);
router.get("/candidates/:id", getCandidateById);
router.post("/candidates", createCandidate);
router.post("/candidates/:id/onboard", onboardCandidate);
router.patch("/candidates/:id/status", updateCandidateStatus);
router.delete("/candidates/:id", deleteCandidate);

router.post("/candidates/:candidate_id/interviews", createCandidateInterview);
router.put("/interviews/:interview_id", updateCandidateInterview);
router.delete("/interviews/:interview_id", deleteCandidateInterview);

export default router;

