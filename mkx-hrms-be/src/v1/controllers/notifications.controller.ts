import { Request, Response, NextFunction } from "express";
import { prisma } from "../../libraries/prisma";

/**
 * Retrieve all notifications for the authenticated user, ordered newest first
 *
 * @param req - Express request with `req.user` populated by `requireAuth`
 * @param res - Express response
 * @param next - Next middleware delegate
 */
export const getNotifications = async (
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  try {
    const userId = req.user!.id;

    const notifications = await prisma.notification.findMany({
      where: { user_id: userId },
      orderBy: { created_at: "desc" },
      take: 50,
    });

    const unreadCount = notifications.filter((n) => !n.is_read).length;

    res.sendSuccess({ data: { notifications, unread_count: unreadCount } });
  } catch (err) {
    next(err);
  }
};

/**
 * Mark a single notification as read by its ID
 *
 * @param req - Express request with `req.user` populated by `requireAuth`
 * @param res - Express response
 * @param next - Next middleware delegate
 */
export const markNotificationRead = async (
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  try {
    const userId = req.user!.id;
    const id = parseInt(req.params["id"] as string, 10);

    if (isNaN(id)) {
      res.sendError({ statusCode: 400, message: "Invalid notification ID" });
      return;
    }

    const notification = await prisma.notification.findFirst({
      where: { id, user_id: userId },
    });

    if (!notification) {
      res.sendError({ statusCode: 404, message: "Notification not found" });
      return;
    }

    await prisma.notification.update({
      where: { id },
      data: { is_read: true },
    });

    res.sendSuccess({ message: "Notification marked as read" });
  } catch (err) {
    next(err);
  }
};

/**
 * Mark all notifications as read for the authenticated user
 *
 * @param req - Express request with `req.user` populated by `requireAuth`
 * @param res - Express response
 * @param next - Next middleware delegate
 */
export const markAllNotificationsRead = async (
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  try {
    const userId = req.user!.id;

    await prisma.notification.updateMany({
      where: { user_id: userId, is_read: false },
      data: { is_read: true },
    });

    res.sendSuccess({ message: "All notifications marked as read" });
  } catch (err) {
    next(err);
  }
};
