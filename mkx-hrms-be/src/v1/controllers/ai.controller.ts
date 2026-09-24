import { Request, Response } from "express";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { prisma } from "../../libraries/prisma";

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || "");

/**
 * Controller to handle Smart Assistant chat powered by Gemini.
 * It reads the authenticated user from `req.user`, fetches their live employee
 * context (name, department, leave balances, last payroll) from the database,
 * and injects that context into the Gemini system instruction so the AI can
 * answer personal HR questions accurately.
 *
 * @param req - Express request with `req.user` populated by `requireAuth`
 * @param res - Express response
 */
export const chatWithAssistant = async (
  req: Request,
  res: Response,
): Promise<void> => {
  try {
    const { prompt } = req.body as { prompt?: string };

    if (!prompt) {
      res.status(400).json({ success: false, error: "Prompt is required" });
      return;
    }

    const user = req.user;
    let contextBlock = "The employee's account details are not available.";

    if (user) {
      const employeeId = user.employee_db_id;

      if (employeeId) {
        const employee = await prisma.employee.findUnique({
          where: { id: employeeId },
          include: {
            department_rel: { select: { name: true } },
            role_rel: { select: { name: true } },
            shift_rel: { select: { name: true } },
            leave_balances: {
              include: { leave_type_rel: { select: { name: true } } },
              where: { year: new Date().getFullYear() },
            },
            payrolls: {
              orderBy: [{ year: "desc" }, { month: "desc" }],
              take: 1,
              select: {
                month: true,
                year: true,
                net_pay: true,
                gross_pay: true,
                total_deductions: true,
              },
            },
          },
        });

        if (employee) {
          const leaveInfo = employee.leave_balances
            .map(
              (lb) =>
                `- ${lb.leave_type_rel.name}: ${lb.remaining} remaining (${lb.used} used / ${lb.allocated} allocated)`,
            )
            .join("\n");

          const lastPayroll = employee.payrolls[0];
          const payrollInfo = lastPayroll
            ? `Gross: ₹${lastPayroll.gross_pay}, Deductions: ₹${lastPayroll.total_deductions}, Net: ₹${lastPayroll.net_pay} (Month: ${lastPayroll.month}/${lastPayroll.year})`
            : "No payroll record available.";

          contextBlock = `
Employee Name: ${employee.name}
Employee ID: ${employee.employee_id}
Email: ${user.email}
Department: ${employee.department_rel?.name ?? "N/A"}
Role: ${employee.role_rel?.name ?? user.role}
Shift: ${employee.shift_rel?.name ?? "N/A"}
Join Date: ${employee.join_date.toISOString().split("T")[0]}
Status: ${employee.status}

Leave Balances (${new Date().getFullYear()}):
${leaveInfo || "No leave balances found."}

Latest Payroll:
${payrollInfo}
          `.trim();
        }
      }
    }

    const systemInstruction = `
You are "Smart Assistant", an intelligent HR concierge embedded in the MKX HRMS Employee App.
Your job is to help the employee with HR-related queries and actions in a helpful, friendly, and concise manner.
Keep responses brief since they are shown on a mobile app. Use markdown formatting (bold, bullet points) where it helps readability.
Do NOT make up data. Only answer based on the context provided below.

--- EMPLOYEE CONTEXT ---
${contextBlock}
--- END CONTEXT ---
    `.trim();

    const model = genAI.getGenerativeModel({
      model: "gemini-2.0-flash-lite",
      systemInstruction,
    });

    const result = await model.generateContent(prompt);
    const text = result.response.text();

    res.status(200).json({ success: true, message: text });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "Unknown error occurred";
    res.status(500).json({
      success: false,
      error: "Failed to generate AI response",
      details: message,
    });
  }
};
