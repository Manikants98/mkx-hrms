import dns from "node:dns";
import net from "node:net";
import nodemailer, { Transporter } from "nodemailer";
import { logger } from "../../utils/logger";
import {
  EmployeeWelcomeEmailOptions,
  buildWelcomeEmailHtml,
  buildWelcomeEmailPlainText,
  LeaveApprovalEmailOptions,
  buildLeaveApprovalEmailHtml,
  buildLeaveApprovalEmailPlainText,
  LeaveStatusUpdateEmailOptions,
  buildLeaveStatusUpdateEmailHtml,
  buildLeaveStatusUpdateEmailPlainText,
} from "../templates/email.templates";

/**
 * Configuration payload required to send a welcome email to an employee
 */

/**
 * Result returned following an email delivery attempt
 */
export interface EmailSendResult {
  success: boolean;
  messageId?: string;
  error?: unknown;
}

/**
 * Generate a cryptographically strong, human-readable temporary password
 *
 * @param length - Desired character length of the generated password
 * @returns Generated password containing uppercase, lowercase, numbers, and special symbols
 */
export const generateTemporaryPassword = (length = 12): string => {
  const upper = "ABCDEFGHJKLMNPQRSTUVWXYZ";
  const lower = "abcdefghijkmnpqrstuvwxyz";
  const numbers = "23456789";
  const allChars = upper + lower + numbers;

  let password = "";
  for (let i = 0; i < length; i++) {
    const randomIndex = Math.floor(Math.random() * allChars.length);
    password += allChars[randomIndex];
  }
  return password;
};

/**
 * Cached Nodemailer transporter instance
 */
let transporterInstance: Transporter | null = null;

/**
 * Resolves all available IPv4 addresses for a given SMTP hostname to prevent ENETUNREACH errors on cloud hosting environments without IPv6 routing
 *
 * @param hostname - The SMTP server domain name
 * @returns Array of resolved IPv4 address strings
 */
const resolveIpv4Addresses = async (hostname: string): Promise<string[]> => {
  if (net.isIP(hostname)) {
    return [hostname];
  }
  try {
    const addresses = await dns.promises.resolve4(hostname);
    if (addresses && addresses.length > 0) {
      return addresses;
    }
  } catch (error) {
    logger.warn(`Could not resolve IPv4 addresses for host ${hostname}: ${String(error)}`);
  }
  return [hostname];
};

/**
 * Creates a Nodemailer Transporter bound to a specific host or IPv4 address
 *
 * @param hostAddress - Hostname or direct IPv4 address
 * @param servername - TLS SNI servername for SSL certificate validation
 * @returns Configured Nodemailer Transporter instance
 */
const createTransporterForHost = (hostAddress: string, servername: string): Transporter => {
  const port = Number(process.env.SMTP_PORT) || 465;
  const isSecure = port === 465;
  const user = process.env.SMTP_USERNAME || "mkx.webs@gmail.com";
  const pass = process.env.SMTP_PASSWORD || "rkpw ijyd pzap cdoe";

  return nodemailer.createTransport({
    host: hostAddress,
    port,
    secure: isSecure,
    connectionTimeout: 8000,
    greetingTimeout: 8000,
    socketTimeout: 10000,
    auth: {
      user,
      pass,
    },
    tls: {
      servername,
      rejectUnauthorized: false,
    },
  });
};

/**
 * Generates an executive-grade, responsive HTML email template for new employee onboarding
 *
 * @param options - Welcome email attributes
 * @returns Fully formatted HTML string
 */

/**
 * Generates clean plain-text fallback content for email clients
 *
 * @param options - Welcome email attributes
 * @returns Plain text representation
 */

/**
 * Dispatches an automated onboarding welcome email delivering portal credentials via Gmail SMTP
 *
 * @param options - Parameters for the welcome email
 * @returns Promise resolving with email dispatch status
 */
