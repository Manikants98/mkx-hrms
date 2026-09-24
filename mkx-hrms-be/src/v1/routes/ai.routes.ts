import { Router } from "express";
import { chatWithAssistant } from "../controllers/ai.controller";

const router = Router();

// Endpoint for Smart Assistant interactions
router.post("/chat", chatWithAssistant);

export default router;
