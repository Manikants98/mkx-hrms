import { Router } from "express";
import { requireAuth } from "../../middlewares/auth.middleware";
import { getNotifications, markNotificationRead, markAllNotificationsRead } from "../controllers/notifications.controller";

const router = Router();

router.get("/", requireAuth, getNotifications);
router.patch("/mark-all-read", requireAuth, markAllNotificationsRead);
router.patch("/:id/read", requireAuth, markNotificationRead);

export default router;

