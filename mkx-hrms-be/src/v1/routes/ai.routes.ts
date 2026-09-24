import { Router } from "express";
import { requireAuth } from "../../middlewares/auth.middleware";
import {
  chatWithAssistant,
  clearChatHistory,
  getChatHistory,
} from "../controllers/ai.controller";

const router = Router();

router.post("/chat", requireAuth, chatWithAssistant);
router.get("/history", requireAuth, getChatHistory);
router.delete("/history", requireAuth, clearChatHistory);

export default router;

