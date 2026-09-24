import { Request, Response } from "express";
import { GoogleGenerativeAI } from "@google/generative-ai";

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || "");

export const chatWithAssistant = async (req: Request, res: Response): Promise<void> => {
  try {
    const { prompt } = req.body;
    
    if (!prompt) {
      res.status(400).json({ error: "Prompt is required" });
      return;
    }

    // Using the user-specified model
    const model = genAI.getGenerativeModel({ model: "gemini-flash-lite-latest" });

    const systemInstruction = `
You are the "Smart Assistant" for MKX HRMS Employee App. 
You are an intelligent HR concierge helping an employee. 
Be helpful, concise, and professional. 
Keep your answers brief as they will be displayed on a mobile app bottom sheet.
    `;

    const chat = model.startChat({
      history: [
        {
          role: "user",
          parts: [{ text: systemInstruction }],
        },
        {
          role: "model",
          parts: [{ text: "Understood. How can I help you today?" }],
        },
      ],
    });

    const result = await chat.sendMessage(prompt);
    const response = await result.response;
    const text = response.text();

    res.status(200).json({
      success: true,
      message: text,
    });
  } catch (error: any) {
    console.error("AI Error:", error);
    res.status(500).json({
      success: false,
      error: "Failed to generate AI response",
      details: error.message,
    });
  }
};
