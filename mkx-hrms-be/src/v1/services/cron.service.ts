import cron from "node-cron";
import { prisma } from "../../libraries/prisma";
import { logger } from "../../utils/logger";

/**
 * Result structure returned by daily attendance initialization
 */
export interface DailyAttendanceInitResult {
  createdCount: number;
  totalActive: number;
  date: string;
}

/**
 * Generates default attendance records for all active employees for the current day.
 * If an employee is on approved leave, sets their status to 'On Leave', otherwise sets to 'Absent'.
 *
 * @param targetDateStr - Optional target calendar date (YYYY-MM-DD), defaults to today in Asia/Kolkata
 * @returns Result object with created count, total active employees, and target date
 */
export const generateDailyAttendance = async (
  targetDateStr?: string,
): Promise<DailyAttendanceInitResult> => {
  logger.info("Starting daily attendance generation job...");
  try {
    const dateString =
      targetDateStr || new Date().toLocaleDateString("en-CA", { timeZone: "Asia/Kolkata" });

    const todayDate = new Date(`${dateString}T00:00:00.000Z`);

    const activeEmployees = await prisma.employee.findMany({
      where: {
        status: "Active",
      },
    });

    const activeLeaves = await prisma.leave.findMany({
      where: {
        status: "Approved",
        start_date: { lte: todayDate },
        end_date: { gte: todayDate },
      },
    });

    const employeesOnLeave = new Set(activeLeaves.map((l) => l.employee_id));

    let createdCount = 0;

    for (const emp of activeEmployees) {
      const recordId = `ATT-${emp.id}-${dateString}`;

      const exists = await prisma.attendance.findUnique({
        where: { record_id: recordId },
      });

      if (!exists) {
        await prisma.attendance.create({
          data: {
            record_id: recordId,
            employee_id: emp.id,
            date: todayDate,
            status: employeesOnLeave.has(emp.id) ? "On Leave" : "Absent",
            location: "Office",
            check_in: null,
            check_out: null,
            work_hours: null,
          },
        });
        createdCount++;
      }
    }

    logger.info(`Daily attendance generation completed. Created ${createdCount} new records.`);
    return {
      createdCount,
      totalActive: activeEmployees.length,
      date: dateString,
    };
  } catch (error) {
    logger.error("Failed to generate daily attendance:", error);
    throw error;
  }
};

/**
 * Automatically creates in-app and push notification records for HR / Admin users
 * when active employees celebrate birthdays or work anniversaries.
 *
 * @param targetDateStr - Optional calendar date string in YYYY-MM-DD (defaults to Asia/Kolkata today)
 * @param specificUserId - Optional specific user ID to guarantee notification delivery to
 * @returns Number of newly created notification records
 */
