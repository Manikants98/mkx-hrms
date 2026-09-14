import { Request, Response, NextFunction } from "express";
import { prisma } from "../../libraries/prisma";

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
  _req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  try {
    const todayStr = new Date().toLocaleDateString("en-CA", { timeZone: "Asia/Kolkata" });
    const todayDate = new Date(`${todayStr}T00:00:00.000Z`);

    const totalEmployees = await prisma.employee.count();
    const activeEmployees = await prisma.employee.count({
      where: { status: "Active" },
    });

    /**
     * Compute real-time staff on approved leave today
     */
    const activeLeavesToday = await prisma.leave.findMany({
      where: {
        status: "Approved",
        start_date: { lte: todayDate },
        end_date: { gte: todayDate },
      },
      select: { employee_id: true },
    });
    const onLeaveToday = new Set(activeLeavesToday.map((l) => l.employee_id)).size;
    const activeCandidates = await prisma.candidate.count({ where: { status: "Active" } });

    const activities = await prisma.activityLog.findMany({
      orderBy: { created_at: "desc" },
      take: 5,
    });

    const topEmployees = await prisma.employee.findMany({
      where: { status: "Active" },
      take: 4,
      orderBy: { created_at: "asc" },
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

      return {
        id: act.id,
        initials: act.initials || act.name.charAt(0).toUpperCase(),
        name: act.name,
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

    const employeeIds = topEmployees.map((e) => e.id);
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

    const formattedPerformers = topEmployees.map((emp) => {
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
        avatar: emp.avatar || undefined,
      };
    });

    const overview = {
      kpi_metrics: {
        total_employees: totalEmployees,
        active_workforce: activeEmployees,
        on_leave_today: onLeaveToday,
        active_candidates: activeCandidates,
      },
      recent_activities: formattedActivities,
      top_performers: formattedPerformers,
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

      return {
        id: act.id,
        initials: act.initials || act.name.charAt(0).toUpperCase(),
        name: act.name,
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
  _req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  try {
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
      select: { created_at: true },
      orderBy: { created_at: "asc" },
    });

    /**
     * Build a cumulative headcount snapshot per month of the current year.
     * An employee hired before month M still counts toward M's total.
     */
    const trend = MONTH_LABELS.slice(0, currentMonth).map((label, idx) => {
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
