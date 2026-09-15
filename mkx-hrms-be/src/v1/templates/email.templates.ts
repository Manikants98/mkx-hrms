// Email templates extracted from email.service.ts

export interface EmployeeWelcomeEmailOptions {
  name: string;
  email: string;
  employeeId: string;
  role?: string | null;
  department?: string | null;
  temporaryPassword: string;
  portalUrl?: string;
  /** One-time set-password token to embed in the CTA button URL */
  setPasswordToken?: string;
}

export const buildWelcomeEmailHtml = (options: EmployeeWelcomeEmailOptions): string => {
  const baseUrl = options.portalUrl || process.env.APP_PORTAL_URL || "https://mkxhrms.vercel.app";
  const portalUrl = options.setPasswordToken
    ? `${baseUrl}/set-password?token=${options.setPasswordToken}`
    : baseUrl;

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Welcome to Your New Account</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      background-color: #f6f9fc;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      -webkit-font-smoothing: antialiased;
    }
    table { border-collapse: collapse; width: 100%; }
    img { max-width: 100%; height: auto; display: block; }
    
    .wrapper { background-color: #f6f9fc; padding: 40px 20px; }
    .container { max-width: 580px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05); overflow: hidden; }
    
    .header { padding: 40px 40px 20px 40px; text-align: center; }
    .content { padding: 0 40px 30px 40px; }
    .footer { background-color: #fdfdfd; border-top: 1px solid #edf2f7; padding: 30px 40px; text-align: center; }
    
    h1 { color: #1a202c; font-size: 26px; font-weight: 700; margin: 0 0 16px 0; line-height: 1.3; }
    p { color: #4a5568; font-size: 16px; line-height: 1.6; margin: 0 0 24px 0; }
    
    .avatar-logo {
      display: inline-block;
      width: 44px;
      height: 44px;
      line-height: 44px;
      border-radius: 8px;
      background-color: #0f172a;
      color: #ffffff;
      font-size: 22px;
      font-weight: 700;
      text-align: center;
      box-shadow: 0 2px 6px rgba(15, 23, 42, 0.15);
    }
    
    .credentials-box {
      background-color: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      padding: 6px 16px;
      text-align: center;
      margin-bottom: 26px;
    }
    .credential-row { padding: 5px 0; }
    .credential-label { color: #718096; font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px; }
    .credential-value { color: #2d3748; font-size: 16px; font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace; font-weight: 600; }
    
    .btn-container { text-align: center; margin: 28px 0; }
    .btn {
      background-color: #4f46e5;
      color: #ffffff !important;
      display: inline-block;
      padding: 14px 32px;
      font-size: 16px;
      font-weight: 600;
      text-decoration: none;
      border-radius: 6px;
      box-shadow: 0 4px 6px -1px rgba(79, 70, 229, 0.2);
    }
    
    .security-notice {
      background-color: #fffaf0;
      border-left: 4px solid #dd6b20;
      padding: 16px;
      border-radius: 0 6px 6px 0;
      margin-bottom: 24px;
      text-align: left;
    }
    .security-notice p { color: #744210; font-size: 14px; margin: 0; line-height: 1.5; }
    .footer-text { color: #a0aec0; font-size: 13px; line-height: 1.5; margin: 0; }
    .footer-link { color: #718096; text-decoration: underline; }

    @media only screen and (max-width: 600px) {
      .wrapper { padding: 16px 8px !important; }
      .header { padding: 30px 20px 10px 20px !important; }
      .content { padding: 0 20px 24px 20px !important; }
      .footer { padding: 24px 20px !important; }
      h1 { font-size: 22px !important; }
      .btn { display: block !important; width: 100% !important; box-sizing: border-box !important; padding: 14px 16px !important; }
    }

    @media (prefers-color-scheme: dark) {
      body, .wrapper {
        background-color: #0b0f17 !important;
      }
      .container {
        background-color: #161f2e !important;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3) !important;
      }
      .avatar-logo {
        background-color: #4f46e5 !important;
        color: #ffffff !important;
      }
      h1 {
        color: #f1f5f9 !important;
      }
      p {
        color: #94a3b8 !important;
      }
      .credentials-box {
        background-color: #0f172a !important;
        border-color: #334155 !important;
      }
      .credential-row {
        border-bottom-color: #334155 !important;
      }
      .credential-label {
        color: #64748b !important;
      }
      .credential-value {
        color: #f8fafc !important;
      }
      .security-notice {
        background-color: #2a1b0a !important;
        border-left-color: #f97316 !important;
      }
      .security-notice p {
        color: #fdba74 !important;
      }
      .footer {
        background-color: #111827 !important;
        border-top-color: #1e293b !important;
      }
      .footer-text {
        color: #64748b !important;
      }
    }
  </style>
</head>
<body>

<table role="presentation" class="wrapper" style="width: 100%; border-collapse: collapse; background-color: #f6f9fc; padding: 40px 20px;">
  <tr>
    <td align="center">
      <table role="presentation" class="container" style="max-width: 580px; width: 100%; margin: 0 auto; background-color: #ffffff; border-radius: 12px; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05); overflow: hidden; border-collapse: collapse;">
        
        <tr>
          <td class="header" style="padding: 40px 40px 20px 40px; text-align: center;">
            <table role="presentation" border="0" cellspacing="0" cellpadding="0" style="margin: 0 auto 16px auto;">
              <tr>
                <td align="center" class="avatar-logo" style="width: 44px; height: 44px; border-radius: 8px; background-color: #0f172a; color: #ffffff; font-size: 22px; font-weight: 700; text-align: center; line-height: 44px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; box-shadow: 0 2px 6px rgba(15, 23, 42, 0.15);">
                  M
                </td>
              </tr>
            </table>
            <h1 style="color: #1a202c; font-size: 26px; font-weight: 700; margin: 0 0 16px 0; line-height: 1.3; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
              Welcome to Your Dashboard!
            </h1>
          </td>
        </tr>
        
        <tr>
          <td class="content" style="padding: 0 40px 30px 40px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
            <p style="color: #4a5568; font-size: 16px; line-height: 1.6; margin: 0 0 16px 0;">
              Hi <strong>${options.name}</strong>,
            </p>
            <p style="color: #4a5568; font-size: 16px; line-height: 1.6; margin: 0 0 24px 0;">
              Your workspace is officially set up and ready to go. We've provisioned a secure account profile using the temporary credentials detailed below:
            </p>
            
            <div class="credentials-box" style="background-color: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 6px 16px; text-align: center; margin-bottom: 26px;">
              <div class="credential-row" style="padding: 10px 0;">
                <div class="credential-value" style="color: #0f172a; font-size: 20px; font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace; font-weight: 700;">${options.temporaryPassword}</div>
              </div>
            </div>
            
            <div class="security-notice" style="background-color: #fffaf0; border-left: 4px solid #dd6b20; padding: 16px; border-radius: 0 6px 6px 0; margin-bottom: 24px; text-align: left;">
              <p style="color: #744210; font-size: 14px; margin: 0; line-height: 1.5;">
                <strong>Immediate Action Required:</strong> For optimal system infrastructure protection, this single-use password will expire automatically within <strong>24 hours</strong>. You must establish a distinct personal password during your initial session.
              </p>
            </div>
            
            <div class="btn-container" style="text-align: center; margin: 28px 0;">
              <a href="${portalUrl}" class="btn" target="_blank" style="background-color: #4f46e5; color: #ffffff !important; display: inline-block; padding: 14px 32px; font-size: 16px; font-weight: 600; text-decoration: none; border-radius: 6px; box-shadow: 0 4px 6px -1px rgba(79, 70, 229, 0.2); font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">
                Confirm & Set Password
              </a>
            </div>
          </td>
        </tr>
        
        <tr>
          <td class="footer" style="background-color: #fdfdfd; border-top: 1px solid #edf2f7; padding: 30px 40px; text-align: center;">
            <p class="footer-text" style="color: #a0aec0; font-size: 13px; line-height: 1.5; margin: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
              Sent by <strong>MKX Technologies Pvt. Ltd.</strong> • 129, Street Number 13, Block A, New Ashok Nagar, New Delhi
            </p>
          </td>
        </tr>
        
      </table>
    </td>
  </tr>
</table>

</body>
</html>`;
};


export const buildWelcomeEmailPlainText = (options: EmployeeWelcomeEmailOptions): string => {
  const baseUrl = options.portalUrl || process.env.APP_PORTAL_URL || "https://mkxhrms.vercel.app";
  const portalUrl = options.setPasswordToken
    ? `${baseUrl.replace(/\/login$/, "")}/set-password?token=${options.setPasswordToken}`
    : baseUrl;
  return `Welcome to Your Dashboard!

Hi ${options.name},

Your workspace is officially set up and ready to go. We've provisioned a secure account profile using the temporary credentials detailed below:

Temporary Password: ${options.temporaryPassword}

Confirm & Set Password:
${portalUrl}

Immediate Action Required: For optimal system infrastructure protection, this single-use password will expire automatically within 24 hours. You must establish a distinct personal password during your initial session.

Sent by MKX Technologies Pvt. Ltd. • 129, Street Number 13, Block A, New Ashok Nagar, New Delhi
`;
};


export interface LeaveApprovalEmailOptions {
  managerName: string;
  managerEmail: string;
  employeeName: string;
  leaveType: string;
  startDate: string;
  endDate: string;
  daysCount: number;
  reason: string;
  approvalToken: string;
  portalUrl?: string;
}

export const buildLeaveApprovalEmailHtml = (options: LeaveApprovalEmailOptions): string => {
  const baseUrl = options.portalUrl || process.env.APP_PORTAL_URL || "https://mkxhrms.vercel.app";
  const portalUrl = `${baseUrl.replace(/\/login$/, "")}/leave-approval/${options.approvalToken}`;

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Leave Request Approval</title>
  <style>
    body { margin: 0; padding: 0; background-color: #f6f9fc; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; -webkit-font-smoothing: antialiased; }
    table { border-collapse: collapse; width: 100%; }
    .wrapper { background-color: #f6f9fc; padding: 40px 20px; }
    .container { max-width: 580px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05); overflow: hidden; }
    .header { padding: 40px 40px 20px 40px; text-align: center; }
    .content { padding: 0 40px 30px 40px; }
    .footer { background-color: #fdfdfd; border-top: 1px solid #edf2f7; padding: 30px 40px; text-align: center; }
    h1 { color: #1a202c; font-size: 26px; font-weight: 700; margin: 0 0 16px 0; line-height: 1.3; }
    p { color: #4a5568; font-size: 16px; line-height: 1.6; margin: 0 0 24px 0; }
    .credentials-box { background-color: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 16px; text-align: left; margin-bottom: 26px; }
    .credential-row { padding: 5px 0; }
    .credential-label { color: #718096; font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px; }
    .credential-value { color: #2d3748; font-size: 16px; font-weight: 600; }
    .btn-container { text-align: center; margin: 28px 0; }
    .btn { background-color: #4f46e5; color: #ffffff !important; display: inline-block; padding: 14px 32px; font-size: 16px; font-weight: 600; text-decoration: none; border-radius: 6px; box-shadow: 0 4px 6px -1px rgba(79, 70, 229, 0.2); }
    .footer-text { color: #a0aec0; font-size: 13px; line-height: 1.5; margin: 0; }
  </style>
</head>
<body>
<table role="presentation" class="wrapper">
  <tr>
    <td align="center">
      <table role="presentation" class="container">
        <tr>
          <td class="header">
            <h1>Leave Request Approval</h1>
          </td>
        </tr>
        <tr>
          <td class="content">
            <p>Hi <strong>${options.managerName}</strong>,</p>
            <p><strong>${options.employeeName}</strong> has requested time off. Please review the details below:</p>
            
            <div class="credentials-box">
              <div class="credential-row">
                <div class="credential-label">Leave Type</div>
                <div class="credential-value">${options.leaveType}</div>
              </div>
              <div class="credential-row">
                <div class="credential-label">Duration</div>
                <div class="credential-value">${options.startDate} to ${options.endDate} (${options.daysCount} days)</div>
              </div>
              <div class="credential-row">
                <div class="credential-label">Reason</div>
                <div class="credential-value">${options.reason}</div>
              </div>
            </div>
            
            <div class="btn-container">
              <a href="${portalUrl}" class="btn" target="_blank">Review Request</a>
            </div>
          </td>
        </tr>
        <tr>
          <td class="footer">
            <p class="footer-text">Sent by <strong>MKX Technologies Pvt. Ltd.</strong></p>
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>
</body>
</html>`;
};


export const buildLeaveApprovalEmailPlainText = (options: LeaveApprovalEmailOptions): string => {
  const baseUrl = options.portalUrl || process.env.APP_PORTAL_URL || "https://mkxhrms.vercel.app";
  const portalUrl = `${baseUrl.replace(/\/login$/, "")}/leave-approval/${options.approvalToken}`;

  return `Leave Request Approval

Hi ${options.managerName},

${options.employeeName} has requested time off. Please review the details below:

Leave Type: ${options.leaveType}
Duration: ${options.startDate} to ${options.endDate} (${options.daysCount} days)
Reason: ${options.reason}

Review Request:
${portalUrl}

Sent by MKX Technologies Pvt. Ltd.
`;
};


export interface LeaveStatusUpdateEmailOptions {
  employeeName: string;
  employeeEmail: string;
  status: "Approved" | "Rejected";
  leaveType: string;
  startDate: string;
  endDate: string;
  daysCount: number;
  remark?: string | null;
}

export const buildLeaveStatusUpdateEmailHtml = (options: LeaveStatusUpdateEmailOptions): string => {
  const color = options.status === "Approved" ? "#10b981" : "#ef4444";
  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Leave Request ${options.status}</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f9fafb; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .card { background: #ffffff; border-radius: 8px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06); overflow: hidden; margin-top: 20px; }
    .header { background: ${color}; color: white; padding: 24px; text-align: center; }
    .header h1 { margin: 0; font-size: 24px; font-weight: 600; }
    .content { padding: 32px; }
    .greeting { font-size: 18px; font-weight: 600; margin-bottom: 24px; color: #111827; }
    .details { background: #f3f4f6; border-radius: 6px; padding: 20px; margin-bottom: 24px; }
    .details p { margin: 0 0 12px 0; font-size: 15px; }
    .details p:last-child { margin: 0; }
    .label { font-weight: 600; color: #4b5563; display: inline-block; width: 120px; }
    .value { color: #111827; }
    .footer { text-align: center; padding: 24px; color: #6b7280; font-size: 14px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="card">
      <div class="header">
        <h1>Leave Request ${options.status}</h1>
      </div>
      <div class="content">
        <div class="greeting">Hi ${options.employeeName},</div>
        <p style="margin-bottom: 24px; color: #4b5563;">Your manager has reviewed your recent leave request and it has been <strong style="color: ${color}">${options.status.toLowerCase()}</strong>.</p>
        
        <div class="details">
          <p><span class="label">Leave Type:</span> <span class="value">${options.leaveType}</span></p>
          <p><span class="label">Duration:</span> <span class="value">${options.startDate} to ${options.endDate}</span></p>
          <p><span class="label">Days:</span> <span class="value">${options.daysCount}</span></p>
          ${
            options.remark
              ? `<div style="margin-top: 16px; padding-top: 16px; border-top: 1px solid #e5e7eb;">
                   <p><span class="label">Manager Remark:</span> <span class="value" style="color: #4b5563; font-style: italic;">"${options.remark}"</span></p>
                 </div>`
              : ""
          }
        </div>
        
        <p style="color: #4b5563; margin-top: 24px;">If you have any questions, please contact your manager or HR.</p>
      </div>
    </div>
    <div class="footer">
      <p>&copy; ${new Date().getFullYear()} MKX Technologies Pvt. Ltd. All rights reserved.</p>
    </div>
  </div>
</body>
</html>`;
};


export const buildLeaveStatusUpdateEmailPlainText = (
  options: LeaveStatusUpdateEmailOptions,
): string => {
  return `Leave Request ${options.status}

Hi ${options.employeeName},

Your manager has reviewed your recent leave request and it has been ${options.status.toLowerCase()}.

Request Details:
- Leave Type: ${options.leaveType}
- Duration: ${options.startDate} to ${options.endDate}
- Days: ${options.daysCount}
${options.remark ? `\nManager Remark:\n"${options.remark}"\n` : ""}
If you have any questions, please contact your manager or HR.

Best regards,
MKX Technologies Pvt. Ltd.`;
};
