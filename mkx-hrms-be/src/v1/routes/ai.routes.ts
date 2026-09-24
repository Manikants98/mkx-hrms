import { Router } from "express";
import { requireAuth } from "../../middlewares/auth.middleware";
import { chatWithAssistant } from "../controllers/ai.controller";

const router = Router();

router.post("/chat", requireAuth, chatWithAssistant);

export default router;
