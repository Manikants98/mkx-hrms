import { Request, Response, NextFunction } from "express";
import { verifyToken, AuthTokenPayload } from "../v1/services/auth.service";
import { prisma } from "../libraries/prisma";

/**
 * Express Request interface extension attaching authenticated user payload
 */
declare global {
  namespace Express {
    interface Request {
      user?: AuthTokenPayload;
    }
  }
}

/**
 * Ambient authentication middleware verifying Bearer JWT token from request header
 * and populating req.user if a valid token is present without blocking unauthenticated requests.
 *
 * @param req - Express request
 * @param _res - Express response
 * @param next - Next middleware delegate
 */
export const authenticateToken = async (
  req: Request,
  _res: Response,
  next: NextFunction,
): Promise<void> => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    next();
    return;
  }

  const token = authHeader.split(" ")[1];
  const decoded = verifyToken(token);

  if (!decoded || !decoded.id) {
    next();
    return;
  }

  try {
    const dbUser = await prisma.user.findUnique({
      where: { id: decoded.id },
      include: {
        role: true,
        employee: {
          include: {
            role_rel: true,
          },
        },
      },
    });

    if (dbUser) {
      let emp = dbUser.employee;
      if (!emp) {
        emp = await prisma.employee.findFirst({
          where: {
            OR: [
              { user_id: dbUser.id },
              { email: { equals: dbUser.email, mode: "insensitive" } },
              { employee_id: dbUser.employee_id },
            ],
          },
          include: { role_rel: true },
        });
      }

      const resolvedRole =
        dbUser.role?.name || emp?.role_rel?.name || decoded.role || "Employee";

      const resolvedName = emp?.name || (dbUser.first_name ? `${dbUser.first_name} ${dbUser.last_name}`.trim() : null) || decoded.name || "User";

      req.user = {
        id: dbUser.id,
        email: dbUser.email,
        name: resolvedName,
        role: resolvedRole,
        employee_db_id: emp?.id || decoded.employee_db_id,
        employee_code:
          emp?.employee_id || dbUser.employee_id || decoded.employee_code,
      };
    } else {
      req.user = decoded;
    }
  } catch (_error: unknown) {
    req.user = decoded;
  }

  next();
};

/**
 * Authentication middleware verifying Bearer JWT token from request header
 *
 * @param req - Express request
 * @param res - Express response
 * @param next - Next middleware delegate
 */
export const requireAuth = (
  req: Request,
  res: Response,
  next: NextFunction,
): void => {
  if (!req.user) {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.sendError({
        statusCode: 401,
        message: "Authorization token required",
      });
      return;
    }

    const token = authHeader.split(" ")[1];
    const decoded = verifyToken(token);

    if (!decoded) {
      res.sendError({
        statusCode: 401,
        message: "Invalid or expired token",
      });
      return;
    }

    req.user = decoded;
  }

  next();
};

