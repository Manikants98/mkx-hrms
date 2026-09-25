import { NextFunction, Request, Response } from "express";
import { prisma } from "../../libraries/prisma";
import { GoogleGenAI } from "@google/genai";

/**
 * Computes human-friendly dynamic relative time string
 *
 * @param date - Date instance to compare against current time
 * @returns Formatted relative time string
 */
function formatRelativeTime(date: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffSec = Math.max(0, Math.floor(diffMs / 1000));
  const diffMin = Math.floor(diffSec / 60);
  const diffHours = Math.floor(diffMin / 60);
  const diffDays = Math.floor(diffHours / 24);

  if (diffSec < 45) return "Just now";
  if (diffMin < 60) return `${diffMin}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays === 1) return "Yesterday";
  if (diffDays < 7) return `${diffDays}d ago`;
  return date.toISOString().split("T")[0];
}

/**
 * Parses a work_hours string like "8h 30m" or "8h" or "30m" into total minutes
 *
 * @param raw - Raw work_hours string from the attendance record
 * @returns Total minutes as a number
 */
function parseWorkHoursToMinutes(raw: string | null): number {
  if (!raw) return 0;
  const hoursMatch = raw.match(/(\d+)h/);
  const minsMatch = raw.match(/(\d+)m/);
  const hours = hoursMatch ? parseInt(hoursMatch[1], 10) : 0;
  const mins = minsMatch ? parseInt(minsMatch[1], 10) : 0;
  return hours * 60 + mins;
}

/**
 * Formats total minutes into a human-readable string like "8h 30m"
 *
 * @param totalMinutes - Total minutes to format
 * @returns Formatted duration string
 */
function formatMinutesToHours(totalMinutes: number): string {
  const h = Math.floor(totalMinutes / 60);
  const m = totalMinutes % 60;
  if (h === 0) return `${m} M`;
  if (m === 0) return `${h} H`;
  return `${h} H ${m} M`;
}

/**
 * Parses a shift time string "HH:MM" or 12-hour format into total minutes from midnight
 *
 * @param timeStr - Shift start_time or end_time string
 * @returns Total minutes from midnight
 */
function parseShiftMinutes(timeStr: string): number {
  const match = timeStr.trim().match(/^(\d{1,2}):(\d{2})\s*(AM|PM)?$/i);
  if (!match) return 0;
  let hours = parseInt(match[1], 10);
  const mins = parseInt(match[2], 10);
  const mod = match[3]?.toUpperCase();
  if (mod === "PM" && hours < 12) hours += 12;
  if (mod === "AM" && hours === 12) hours = 0;
  return hours * 60 + mins;
}

/**
 * Controller to fetch comprehensive dashboard metrics, activities, and performers
 *
 * @param _req - Express request
 * @param res - Express response
 * @param next - Next middleware delegate
 */
export const getDashboardOverview = async (
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  try {
    const todayStr = new Date().toLocaleDateString("en-CA", { timeZone: "Asia/Kolkata" });
    const todayDate = new Date(`${todayStr}T00:00:00.000Z`);

    const userRole = (req.user?.role || "").toLowerCase();
    const isManager = userRole.includes("manager");
    const isAdminOrHR = userRole.includes("admin") || userRole.includes("hr");

    let managerEmployeeId = req.user?.employee_db_id;
    if (!managerEmployeeId && req.user?.id && isManager && !isAdminOrHR) {
      const emp = await prisma.employee.findFirst({
        where: {
          OR: [
            { user_id: req.user.id },
            { email: { equals: req.user.email, mode: "insensitive" } },
            ...(req.user.employee_code ? [{ employee_id: req.user.employee_code }] : []),
          ],
        },
        select: { id: true },
      });
      if (emp) {
        managerEmployeeId = emp.id;
      }
    }

    const employeeWhere: Record<string, unknown> = {};
    if (isManager && !isAdminOrHR && managerEmployeeId) {
      employeeWhere.manager_id = managerEmployeeId;
    }

    const totalEmployees = await prisma.employee.count({ where: employeeWhere });
    const activeEmployees = await prisma.employee.count({
      where: { ...employeeWhere, status: "Active" },
    });

    /**
     * Compute real-time staff on approved leave today
     */
    const activeLeavesToday = await prisma.leave.findMany({
      where: {
        status: "Approved",
        start_date: { lte: todayDate },
        end_date: { gte: todayDate },
        ...(isManager && !isAdminOrHR && managerEmployeeId
          ? { employee: { manager_id: managerEmployeeId } }
          : {}),
      },
      select: { employee_id: true },
    });
    const onLeaveToday = new Set(activeLeavesToday.map((l) => l.employee_id)).size;

    const pendingLeaves = await prisma.leave.count({
      where: {
        status: "Pending",
        ...(isManager && !isAdminOrHR && managerEmployeeId
          ? { employee: { manager_id: managerEmployeeId } }
          : {}),
      },
    });

    const activeCandidates =
      isManager && !isAdminOrHR ? 0 : await prisma.candidate.count({ where: { status: "Active" } });

    const attendanceWhere: Record<string, unknown> = {
      record_id: { contains: todayStr },
    };
    if (isManager && !isAdminOrHR && managerEmployeeId) {
      attendanceWhere.employee = { manager_id: managerEmployeeId };
    }

    const todayAttendance = await prisma.attendance.findMany({
      where: attendanceWhere,
      include: { employee: true },
    });

    const onTimeCount = todayAttendance.filter(
      (a) => a.status === "Present" || (a.check_in && a.status !== "Absent" && a.status !== "Late"),
    ).length;
    const lateCount = todayAttendance.filter((a) => a.status === "Late").length;
    const explicitAbsent = todayAttendance.filter((a) => a.status === "Absent").length;
    const recordedEmpIds = new Set(todayAttendance.map((a) => a.employee_id));
    const unrecordedCount = Math.max(0, activeEmployees - recordedEmpIds.size);
    const absentCount = explicitAbsent + unrecordedCount;
    const totalPresentPhysically = onTimeCount + lateCount;

    const activityWhere: Record<string, unknown> = {};
    if (isManager && !isAdminOrHR && managerEmployeeId) {
      activityWhere.employee = { manager_id: managerEmployeeId };
    }

    const activities = await prisma.activityLog.findMany({
      where: activityWhere,
      orderBy: { created_at: "desc" },
      take: 5,
    });

    const allEmployees = await prisma.employee.findMany({
      where: {
        ...employeeWhere,
        status: "Active",
      },
      include: {
        role_rel: true,
        department_rel: true,
        shift_rel: true,
      },
    });

    const formattedActivities = activities.map((act) => {
      const timeStr = formatRelativeTime(act.created_at);
      let coreDescription = act.subtext;
      if (coreDescription.includes(" • ")) {
        coreDescription = coreDescription.split(" • ")[0];
      }

      const cleanName = act.name.replace(/\s*\([^)]*\)/g, "").trim();

      return {
        id: act.id,
        initials: act.initials || cleanName.charAt(0).toUpperCase(),
        name: cleanName,
        subtext: `${coreDescription} • ${timeStr}`,
        diff: coreDescription,
        time_ago: timeStr,
        status_label: act.status_label,
        status_type: act.status_type as "success" | "warning" | "error" | "info",
        bg_alpha: act.bg_alpha || "rgba(0, 177, 216, 0.1)",
        created_at: act.created_at.toISOString(),
      };
    });

    /** Compute Monday and Sunday boundaries for the current week in IST */
    const nowIST = new Date(new Date().toLocaleString("en-US", { timeZone: "Asia/Kolkata" }));
    const dayOfWeek = nowIST.getDay();
    const diffToMonday = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
    const weekStart = new Date(
      Date.UTC(nowIST.getFullYear(), nowIST.getMonth(), nowIST.getDate() + diffToMonday),
    );
    const weekEnd = new Date(
      Date.UTC(nowIST.getFullYear(), nowIST.getMonth(), nowIST.getDate() + diffToMonday + 7),
    );

    const employeeIds = allEmployees.map((e) => e.id);
    const weeklyAttendance = await prisma.attendance.findMany({
      where: {
        employee_id: { in: employeeIds },
        date: { gte: weekStart, lt: weekEnd },
        work_hours: { not: null },
      },
      select: { employee_id: true, work_hours: true },
    });

    /** Group total minutes per employee */
    const weeklyMinutesMap = new Map<number, number>();
    for (const record of weeklyAttendance) {
      const prev = weeklyMinutesMap.get(record.employee_id) ?? 0;
      weeklyMinutesMap.set(record.employee_id, prev + parseWorkHoursToMinutes(record.work_hours));
    }

    /**
     * Number of working days elapsed so far this week (Mon–today, max 5).
     * Used as the denominator for expected hours.
     */
    const elapsedWorkDays = Math.min(dayOfWeek === 0 ? 5 : dayOfWeek, 5);

    const allPerformers = allEmployees.map((emp) => {
      const actualMins = weeklyMinutesMap.get(emp.id) ?? 0;

      /** Derive expected daily minutes from the employee's assigned shift */
      let expectedDailyMins = 8 * 60;
      if (emp.shift_rel) {
        const startMins = parseShiftMinutes(emp.shift_rel.start_time);
        const endMins = parseShiftMinutes(emp.shift_rel.end_time);
        const shiftDuration =
          endMins > startMins ? endMins - startMins : 24 * 60 - startMins + endMins;
        const graceMins = emp.shift_rel.grace_mins ?? 0;
        expectedDailyMins = Math.max(shiftDuration - graceMins, 1);
      }

      const expectedWeeklyMins = expectedDailyMins * elapsedWorkDays;
      const performancePct =
        expectedWeeklyMins > 0
          ? Math.min(Math.round((actualMins / expectedWeeklyMins) * 100), 100)
          : 0;

      return {
        name: emp.name,
        role: emp.role_rel?.name || "Staff",
        department: emp.department_rel?.name || null,
        join_date: emp.join_date.toISOString().split("T")[0],
        weekly_hours: formatMinutesToHours(actualMins),
        performance_pct: performancePct,
        actualMins,
        avatar: emp.avatar || undefined,
      };
    });

    const formattedPerformers = allPerformers
      .sort((a, b) => {
        if (b.performance_pct !== a.performance_pct) {
          return b.performance_pct - a.performance_pct;
        }
        return b.actualMins - a.actualMins;
      })
      .slice(0, 4)
      .map(({ actualMins, ...rest }) => rest);

    const activeEmpsData = await prisma.employee.findMany({
      where: { status: "Active" },
      select: {
        id: true,
        name: true,
        avatar: true,
        birth_date: true,
        join_date: true,
        role_rel: { select: { name: true } },
      },
    });

    const celebrations: any[] = [];
    activeEmpsData.forEach((e) => {
      if (
        e.birth_date &&
        e.birth_date.getDate() === todayDate.getDate() &&
        e.birth_date.getMonth() === todayDate.getMonth()
      ) {
        celebrations.push({
          type: "Birthday",
          employee_id: e.id,
          name: e.name,
          role: e.role_rel?.name || "Staff",
          avatar: e.avatar,
        });
      }

      if (
        e.join_date &&
        e.join_date.getDate() === todayDate.getDate() &&
        e.join_date.getMonth() === todayDate.getMonth() &&
        e.join_date.getFullYear() < todayDate.getFullYear()
      ) {
        const years = todayDate.getFullYear() - e.join_date.getFullYear();
        celebrations.push({
          type: "Work Anniversary",
          years: years,
          employee_id: e.id,
          name: e.name,
          role: e.role_rel?.name || "Staff",
          avatar: e.avatar,
        });
      }
    });

    let smartInsights: any = null;
    if (req.user?.employee_db_id) {
      try {
        const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY || "" });
        const employee = await prisma.employee.findUnique({
          where: { id: req.user.employee_db_id },
          include: {
            leave_balances: {
              include: { leave_type_rel: { select: { name: true } } },
              where: { year: new Date().getFullYear() },
            },
            attendance: { take: 30, orderBy: { date: "desc" } },
          },
        });
        if (employee) {
          const leaveInfo = employee.leave_balances
            .map((lb) => `${lb.leave_type_rel?.name ?? "Leave"}: ${lb.remaining} remaining`)
            .join(", ");

          const lateDays = employee.attendance.filter(
            (a) => a.status?.toUpperCase() === "LATE",
          ).length;
          const absentDays = employee.attendance.filter(
            (a) => a.status?.toUpperCase() === "ABSENT",
          ).length;
          const presentDays = employee.attendance.filter(
            (a) => a.status?.toUpperCase() === "PRESENT",
          ).length;

          const contextBlock = `
Leave Balances: ${leaveInfo || "None"}
Last 30 Days Attendance: ${presentDays} Present, ${lateDays} Late, ${absentDays} Absent.
`;
          const systemInstruction = `
You are an AI Assistant for an HR app.
Analyze the employee's data and provide a short personalized summary and 1-3 suggestions (reminders, warnings, or tips).
If there is no significant HR data to report on, or just as a friendly touch, provide general workplace wellness tips.
Output strictly in JSON format matching this schema:
{
  "summary": "Short 1-2 sentence friendly summary of their current status",
  "suggestions": [
    { "type": "reminder" | "warning" | "info" | "success", "message": "The suggestion text" }
  ]
}
No markdown formatting, just pure JSON.
`.trim();

          const response = await ai.models.generateContent({
            model: "gemini-flash-lite-latest",
            contents: `Employee Data:\n${contextBlock}`,
            config: { systemInstruction, responseMimeType: "application/json" },
          });

          const text = response.text ?? "{}";
          const cleanJson = text
            .replace(/```json/gi, "")
            .replace(/```/g, "")
            .trim();
          smartInsights = JSON.parse(cleanJson);
        }
      } catch (e) {
        console.error("Failed to fetch smart insights inside dashboard API:", e);
      }
    }

    const overview = {
      kpi_metrics: {
        total_employees: totalEmployees,
        active_workforce: activeEmployees,
        present_today: totalPresentPhysically,
        absent_today: absentCount,
        late_today: lateCount,
        on_leave_today: onLeaveToday,
        pending_leaves: pendingLeaves,
        active_candidates: activeCandidates,
      },
      attendance: {
        present: onTimeCount,
        absent: absentCount,
        late: lateCount,
        on_leave: onLeaveToday,
        total: totalEmployees,
      },
      pending_leaves: pendingLeaves,
      recent_activities: formattedActivities,
      top_performers: formattedPerformers,
      celebrations: celebrations,
      smart_insights: smartInsights,
    };

    res.sendSuccess({
      message: "Dashboard overview fetched successfully",
      data: overview,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Controller to fetch all activity logs with search and pagination support
 *
 * @param req - Express request with optional query params
 * @param res - Express response
 * @param next - Next middleware delegate
 */
export const getAllActivities = async (
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  try {
    const limit = Math.min(Number(req.query.limit) || 50, 100);
    const search = (req.query.search as string) || "";

    const andConditions: Array<Record<string, unknown>> = [];

    const userRole = (req.user?.role || "").toLowerCase();
    const isManager = userRole.includes("manager");
    const isAdminOrHR = userRole.includes("admin") || userRole.includes("hr");

    let managerEmployeeId = req.user?.employee_db_id;
    if (!managerEmployeeId && req.user?.id && isManager && !isAdminOrHR) {
      const emp = await prisma.employee.findFirst({
        where: {
          OR: [
            { user_id: req.user.id },
            { email: { equals: req.user.email, mode: "insensitive" } },
            ...(req.user.employee_code ? [{ employee_id: req.user.employee_code }] : []),
          ],
        },
        select: { id: true },
      });
      if (emp) {
        managerEmployeeId = emp.id;
      }
    }

    if (isManager && !isAdminOrHR && managerEmployeeId) {
      andConditions.push({
        employee: { manager_id: managerEmployeeId },
      });
    }

    if (search.trim()) {
      andConditions.push({
        OR: [
          { name: { contains: search, mode: "insensitive" } },
          { subtext: { contains: search, mode: "insensitive" } },
          { status_label: { contains: search, mode: "insensitive" } },
        ],
      });
    }

    const whereClause = andConditions.length > 0 ? { AND: andConditions } : {};

    const activities = await prisma.activityLog.findMany({
      where: whereClause,
      orderBy: { created_at: "desc" },
      take: limit,
    });

    const formatted = activities.map((act) => {
      const timeStr = formatRelativeTime(act.created_at);
      let coreDescription = act.subtext;
      if (coreDescription.includes(" • ")) {
        coreDescription = coreDescription.split(" • ")[0];
      }

      const cleanName = act.name.replace(/\s*\([^)]*\)/g, "").trim();

      return {
        id: act.id,
        initials: act.initials || cleanName.charAt(0).toUpperCase(),
        name: cleanName,
        subtext: `${coreDescription} • ${timeStr}`,
        diff: coreDescription,
        time_ago: timeStr,
        status_label: act.status_label,
        status_type: act.status_type as "success" | "warning" | "error" | "info",
        bg_alpha: act.bg_alpha || "rgba(0, 177, 216, 0.1)",
        created_at: act.created_at.toISOString(),
      };
    });

    res.sendSuccess({
      message: "Activity logs fetched successfully",
      data: formatted,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Controller to fetch real monthly workforce growth data for the current year
 *
 * @param _req - Express request
 * @param res - Express response
 * @param next - Next middleware delegate
 */
export const getWorkforceTrend = async (
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  try {
    const userRole = (req.user?.role || "").toLowerCase();
    const isManager = userRole.includes("manager");
    const isAdminOrHR = userRole.includes("admin") || userRole.includes("hr");

    let managerEmployeeId = req.user?.employee_db_id;
    if (!managerEmployeeId && req.user?.id && isManager && !isAdminOrHR) {
      const emp = await prisma.employee.findFirst({
        where: {
          OR: [
            { user_id: req.user.id },
            { email: { equals: req.user.email, mode: "insensitive" } },
            ...(req.user.employee_code ? [{ employee_id: req.user.employee_code }] : []),
          ],
        },
        select: { id: true },
      });
      if (emp) {
        managerEmployeeId = emp.id;
      }
    }

    const employeeWhere: Record<string, unknown> = {};
    if (isManager && !isAdminOrHR && managerEmployeeId) {
      employeeWhere.manager_id = managerEmployeeId;
    }

    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth() + 1;

    const MONTH_LABELS = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    const allEmployees = await prisma.employee.findMany({
      where: employeeWhere,
      select: { created_at: true },
      orderBy: { created_at: "asc" },
    });

    /**
     * Build a cumulative headcount snapshot per month of the current year.
     * An employee hired before month M still counts toward M's total.
     */
    const trend = MONTH_LABELS.map((label, idx) => {
      const month = idx + 1;
      const monthEnd = new Date(Date.UTC(currentYear, month, 1));
      const count = allEmployees.filter((e) => new Date(e.created_at) < monthEnd).length;

      return { name: label, employees: count };
    });

    res.sendSuccess({
      message: "Workforce trend fetched successfully",
      data: trend,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Send a push notification wish to an employee
 */
export const sendWish = async (req: Request, res: Response) => {
  try {
    const { employee_id, message } = req.body;
    if (!employee_id || !message) {
      return res.status(400).json({ status: "error", message: "Missing employee_id or message" });
    }

    const employee = await prisma.employee.findUnique({
      where: { id: employee_id },
    });

    if (!employee || !employee.user_id) {
      return res
        .status(404)
        .json({ status: "error", message: "Employee or associated user not found" });
    }

    const targetUser = await prisma.user.findUnique({
      where: { id: employee.user_id },
    });

    if (!targetUser || !targetUser.fcm_token) {
      return res
        .status(404)
        .json({
          status: "error",
          message: "Target user does not have a registered device for notifications.",
        });
    }

    const { sendPushNotification } = require("../../libraries/firebase");
    const success = await sendPushNotification(targetUser.fcm_token, "New Wish! 🎉", message, {
      route: "/celebrations",
    });

    if (success) {
      return res.json({ status: "success", message: "Wish sent successfully!" });
    } else {
      return res.status(500).json({ status: "error", message: "Failed to send push notification" });
    }
  } catch (error) {
    console.error("Error sending wish:", error);
    return res.status(500).json({ status: "error", message: "Internal server error" });
  }
};
