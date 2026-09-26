import { Request, Response, NextFunction } from "express";
import { ZodType, ZodError } from "zod";
import { ApiError } from "../utils/ApiError";

/**
 * Express middleware to validate request payloads against a Zod schema.
 *
 * Supports validating `body`, `query`, and `params`.
 * If validation fails, it throws a 400 Bad Request ApiError with formatted issues.
 *
 * @param schema - Zod schema to validate against
 * @returns Express middleware function
 */
export const validate = (schema: ZodType<unknown>) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      const parsed = schema.parse({
        body: req.body,
        query: req.query,
        params: req.params,
      }) as { body?: unknown; query?: unknown; params?: unknown };

      if (parsed.body !== undefined) req.body = parsed.body;
      if (parsed.query !== undefined) {
        Object.defineProperty(req, "query", {
          value: parsed.query,
          writable: true,
          configurable: true,
          enumerable: true,
        });
      }
      if (parsed.params !== undefined) {
        Object.defineProperty(req, "params", {
          value: parsed.params,
          writable: true,
          configurable: true,
          enumerable: true,
        });
      }

      next();
    } catch (err) {
      if (err instanceof ZodError) {
        const errorMessages = err.issues.map((e) => `${e.path.join(".")} - ${e.message}`);
        next(new ApiError(400, `Validation Error: ${errorMessages.join(" | ")}`));
      } else {
        next(err);
      }
    }
  };
};
