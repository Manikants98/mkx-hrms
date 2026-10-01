import { Router } from "express";
import {
  login,
  logout,
  getMe,
  verifySetPasswordToken,
  setPasswordWithToken,
  saveFcmToken,
} from "../controllers/auth.controller";
import { validate } from "../../middlewares/validate.middleware";
import {
  loginSchema,
  setPasswordSchema,
  verifySetPasswordTokenSchema,
} from "../schemas/auth.schema";

import { requireAuth } from "../../middlewares/auth.middleware";

const router = Router();

// Public routes
router.post("/login", validate(loginSchema), login);
router.get("/set-password", validate(verifySetPasswordTokenSchema), verifySetPasswordToken);
router.post("/set-password", validate(setPasswordSchema), setPasswordWithToken);

// Protected routes
router.post("/logout", requireAuth, logout);
router.get("/me", requireAuth, getMe);
router.post("/fcm-token", requireAuth, saveFcmToken);

export default router;