export const sendEmployeeWelcomeEmail = async (
  options: EmployeeWelcomeEmailOptions,
): Promise<EmailSendResult> => {
  try {
    const rawHost = process.env.SMTP_HOST || "smtp.gmail.com";
    const fromName = process.env.SMTP_FROM_NAME || "MKX HRMS Workplace";
    const fromEmail =
      process.env.SMTP_FROM_EMAIL || process.env.SMTP_USERNAME || "no-reply@mkx.monster";

    const mailOptions = {
      from: `"${fromName}" <${fromEmail}>`,
      to: options.email,
      subject: `Welcome to MKX HRMS - Your Account Credentials (${options.employeeId})`,
      text: buildWelcomeEmailPlainText(options),
      html: buildWelcomeEmailHtml(options),
    };

    if (transporterInstance) {
      try {
        const info = await transporterInstance.sendMail(mailOptions);
        logger.info(`Welcome email dispatched to ${options.email} (Message ID: ${info.messageId})`);
        return {
          success: true,
          messageId: info.messageId,
        };
      } catch (cachedErr) {
        logger.warn(
          `Cached SMTP transporter failed, attempting re-resolution: ${String(cachedErr)}`,
        );
        transporterInstance = null;
      }
    }

    const ipv4List = await resolveIpv4Addresses(rawHost);
    let lastError: unknown = null;

    for (const hostAddress of ipv4List) {
      try {
        const transporter = createTransporterForHost(hostAddress, rawHost);
        const info = await transporter.sendMail(mailOptions);
        transporterInstance = transporter;
        logger.info(
          `Welcome email dispatched to ${options.email} (Message ID: ${info.messageId}) [via IPv4: ${hostAddress}]`,
        );
        return {
          success: true,
          messageId: info.messageId,
        };
      } catch (err) {
        lastError = err;
        logger.warn(
          `Failed sending welcome email via [${hostAddress}], checking alternative address...`,
        );
      }
    }

    logger.error(`Failed to send welcome email to ${options.email}:`, lastError);
    return {
      success: false,
      error: lastError,
    };
  } catch (error) {
    logger.error(`Failed to send welcome email to ${options.email}:`, error);
    return {
      success: false,
      error,
    };
  }
};

/**
 * Verifies active SMTP connection and authentication credentials with automatic IPv4 fallback
 *
 * @returns Promise resolving to boolean indicating connection health
 */
export const verifySmtpConnection = async (): Promise<boolean> => {
  try {
    const rawHost = process.env.SMTP_HOST || "smtp.gmail.com";
    const ipv4List = await resolveIpv4Addresses(rawHost);

    let connected = false;
    let lastError: unknown = null;

    for (const hostAddress of ipv4List) {
      try {
        const testTransporter = createTransporterForHost(hostAddress, rawHost);
        await testTransporter.verify();
        transporterInstance = testTransporter;
        connected = true;
        logger.success(
          `SMTP email service is connected and ready to dispatch emails [via IPv4: ${hostAddress}]`,
        );
        break;
      } catch (err) {
        lastError = err;
        logger.warn(
          `SMTP verification attempt failed for [${hostAddress}], checking alternative address...`,
        );
      }
    }

    if (connected) {
      return true;
    }

    logger.warn(
      "SMTP email service verification failed. Check credentials or network connectivity.",
    );
    logger.error("SMTP verification error:", lastError);
    return false;
  } catch (error) {
    logger.error("Unexpected error during SMTP verification:", error);
    return false;
  }
};

/**
 * Configuration payload required to send a leave approval email to a manager
 */

export const sendLeaveApprovalEmail = async (
  options: LeaveApprovalEmailOptions,
): Promise<EmailSendResult> => {
  try {
    const rawHost = process.env.SMTP_HOST || "smtp.gmail.com";
    const fromName = process.env.SMTP_FROM_NAME || "MKX HRMS Workplace";
    const fromEmail =
      process.env.SMTP_FROM_EMAIL || process.env.SMTP_USERNAME || "mkx.webs@gmail.com";

    const mailOptions = {
      from: `"${fromName}" <${fromEmail}>`,
      to: options.managerEmail,
      subject: `Leave Approval Required: ${options.employeeName}`,
      text: buildLeaveApprovalEmailPlainText(options),
      html: buildLeaveApprovalEmailHtml(options),
    };

    if (transporterInstance) {
      try {
        const info = await transporterInstance.sendMail(mailOptions);
        logger.info(
          `Leave approval email dispatched to ${options.managerEmail} (Message ID: ${info.messageId})`,
        );
        return { success: true, messageId: info.messageId };
      } catch (cachedErr) {
        logger.warn(
          `Cached SMTP transporter failed, attempting re-resolution: ${String(cachedErr)}`,
        );
        transporterInstance = null;
      }
    }

    const ipv4List = await resolveIpv4Addresses(rawHost);
    let lastError: unknown = null;

    for (const hostAddress of ipv4List) {
      try {
        const transporter = createTransporterForHost(hostAddress, rawHost);
        const info = await transporter.sendMail(mailOptions);
        transporterInstance = transporter;
        logger.info(
          `Leave approval email dispatched to ${options.managerEmail} (Message ID: ${info.messageId}) [via IPv4: ${hostAddress}]`,
        );
        return { success: true, messageId: info.messageId };
      } catch (err) {
        lastError = err;
        logger.warn(
          `Failed sending leave approval email via [${hostAddress}], checking alternative address...`,
        );
      }
    }

    logger.error(`Failed to send leave approval email to ${options.managerEmail}:`, lastError);
    return { success: false, error: lastError };
  } catch (error) {
    logger.error(`Failed to send leave approval email to ${options.managerEmail}:`, error);
    return { success: false, error };
  }
};