export const generateCelebrationNotifications = async (
  targetDateStr?: string,
  specificUserId?: number,
): Promise<number> => {
  try {
    const today = new Date();
    const tDay = Number(
      today.toLocaleString("en-US", { timeZone: "Asia/Kolkata", day: "numeric" }),
    );
    const tMonth = Number(
      today.toLocaleString("en-US", { timeZone: "Asia/Kolkata", month: "numeric" }),
    );
    const tYear = Number(
      today.toLocaleString("en-US", { timeZone: "Asia/Kolkata", year: "numeric" }),
    );

    const dateKey =
      targetDateStr || today.toLocaleDateString("en-CA", { timeZone: "Asia/Kolkata" });

    const activeEmployees = await prisma.employee.findMany({
      where: { status: "Active" },
      select: {
        id: true,
        name: true,
        birth_date: true,
        join_date: true,
      },
    });

    interface CelebrationItem {
      employeeId: number;
      name: string;
      title: string;
      message: string;
      type: string;
    }

    const celebrations: CelebrationItem[] = [];

    for (const emp of activeEmployees) {
      if (emp.birth_date) {
        const bDay = Number(
          emp.birth_date.toLocaleString("en-US", { timeZone: "Asia/Kolkata", day: "numeric" }),
        );
        const bMonth = Number(
          emp.birth_date.toLocaleString("en-US", { timeZone: "Asia/Kolkata", month: "numeric" }),
        );
        if (bDay === tDay && bMonth === tMonth) {
          celebrations.push({
            employeeId: emp.id,
            name: emp.name,
            title: "Birthday Today!",
            message: `${emp.name} has a birthday today! Wish them a great day.`,
            type: "celebration",
          });
        }
      }

      if (emp.join_date) {
        const jDay = Number(
          emp.join_date.toLocaleString("en-US", { timeZone: "Asia/Kolkata", day: "numeric" }),
        );
        const jMonth = Number(
          emp.join_date.toLocaleString("en-US", { timeZone: "Asia/Kolkata", month: "numeric" }),
        );
        const jYear = Number(
          emp.join_date.toLocaleString("en-US", { timeZone: "Asia/Kolkata", year: "numeric" }),
        );
        if (jDay === tDay && jMonth === tMonth && jYear < tYear) {
          const years = tYear - jYear;
          celebrations.push({
            employeeId: emp.id,
            name: emp.name,
            title: "Work Anniversary Today!",
            message: `${emp.name} is celebrating ${years} ${years === 1 ? "year" : "years"} at the company today!`,
            type: "celebration",
          });
        }
      }
    }

    if (celebrations.length === 0) {
      return 0;
    }

    /** Find all HR and Admin users who should receive employee milestone notifications */
    let hrUsers = await prisma.user.findMany({
      where: {
        OR: [
          {
            role: {
              name: { in: ["Admin", "HR Specialist", "HR Manager", "HR Admin", "Super Admin"] },
            },
          },
          {
            employee: {
              role_rel: { name: { in: ["Admin", "HR Specialist", "HR Manager", "HR Admin"] } },
            },
          },
        ],
      },
      select: { id: true, fcm_token: true },
    });

    if (hrUsers.length === 0) {
      hrUsers = await prisma.user.findMany({
        select: { id: true, fcm_token: true },
      });
    }

    /** Add specific requesting user if provided and not already present */
    if (specificUserId && !hrUsers.some((u) => u.id === specificUserId)) {
      const specificUser = await prisma.user.findUnique({
        where: { id: specificUserId },
        select: { id: true, fcm_token: true },
      });
      if (specificUser) {
        hrUsers.push(specificUser);
      }
    }

    let createdCount = 0;

    for (const hrUser of hrUsers) {
      for (const item of celebrations) {
        /** Check if this notification has already been created today to prevent duplication */
        const existing = await prisma.notification.findFirst({
          where: {
            user_id: hrUser.id,
            title: item.title,
            message: item.message,
            created_at: {
              gte: new Date(`${dateKey}T00:00:00.000Z`),
            },
          },
        });

        if (!existing) {
          await prisma.notification.create({
            data: {
              user_id: hrUser.id,
              title: item.title,
              message: item.message,
              type: item.type,
              sender_name: "System",
              data: {
                employee_id: item.employeeId,
                date: dateKey,
              },
            },
          });
          createdCount++;

          if (hrUser.fcm_token) {
            try {
              const { sendPushNotification } = require("../../libraries/firebase");
              await sendPushNotification(hrUser.fcm_token, item.title, item.message, {
                route: "/notifications",
              });
            } catch (err: unknown) {
              logger.warn(
                `Failed to dispatch FCM push notification to user ${hrUser.id}: ${String(err)}`,
              );
            }
          }
        }
      }
    }

    logger.info(`Celebration notifications generated. Created ${createdCount} notifications.`);
    return createdCount;
  } catch (error: unknown) {
    logger.error("Failed to generate celebration notifications:", error);
    return 0;
  }
};

/**
 * Initializes and schedules all background cron jobs.
 */
export const initCronJobs = () => {
  logger.info("Initializing background cron jobs...");

  cron.schedule("0 0 * * *", () => {
    generateDailyAttendance();
    generateCelebrationNotifications();
  });
};
