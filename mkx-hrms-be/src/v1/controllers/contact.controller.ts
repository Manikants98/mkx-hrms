import { Request, Response } from "express";
import { sendContactUsEmail } from "../services/email.service";

export const handleContactSubmit = async (req: Request, res: Response): Promise<void> => {
  const { name, email, number, subject, message } = req.body;

  const result = await sendContactUsEmail({
    name,
    email,
    number,
    subject,
    message,
  });

  if (result.success) {
    res.sendSuccess({
      message: "Your message has been sent successfully. We will get back to you shortly.",
    });
  } else {
    res.sendError({
      statusCode: 500,
      message: "Failed to send message. Please try again later.",
    });
  }
};