export const sendLeaveStatusUpdateEmail = async (
  options: LeaveStatusUpdateEmailOptions,
): Promise<EmailSendResult> => {
  try {
    const rawHost = process.env.SMTP_HOST || "smtp.gmail.com";
    const mailOptions = {
      from: `"${process.env.SMTP_FROM_NAME || "HR System"}" <${
        process.env.SMTP_FROM_EMAIL || "noreply@company.com"
      }>`,
      to: options.employeeEmail,
      subject: `Leave Request ${options.status}`,
      text: buildLeaveStatusUpdateEmailPlainText(options),
      html: buildLeaveStatusUpdateEmailHtml(options),
    };

    if (transporterInstance) {
      try {
        const info = await transporterInstance.sendMail(mailOptions);
        logger.info(
          `Leave status update email dispatched to ${options.employeeEmail} (Message ID: ${info.messageId})`,
        );
        return { success: true, messageId: info.messageId };
      } catch (cachedErr) {
        logger.warn(
          `Cached SMTP transporter failed, attempting re-resolution: ${String(cachedErr)}`,
        );
        transporterInstance = null;
      }
    }

    const ipv4List = await resolveIpv4Addresses(rawHost);
    let lastError: unknown = null;

    for (const hostAddress of ipv4List) {
      try {
        const transporter = createTransporterForHost(hostAddress, rawHost);
        const info = await transporter.sendMail(mailOptions);
        transporterInstance = transporter;
        logger.info(
          `Leave status update email dispatched to ${options.employeeEmail} (Message ID: ${info.messageId}) [via IPv4: ${hostAddress}]`,
        );
        return { success: true, messageId: info.messageId };
      } catch (err) {
        lastError = err;
        logger.warn(
          `Failed sending leave status update email via [${hostAddress}], checking alternative address...`,
        );
      }
    }

    logger.error(
      `Failed to send leave status update email to ${options.employeeEmail}:`,
      lastError,
    );
    return { success: false, error: lastError };
  } catch (error) {
    logger.error(`Failed to send leave status update email to ${options.employeeEmail}:`, error);
    return { success: false, error };
  }
};

export interface ContactUsEmailOptions {
  name: string;
  email: string;
  number?: string;
  subject: string;
  message: string;
}

export const sendContactUsEmail = async (
  options: ContactUsEmailOptions,
): Promise<EmailSendResult> => {
  try {
    const rawHost = process.env.SMTP_HOST || "smtp.gmail.com";
    const fromEmail =
      process.env.SMTP_FROM_EMAIL || process.env.SMTP_USERNAME || "no-reply@mkx.monster";

    const mailOptions = {
      from: `"${options.name} (via Website)" <${fromEmail}>`,
      to: "mkxtechnologies@gmail.com",
      replyTo: options.email,
      subject: `New Contact Request: ${options.subject}`,
      text: `You have received a new message from ${options.name} (${options.email}).\n\nPhone Number: ${options.number || "N/A"}\nSubject: ${options.subject}\n\nMessage:\n${options.message}`,
      html: `
        <h2>New Contact Request</h2>
        <p><strong>Name:</strong> ${options.name}</p>
        <p><strong>Email:</strong> ${options.email}</p>
        <p><strong>Phone Number:</strong> ${options.number || "N/A"}</p>
        <p><strong>Subject:</strong> ${options.subject}</p>
        <hr />
        <p><strong>Message:</strong></p>
        <p>${options.message.replace(/\n/g, "<br/>")}</p>
      `,
    };

    if (transporterInstance) {
      try {
        const info = await transporterInstance.sendMail(mailOptions);
        logger.info(
          `Contact Us email dispatched to mkxtechnologies@gmail.com (Message ID: ${info.messageId})`,
        );
        logger.info(`SMTP Response: ${info.response}`);
        logger.info(`SMTP Envelope: ${JSON.stringify(info.envelope)}`);
        return { success: true, messageId: info.messageId };
      } catch (cachedErr) {
        logger.warn(
          `Cached SMTP transporter failed, attempting re-resolution: ${String(cachedErr)}`,
        );
        transporterInstance = null;
      }
    }

    const ipv4List = await resolveIpv4Addresses(rawHost);
    let lastError: unknown = null;

    for (const hostAddress of ipv4List) {
      try {
        const transporter = createTransporterForHost(hostAddress, rawHost);
        const info = await transporter.sendMail(mailOptions);
        transporterInstance = transporter;
        logger.info(
          `Contact Us email dispatched to mkxtechnologies@gmail.com (Message ID: ${info.messageId}) [via IPv4: ${hostAddress}]`,
        );
        logger.info(`SMTP Response: ${info.response}`);
        logger.info(`SMTP Envelope: ${JSON.stringify(info.envelope)}`);
        return { success: true, messageId: info.messageId };
      } catch (err) {
        lastError = err;
        logger.warn(
          `Failed sending Contact Us email via [${hostAddress}], checking alternative address...`,
        );
      }
    }

    logger.error(`Failed to send Contact Us email to mkxtechnologies@gmail.com:`, lastError);
    return { success: false, error: lastError };
  } catch (error) {
    logger.error(`Failed to send Contact Us email to mkxtechnologies@gmail.com:`, error);
    return { success: false, error };
  }
};
