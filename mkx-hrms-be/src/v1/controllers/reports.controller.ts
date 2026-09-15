import { Request, Response, NextFunction } from "express";
import { prisma } from "../../libraries/prisma";

/**
 * Controller to retrieve generated analytics reports
 *
 * @param _req - Express request
 * @param res - Express response
 * @param next - Next middleware delegate
 */
export const getReports = async (
  _req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  try {
    const reports = await prisma.report.findMany({
      orderBy: { created_at: "desc" },
    });

    const formatted = reports.map((r) => ({
      id: r.report_code,
      title: r.title,
      category: r.category,
      date: r.date.toISOString().split("T")[0],
      status: r.status,
    }));

    res.sendSuccess({
      message: "Reports fetched successfully",
      data: formatted,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Controller to fetch dynamic analytical charts and trend data
 *
 * @param _req - Express request
 * @param res - Express response
 * @param next - Next middleware delegate
 */
export const getReportAnalytics = async (
  _req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  try {
    /** 1. Summary Cards Data */
    const totalEmployees = await prisma.employee.count({
      where: { status: "Active" },
    });

    const inactiveEmployees = await prisma.employee.count({
      where: { status: "Inactive" },
    });

    const totalAllTime = totalEmployees + inactiveEmployees;
    const retentionRate =
      totalAllTime > 0 ? `${((totalEmployees / totalAllTime) * 100).toFixed(1)}%` : "0.0%";

    /** Pending Leaves Calculation (Replaces Time to Hire) */
    const pendingLeaves = await prisma.leave.count({
      where: { status: "Pending" }
    });
    
    /** Monthly Compensation Calculation */
    const payrollRecords = await prisma.payroll.findMany();
    const totalMonthlyCompensation = payrollRecords.reduce(
      (acc, curr) => acc + Number(curr.net_pay || 0),
      0,
    );
    const compensationStr =
      totalMonthlyCompensation > 0 ? `₹${(totalMonthlyCompensation / 1000).toFixed(1)}k` : "₹0";

    /** 2. Headcount Growth & Retention Trend (Last 6 Months) */
    const months = [];
    const now = new Date();
    const monthNames = [
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
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      months.push({
        label: monthNames[d.getMonth()],
        year: d.getFullYear(),
        monthIndex: d.getMonth(),
        endOfDate: new Date(d.getFullYear(), d.getMonth() + 1, 0, 23, 59, 59),
      });
    }

    const allEmployees = await prisma.employee.findMany({
      select: {
        join_date: true,
        status: true,
        department_rel: { select: { name: true } },
      },
    });

    /** Dynamically collect all unique department names for the chart keys */
    const allDeptKeys = new Set<string>();
    allEmployees.forEach((emp) => {
      const deptName = emp.department_rel?.name?.toLowerCase().replace(/[^a-z0-9]/g, "") || "other";
      allDeptKeys.add(deptName);
    });

    const headcount_growth = months.map((m) => {
      const entry: Record<string, any> = { month: m.label };
      allDeptKeys.forEach((k) => {
        entry[k] = 0;
      });

      allEmployees.forEach((emp) => {
        const deptName =
          emp.department_rel?.name?.toLowerCase().replace(/[^a-z0-9]/g, "") || "other";
        if (emp.join_date <= m.endOfDate) {
          entry[deptName] += 1;
        }
      });
      return entry;
    });

    const retention_trend = months.map((m) => {
      const totalTillMonth = allEmployees.filter((e) => e.join_date <= m.endOfDate).length;
      const inactiveTillMonth = allEmployees.filter(
        (e) => e.join_date <= m.endOfDate && e.status === "Inactive",
      ).length;
      const activeTillMonth = totalTillMonth - inactiveTillMonth;
      const rate = totalTillMonth > 0 ? (activeTillMonth / totalTillMonth) * 100 : 0;
      return { month: m.label, rate: Number(rate.toFixed(1)) };
    });

    /** 4. Department Distribution (Replaces Recruitment Sources) */
    const activeEmployees = allEmployees.filter(e => e.status === "Active");
    const currentDeptMap: Record<string, number> = {};
    
    activeEmployees.forEach(e => {
      const dName = e.department_rel?.name || "Unassigned";
      currentDeptMap[dName] = (currentDeptMap[dName] || 0) + 1;
    });
    
    const colors = ["#00b1d8", "#45ba50", "#ff8b25", "#ad87ed", "#f43f5e", "#8b5cf6"];
    const department_distribution = Object.keys(currentDeptMap).map((name, i) => ({
      name,
      value: currentDeptMap[name],
      color: colors[i % colors.length],
    }));

    /** 5. Department Compensation (Using recent payrolls approx) */
    const payrollsWithDept = await prisma.payroll.findMany({
      include: {
        employee: {
          include: { department_rel: true },
        },
      },
    });

    const deptCompMap: Record<string, number> = {};
    payrollsWithDept.forEach((p) => {
      const dName = p.employee?.department_rel?.name || "Unassigned";
      deptCompMap[dName] = (deptCompMap[dName] || 0) + Number(p.net_pay || 0);
    });

    const department_compensation = Object.keys(deptCompMap)
      .map((dept) => {
        const current = deptCompMap[dept];
        return {
          dept,
          current,
          budget: Math.round(current * 1.1),
        };
      })
      .sort((a, b) => b.current - a.current)
      .slice(0, 5);

    const data = {
      summary_cards: [
        {
          id: "headcount",
          title: "Total Headcount",
          value: String(totalEmployees),
          change: "Dynamic active count",
          positive: true,
          icon_color: "text-[#00b1d8]",
          icon_bg: "bg-[#00b1d8]/10",
        },
        {
          id: "retention",
          title: "Retention Rate",
          value: retentionRate,
          change: "Dynamic calculated rate",
          positive: true,
          icon_color: "text-[#45ba50]",
          icon_bg: "bg-[#45ba50]/10",
        },
        {
          id: "leave-requests",
          title: "Active Leave Requests",
          value: String(pendingLeaves),
          change: "Pending approvals",
          positive: pendingLeaves === 0,
          icon_color: "text-[#ff8b25]",
          icon_bg: "bg-[#ff8b25]/10",
        },
        {
          id: "compensation",
          title: "Monthly Compensation",
          value: compensationStr,
          change: "Based on active base salaries",
          positive: false,
          icon_color: "text-[#ad87ed]",
          icon_bg: "bg-[#ad87ed]/10",
        },
      ],
      headcount_growth,
      retention_trend,
      department_distribution,
      department_compensation,
    };

    res.sendSuccess({
      message: "Analytics data fetched successfully",
      data,
    });
  } catch (err) {
    next(err);
  }
};
