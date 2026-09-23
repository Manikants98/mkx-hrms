import { Request, Response, NextFunction } from "express";
import { prisma } from "../libraries/prisma";
import { verifyToken } from "../v1/services/auth.service";

/**
 * Snapshot model for tracking pre-mutation state of database entities
 */
interface EntitySnapshot {
  id?: number | string;
  name?: string;
  title?: string;
  status?: string;
  role?: string;
  department?: string;
  stage?: string;
  manager_name?: string;
  email?: string;
  leave_type?: string;
  author_name?: string;
  category?: string;
  employee_id?: number | null;
  user_id?: number | null;
  employee?: { name?: string; id?: number } | null;
}

/**
 * Helper to compute two-letter uppercase initials from a full name
 *
 * @param name - Full name or label
 * @returns Initials string
 */
function extractInitials(name: string): string {
  const clean = name.replace(/\([^)]*\)/g, "").trim();
  const parts = clean.split(/\s+/).filter(Boolean);
  if (parts.length === 0) return "HR";
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

/**
 * Middleware to intercept modifying HTTP requests and track entity changes
 *
 * @param req - Express request
 * @param res - Express response
 * @param next - Next middleware delegate
 */
export const activityTrackingMiddleware = async (
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  const method = req.method.toUpperCase();

  if (!["POST", "PUT", "PATCH", "DELETE"].includes(method)) {
    return next();
  }

  const rawUrl = req.originalUrl || req.url;
  const pathWithoutQuery = rawUrl.split("?")[0];

  if (
    pathWithoutQuery.includes("/export") ||
    pathWithoutQuery.includes("/health") ||
    pathWithoutQuery.includes("/auth/login") ||
    pathWithoutQuery.includes("/auth/logout")
  ) {
    return next();
  }

  let snapshot: EntitySnapshot | null = null;
  const segments = pathWithoutQuery.split("/").filter(Boolean);
  const lastSegment = segments[segments.length - 1];
  const secondLastSegment = segments.length > 1 ? segments[segments.length - 2] : "";

  const targetId = !isNaN(Number(lastSegment))
    ? Number(lastSegment)
    : lastSegment === "status" && !isNaN(Number(secondLastSegment))
      ? Number(secondLastSegment)
      : lastSegment;

  const idStr = String(targetId);
  const numericId = !isNaN(Number(targetId)) ? Number(targetId) : undefined;

  try {
    if (
      pathWithoutQuery.includes("/employees") &&
      (method === "PUT" || method === "PATCH" || method === "DELETE")
    ) {
      const emp = await prisma.employee.findFirst({
        where: {
          OR: [...(numericId ? [{ id: numericId }] : []), { employee_id: idStr }],
        },
        include: {
          role_rel: true,
          department_rel: true,
          manager: true,
        },
      });
      if (emp) {
        snapshot = {
          id: emp.id,
          name: emp.name,
          status: emp.status,
          role: emp.role_rel?.name,
          department: emp.department_rel?.name,
          manager_name: emp.manager?.name || undefined,
          email: emp.email,
          employee_id: emp.id,
          user_id: emp.user_id,
        };
      }
    } else if (
      pathWithoutQuery.includes("/leaves") &&
      (method === "PUT" || method === "PATCH" || method === "DELETE")
    ) {
      const leave = await prisma.leave.findFirst({
        where: {
          OR: [...(numericId ? [{ id: numericId }] : []), { leave_code: idStr }],
        },
        include: { employee: true, leave_type_rel: true },
      });
      if (leave) {
        snapshot = {
          id: leave.id,
          status: leave.status,
          leave_type: leave.leave_type_rel?.name,
          employee_id: leave.employee_id,
          employee: { name: leave.employee?.name, id: leave.employee?.id },
        };
      }
    } else if (
      pathWithoutQuery.includes("/recruitment") &&
      (method === "PUT" ||
        method === "PATCH" ||
        method === "DELETE" ||
        pathWithoutQuery.includes("/onboard"))
    ) {
      const candidate = await prisma.candidate.findFirst({
        where: {
          OR: [...(numericId ? [{ id: numericId }] : []), { candidate_code: idStr }],
        },
      });
      if (candidate) {
        snapshot = {
          id: candidate.id,
          name: candidate.name,
          stage: candidate.stage,
          status: candidate.status,
          role: candidate.position,
          department: candidate.department,
          employee_id: candidate.employee_id,
        };
      }
    } else if (
      pathWithoutQuery.includes("/blogs") &&
      (method === "PUT" || method === "PATCH" || method === "DELETE")
    ) {
      const blog = await prisma.blogPost.findFirst({
        where: {
          OR: [...(numericId ? [{ id: numericId }] : []), { slug: idStr }],
        },
      });
      if (blog) {
        snapshot = {
          id: blog.id,
          title: blog.title,
          status: blog.status,
          category: blog.category,
          author_name: blog.author_name,
        };
      }
    }
  } catch {
    /** Gracefully bypass snapshot errors */
  }

  res.on("finish", async () => {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      return;
    }

    try {
      let actorUserId: number | null = req.user?.id || null;
      let actorEmployeeId: number | null = req.user?.employee_db_id || null;
      let actorName: string = req.user?.name || "";

      const authHeader = req.headers.authorization;
      if (!actorUserId && authHeader && authHeader.startsWith("Bearer ")) {
        const token = authHeader.split(" ")[1];
        const decoded = verifyToken(token);
        if (decoded?.id) {
          actorUserId = decoded.id;
          actorName = decoded.name || "";
          actorEmployeeId = decoded.employee_db_id || null;
        }
      }

      if ((!actorName || !actorEmployeeId) && actorUserId) {
        const user = await prisma.user.findUnique({
          where: { id: actorUserId },
          include: { employee: true },
        });
        if (user) {
          actorName = actorName || user.employee?.name || (user.first_name ? `${user.first_name} ${user.last_name}`.trim() : null) || "User";
          actorEmployeeId = actorEmployeeId || user.employee?.id || null;
        }
      }

      const body = req.body && typeof req.body === "object" ? req.body : {};
      let name = actorName || "System";
      let subtext = "Action completed";
      let statusLabel = "Updated";
      let statusType: "success" | "warning" | "error" | "info" = "info";
      let bgAlpha = "rgba(0, 177, 216, 0.1)";

      if (pathWithoutQuery.includes("/employees")) {
        if (method === "POST") {
          const empName =
            body.name ||
            [body.first_name, body.last_name].filter(Boolean).join(" ") ||
            "New Employee";
          name = `${empName} (Employee)`;
          subtext = `New Hire • ${body.department || "Organization"} (${body.role || "Staff"})`;
          statusLabel = "New Hire";
          statusType = "success";
          bgAlpha = "rgba(69, 186, 80, 0.1)";
        } else if (method === "PUT" || method === "PATCH") {
          const empName = snapshot?.name || body.name || "Employee";
          name = `${empName} (Employee)`;
          const diffs: string[] = [];

          if (snapshot && body.status && body.status !== snapshot.status) {
            diffs.push(`Status: "${snapshot.status}" → "${body.status}"`);
          }
          if (snapshot && body.role && body.role !== snapshot.role) {
            diffs.push(`Role: "${snapshot.role}" → "${body.role}"`);
          }
          if (snapshot && body.department && body.department !== snapshot.department) {
            diffs.push(`Department: "${snapshot.department}" → "${body.department}"`);
          }
          if (snapshot && body.manager_name && body.manager_name !== snapshot.manager_name) {
            diffs.push(`Manager: "${snapshot.manager_name}" → "${body.manager_name}"`);
          }
          if (diffs.length === 0) {
            diffs.push("Updated employee profile records");
          }

          subtext = diffs.join(", ");
          statusLabel = (body.status as string) || "Updated";
          if (body.status === "Inactive") {
            statusType = "error";
            bgAlpha = "rgba(241, 77, 76, 0.1)";
          } else if (body.status === "Active") {
            statusType = "success";
            bgAlpha = "rgba(69, 186, 80, 0.1)";
          } else {
            statusType = "info";
            bgAlpha = "rgba(0, 177, 216, 0.1)";
          }
        } else if (method === "DELETE") {
          const empName = snapshot?.name || "Employee";
          name = `${empName} (Employee)`;
          subtext = "Removed from active workforce directory";
          statusLabel = "Deleted";
          statusType = "error";
          bgAlpha = "rgba(241, 77, 76, 0.1)";
        }
      } else if (pathWithoutQuery.includes("/attendance")) {
        if (pathWithoutQuery.includes("/punch")) {
          const empName = actorName || snapshot?.name || body.employee_name || "Employee";
          name = `${empName} (Attendance)`;
          const punchType = (body.type || body.punch_type || "").toString().toLowerCase();
          const isOut = punchType.includes("out");
          subtext = isOut ? "Clocked out for the shift" : "Clocked in for shift";
          statusLabel = isOut ? "Clock Out" : "Clock In";
          statusType = isOut ? "warning" : "success";
          bgAlpha = isOut ? "rgba(255, 139, 37, 0.1)" : "rgba(16, 185, 129, 0.1)";
        } else if (pathWithoutQuery.includes("/generate-daily")) {
          const opName = actorName || "HR Admin";
          name = `${opName} (Attendance)`;
          subtext = "Generated daily attendance logs for active workforce";
          statusLabel = "Generated";
          statusType = "info";
          bgAlpha = "rgba(0, 177, 216, 0.1)";
        } else {
          const empName = snapshot?.employee?.name || snapshot?.name || actorName || "Employee";
          name = `${empName} (Attendance)`;
          subtext = `Updated attendance records (${method} ${pathWithoutQuery})`;
          statusLabel = method === "POST" ? "Created" : method === "DELETE" ? "Deleted" : "Updated";
          statusType = method === "DELETE" ? "error" : "info";
          bgAlpha = "rgba(0, 177, 216, 0.1)";
        }
      } else if (pathWithoutQuery.includes("/payroll")) {
        const opName = actorName || "HR Admin";
        name = `${opName} (Payroll)`;
        if (pathWithoutQuery.includes("/generate")) {
          subtext = "Generated payroll runs for billing cycle";
          statusLabel = "Processed";
          statusType = "success";
          bgAlpha = "rgba(16, 185, 129, 0.1)";
        } else {
          subtext = `Payroll record ${method === "POST" ? "created" : method === "DELETE" ? "deleted" : "updated"}`;
          statusLabel = method === "POST" ? "Created" : method === "DELETE" ? "Deleted" : "Updated";
          statusType = method === "DELETE" ? "error" : "info";
          bgAlpha = "rgba(0, 177, 216, 0.1)";
        }
      } else if (pathWithoutQuery.includes("/leaves")) {
        if (method === "PATCH" || method === "PUT") {
          const empName = snapshot?.employee?.name || "Employee";
          name = `${empName} (Leave Req)`;
          const oldStatus = snapshot?.status || "Pending";
          const newStatus = (body.status as string) || "Updated";
          subtext = `Status: "${oldStatus}" → "${newStatus}" (${snapshot?.leave_type || "Leave"})`;
          statusLabel = newStatus;
          if (newStatus === "Approved") {
            statusType = "success";
            bgAlpha = "rgba(69, 186, 80, 0.1)";
          } else if (newStatus === "Rejected") {
            statusType = "error";
            bgAlpha = "rgba(241, 77, 76, 0.1)";
          } else {
            statusType = "warning";
            bgAlpha = "rgba(255, 139, 37, 0.1)";
          }
        } else if (method === "POST") {
          name = `${body.employee_name || actorName || "Employee"} (Leave Req)`;
          subtext = `Requested ${body.leave_type || "Annual"} leave (${body.days_count || 1} days)`;
          statusLabel = "Pending";
          statusType = "warning";
          bgAlpha = "rgba(255, 139, 37, 0.1)";
        }
      } else if (pathWithoutQuery.includes("/recruitment")) {
        if (pathWithoutQuery.includes("/onboard")) {
          const candName = snapshot?.name || body.name || "Candidate";
          name = `${candName} (Onboarding)`;
          subtext = `Hired into workforce as ${snapshot?.role || body.role || "Employee"}`;
          statusLabel = "Hired";
          statusType = "success";
          bgAlpha = "rgba(69, 186, 80, 0.1)";
        } else if (method === "POST") {
          const candName = body.name || "Candidate";
          name = `${candName} (Candidate)`;
          subtext = `Applied for ${body.position || "Role"} • ${body.department || "Operations"}`;
          statusLabel = "Applied";
          statusType = "info";
          bgAlpha = "rgba(0, 177, 216, 0.1)";
        } else if (method === "PUT" || method === "PATCH") {
          const candName = snapshot?.name || body.name || "Candidate";
          name = `${candName} (Candidate)`;
          const diffs: string[] = [];
          if (snapshot && body.stage && body.stage !== snapshot.stage) {
            diffs.push(`Stage: "${snapshot.stage}" → "${body.stage}"`);
          }
          if (snapshot && body.status && body.status !== snapshot.status) {
            diffs.push(`Status: "${snapshot.status}" → "${body.status}"`);
          }
          if (diffs.length === 0) diffs.push("Updated candidate application");
          subtext = diffs.join(", ");
          statusLabel = (body.stage as string) || (body.status as string) || "Updated";
          statusType =
            statusLabel === "Hired" ? "success" : statusLabel === "Rejected" ? "error" : "info";
          bgAlpha =
            statusType === "success"
              ? "rgba(69, 186, 80, 0.1)"
              : statusType === "error"
                ? "rgba(241, 77, 76, 0.1)"
                : "rgba(0, 177, 216, 0.1)";
        }
      } else if (pathWithoutQuery.includes("/blogs")) {
        if (method === "POST") {
          name = `${body.author_name || actorName || "Admin"} (Blog)`;
          subtext = `Created article: "${body.title || "Untitled"}"`;
          statusLabel = (body.status as string) || "Draft";
          statusType = body.status === "Published" ? "success" : "warning";
          bgAlpha = statusType === "success" ? "rgba(69, 186, 80, 0.1)" : "rgba(255, 139, 37, 0.1)";
        } else if (method === "PUT" || method === "PATCH") {
          name = `${snapshot?.author_name || body.author_name || actorName || "Admin"} (Blog)`;
          const diffs: string[] = [];
          if (snapshot && body.status && body.status !== snapshot.status) {
            diffs.push(`Status: "${snapshot.status}" → "${body.status}"`);
          }
          if (snapshot && body.title && body.title !== snapshot.title) {
            diffs.push(`Title: "${snapshot.title}" → "${body.title}"`);
          }
          if (snapshot && body.category && body.category !== snapshot.category) {
            diffs.push(`Category: "${snapshot.category}" → "${body.category}"`);
          }
          if (diffs.length === 0) diffs.push("Updated article content");
          subtext = diffs.join(", ");
          statusLabel = (body.status as string) || snapshot?.status || "Updated";
          statusType =
            statusLabel === "Published" ? "success" : statusLabel === "Draft" ? "warning" : "info";
          bgAlpha =
            statusType === "success"
              ? "rgba(69, 186, 80, 0.1)"
              : statusType === "warning"
                ? "rgba(255, 139, 37, 0.1)"
                : "rgba(0, 177, 216, 0.1)";
        } else if (method === "DELETE") {
          name = `${snapshot?.author_name || actorName || "Admin"} (Blog)`;
          subtext = `Deleted article: "${snapshot?.title || "Article"}"`;
          statusLabel = "Deleted";
          statusType = "error";
          bgAlpha = "rgba(241, 77, 76, 0.1)";
        }
      } else {
        const actor = actorName ? `${actorName}` : "System Operation";
        name = actor;
        subtext = `${method} ${pathWithoutQuery}`;
        statusLabel = method === "DELETE" ? "Deleted" : method === "POST" ? "Created" : "Updated";
        statusType = method === "DELETE" ? "error" : "info";
        bgAlpha = "rgba(0, 177, 216, 0.1)";
      }

      const initials = extractInitials(name);

      await prisma.activityLog.create({
        data: {
          user_id: actorUserId,
          employee_id:
            actorEmployeeId || (snapshot?.employee_id ? Number(snapshot.employee_id) : null),
          initials,
          name,
          subtext: subtext.slice(0, 255),
          status_label: statusLabel.slice(0, 50),
          status_type: statusType,
          bg_alpha: bgAlpha,
        },
      });
    } catch {
      /** Fail-safe logging */
    }
  });

  next();
};
