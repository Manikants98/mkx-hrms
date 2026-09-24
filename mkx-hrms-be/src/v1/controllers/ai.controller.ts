import { Request, Response } from "express";
import { GoogleGenAI } from "@google/genai";
import { prisma } from "../../libraries/prisma";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY || "" });

/**
 * Controller to handle Smart Assistant chat powered by Gemini.
 * Reads the authenticated user from `req.user`, fetches their live employee
 * context (name, department, leave balances, latest payroll) from the database,
 * and injects that context into the Gemini system instruction so the AI can
 * answer personal HR questions accurately.
 *
 * @param req - Express request with `req.user` populated by `requireAuth`
 * @param res - Express response
 */
export const chatWithAssistant = async (req: Request, res: Response): Promise<void> => {
  try {
    const { prompt } = req.body as { prompt?: string };

    if (!prompt) {
      res.status(400).json({ success: false, error: "Prompt is required" });
      return;
    }

    const user = req.user;
    let contextBlock = "The employee's account details are not available.";

    if (user?.employee_db_id) {
      const employee = await prisma.employee.findUnique({
        where: { id: user.employee_db_id },
        include: {
          department_rel: { select: { name: true } },
          role_rel: { select: { name: true } },
          shift_rel: { select: { name: true, start_time: true, end_time: true } },
          leave_balances: {
            include: { leave_type_rel: { select: { name: true } } },
            where: { year: new Date().getFullYear() },
          },
          payrolls: {
            orderBy: [{ year: "desc" }, { month: "desc" }],
            take: 1,
          },
          attendance: { take: 31, orderBy: { date: "desc" } }, // Last 14 days of attendance
          leaves: { take: 10, orderBy: { created_at: "desc" } }, // Last 10 leave requests
          salary_structures: true,
          manager: { select: { name: true, email: true } },
          subordinates: {
            select: { name: true, email: true, department_rel: { select: { name: true } } },
          },
          user: { select: { email: true, status: true, timezone: true } },
          notification_preferences: true,
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
Employee Full Record (JSON):
${JSON.stringify(employee, null, 2)}

Leave Balances (${new Date().getFullYear()}):
${leaveInfo || "No leave balances found."}

Latest Payroll:
${payrollInfo}
        `.trim();
      }
    }

    const systemInstruction = `
You are "Smart Assistant", an intelligent HR concierge embedded in the MKX HRMS Employee App.
Your job is to help the employee with HR-related queries in a helpful, friendly, and concise manner.
Keep responses brief since they are shown on a mobile app. Use markdown formatting (bold, bullet points) where it helps readability.
Do NOT make up data. Only answer based on the context provided below.

--- EMPLOYEE CONTEXT ---
${contextBlock}
--- END CONTEXT ---
    `.trim();

    const response = await ai.models.generateContent({
      model: "gemini-flash-lite-latest",
      contents: prompt,
      config: {
        systemInstruction,
      },
    });

    const text = response.text ?? "";

    if (user?.employee_db_id) {
      await prisma.aiChatHistory.create({
        data: {
          employee_id: user.employee_db_id,
          prompt,
          response: text,
        },
      });
    }

    res.status(200).json({ success: true, message: text });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Unknown error occurred";
    res.status(500).json({
      success: false,
      error: "Failed to generate AI response",
      details: message,
    });
  }
};

/**
 * Controller to fetch chat history for the authenticated employee.
 *
 * @param req - Express request with `req.user`
 * @param res - Express response
 */
export const getChatHistory = async (req: Request, res: Response): Promise<void> => {
  try {
    const user = req.user;
    if (!user?.employee_db_id) {
      res.status(200).json({ success: true, history: [] });
      return;
    }

    const history = await prisma.aiChatHistory.findMany({
      where: { employee_id: user.employee_db_id },
      orderBy: { created_at: "asc" },
      take: 50,
    });

    res.status(200).json({ success: true, history });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Unknown error occurred";
    res.status(500).json({
      success: false,
      error: "Failed to fetch chat history",
      details: message,
    });
  }
};

/**
 * Controller to clear chat history for the authenticated employee.
 *
 * @param req - Express request with `req.user`
 * @param res - Express response
 */
export const clearChatHistory = async (req: Request, res: Response): Promise<void> => {
  try {
    const user = req.user;
    if (!user?.employee_db_id) {
      res.status(200).json({ success: true });
      return;
    }

    await prisma.aiChatHistory.deleteMany({
      where: { employee_id: user.employee_db_id },
    });

    res.status(200).json({ success: true, message: "Chat history cleared" });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Unknown error occurred";
    res.status(500).json({
      success: false,
      error: "Failed to clear chat history",
      details: message,
    });
  }
};

