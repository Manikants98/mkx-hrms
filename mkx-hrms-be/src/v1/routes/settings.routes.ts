import { Router } from "express";
import {
  getSettings,
  updateProfile,
  updateNotificationPreferences,
} from "../controllers/settings.controller";
import { validate } from "../../middlewares/validate.middleware";
import {
  updateProfileSchema,
  updateNotificationPreferencesSchema,
} from "../schemas/settings.schema";

const router = Router();

router.get("/", getSettings);
router.put("/profile", validate(updateProfileSchema), updateProfile);
router.put(
  "/notifications",
  validate(updateNotificationPreferencesSchema),
  updateNotificationPreferences,
);

export default router;
