import { Router } from "express";
import { login, logout, getMe, verifySetPasswordToken, setPasswordWithToken, saveFcmToken } from "../controllers/auth.controller";
import { validate } from "../../middlewares/validate.middleware";
import { loginSchema, setPasswordSchema, verifySetPasswordTokenSchema } from "../schemas/auth.schema";

const router = Router();

router.post("/login", validate(loginSchema), login);
router.post("/logout", logout);
router.get("/me", getMe);
router.post("/fcm-token", saveFcmToken);
router.get("/set-password", validate(verifySetPasswordTokenSchema), verifySetPasswordToken);
router.post("/set-password", validate(setPasswordSchema), setPasswordWithToken);

export default router;
