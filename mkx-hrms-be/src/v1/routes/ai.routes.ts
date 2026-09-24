import { Router } from "express";
import { requireAuth } from "../../middlewares/auth.middleware";
import {
  chatWithAssistant,
  clearChatHistory,
  getChatHistory,
  getDashboardInsights,
} from "../controllers/ai.controller";

const router = Router();

router.post("/chat", requireAuth, chatWithAssistant);
router.get("/history", requireAuth, getChatHistory);
router.delete("/history", requireAuth, clearChatHistory);
router.get("/dashboard-insights", requireAuth, getDashboardInsights);

export default router;

