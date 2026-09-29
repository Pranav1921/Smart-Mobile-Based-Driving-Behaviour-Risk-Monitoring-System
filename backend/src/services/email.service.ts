import tls from 'tls';
import dotenv from 'dotenv';
import { logger } from '../config/logger';

interface SendEmailOptions {
  to: string;
  subject: string;
  html: string;
}

export class EmailService {
  private getSmtpConfig() {
    dotenv.config();
    return {
      host: process.env.SMTP_HOST || 'smtp.gmail.com',
      port: Number(process.env.SMTP_PORT) || 465,
      user: process.env.SMTP_USER || '',
      pass: process.env.SMTP_PASS || '',
      from: process.env.EMAIL_FROM || process.env.SMTP_USER || 'SmartDrive Authority <noreply@smartdrive.ai>',
    };
  }

  /**
   * Native lightweight SMTP client over TLS (Port 465) without external dependencies.
   * Works reliably with Gmail, Brevo, Outlook, or any standard SMTP service.
   */
  async sendMail(options: SendEmailOptions): Promise<boolean> {
    const config = this.getSmtpConfig();

    if (!config.user || !config.pass) {
      logger.warn(`[EMAIL SERVICE] SMTP_USER or SMTP_PASS not set in .env. Email dispatch simulated for ${options.to}`);
      logger.info(`[SIMULATED EMAIL TO ${options.to}] Subject: ${options.subject}`);
      return false;
    }

    return new Promise((resolve) => {
      logger.info(`[EMAIL SERVICE] Connecting to SMTP server ${config.host}:${config.port} for ${options.to}...`);

      const socket = tls.connect({
        host: config.host,
        port: config.port,
        rejectUnauthorized: false, // Prevents self-signed or intermediate cert handshake issues
      });

      let step = 0;
      let buffer = '';

      const sendCmd = (cmd: string) => {
        socket.write(cmd + '\r\n');
      };

      socket.on('data', (data) => {
        const msg = data.toString();
        buffer += msg;

        // Wait for complete multi-line response (e.g. "250-", "250 ")
        if (!msg.match(/^\d{3} /m) && !msg.match(/\r\n/)) return;

        const code = parseInt(buffer.trim().substring(0, 3), 10);
        buffer = '';

        if (step === 0 && (code === 220 || code === 250)) {
          // Connected
          step = 1;
          sendCmd('EHLO smartdrive.ai');
        } else if (step === 1 && code === 250) {
          // EHLO success -> Start AUTH
          step = 2;
          sendCmd('AUTH LOGIN');
        } else if (step === 2 && code === 334) {
          // Send Username in base64
          step = 3;
          sendCmd(Buffer.from(config.user).toString('base64'));
        } else if (step === 3 && code === 334) {
          // Send Password in base64 (clean spaces if copied as Google App Password)
          step = 4;
          const cleanPass = config.pass.replace(/\s+/g, '');
          sendCmd(Buffer.from(cleanPass).toString('base64'));
        } else if (step === 4 && (code === 235 || code === 250)) {
          // Auth Success -> MAIL FROM
          step = 5;
          const senderEmail = config.user;
          sendCmd(`MAIL FROM:<${senderEmail}>`);
        } else if (step === 5 && code === 250) {
          // Recipient
          step = 6;
          sendCmd(`RCPT TO:<${options.to}>`);
        } else if (step === 6 && code === 250) {
          // DATA Command
          step = 7;
          sendCmd('DATA');
        } else if (step === 7 && code === 354) {
          // Send Headers and Body
          step = 8;
          const rawMessage = [
            `From: ${config.from}`,
            `To: <${options.to}>`,
            `Subject: ${options.subject}`,
            'MIME-Version: 1.0',
            'Content-Type: text/html; charset=UTF-8',
            '',
            options.html,
            '.',
          ].join('\r\n');

          socket.write(rawMessage + '\r\n');
        } else if (step === 8 && code === 250) {
          // Email sent successfully
          step = 9;
          logger.info(`[EMAIL SERVICE] SUCCESS! Real email dispatched to ${options.to}`);
          sendCmd('QUIT');
          socket.end();
          resolve(true);
        } else if (code >= 400) {
          logger.error(`[EMAIL SERVICE] SMTP Error at step ${step}: ${msg.trim()}`);
          socket.end();
          resolve(false);
        }
      });

      socket.on('error', (err) => {
        logger.error(`[EMAIL SERVICE] Socket error connecting to ${config.host}: ${err.message}`);
        resolve(false);
      });

      socket.setTimeout(12000, () => {
        logger.warn('[EMAIL SERVICE] SMTP connection timed out.');
        socket.destroy();
        resolve(false);
      });
    });
  }

  /**
   * Dispatches the official onboarding credential email to any approved driver
   */
  async sendDriverApprovalEmail(params: {
    toEmail: string;
    driverName: string;
    driverCode: string;
    tempPassword: string;
    zone: string;
  }) {
    const { toEmail, driverName, driverCode, tempPassword, zone } = params;

    const subject = `🎉 SmartDrive Application Approved - Your Driver ID: ${driverCode}`;

    const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #0f172a; margin: 0; padding: 20px; color: #f8fafc; }
        .container { max-width: 580px; margin: 0 auto; background-color: #1e293b; border-radius: 20px; border: 1px solid #334155; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.5); }
        .header { background: linear-gradient(135deg, #0f172a, #1e293b); padding: 30px; text-align: center; border-bottom: 2px solid #10b981; }
        .header h1 { margin: 0; color: #10b981; font-size: 24px; font-weight: 900; letter-spacing: 1px; }
        .header p { margin: 5px 0 0 0; color: #94a3b8; font-size: 11px; text-transform: uppercase; letter-spacing: 1.5px; }
        .content { padding: 30px; }
        .badge { display: inline-block; background-color: rgba(16,185,129,0.15); color: #10b981; padding: 4px 12px; border-radius: 9999px; font-size: 11px; font-weight: bold; border: 1px solid rgba(16,185,129,0.3); text-transform: uppercase; margin-bottom: 15px; }
        .greeting { font-size: 18px; font-weight: bold; margin-bottom: 12px; color: #ffffff; }
        .desc { font-size: 14px; line-height: 1.6; color: #cbd5e1; margin-bottom: 25px; }
        .card { background-color: #0f172a; border-radius: 14px; border: 1px solid #334155; padding: 20px; margin-bottom: 25px; }
        .row { display: flex; justify-content: space-between; margin-bottom: 12px; padding-bottom: 12px; border-bottom: 1px solid #1e293b; }
        .row:last-child { margin-bottom: 0; padding-bottom: 0; border-bottom: none; }
        .label { color: #94a3b8; font-size: 11px; font-weight: bold; text-transform: uppercase; }
        .val { color: #ffffff; font-size: 15px; font-family: monospace; font-weight: bold; }
        .highlight-id { color: #10b981; font-size: 18px; font-family: monospace; font-weight: 900; }
        .highlight-pw { color: #f59e0b; font-size: 18px; font-family: monospace; font-weight: 900; }
        .instructions { background-color: rgba(245,158,11,0.08); border-left: 4px solid #f59e0b; padding: 12px 16px; border-radius: 8px; font-size: 13px; color: #fde68a; line-height: 1.5; margin-bottom: 25px; }
        .footer { background-color: #0b1120; padding: 20px; text-align: center; font-size: 11px; color: #64748b; border-top: 1px solid #1e293b; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>SMARTDRIVE SYSTEM</h1>
          <p>Smart Mobile Driving Behaviour & Risk Monitoring</p>
        </div>
        <div class="content">
          <div class="badge">Application Approved</div>
          <div class="greeting">Hello ${driverName},</div>
          <div class="desc">
            Your onboarding application for <strong>${zone}</strong> has been officially verified and approved by the Regional Transport Command Center.
          </div>

          <div class="card">
            <div style="margin-bottom: 15px;">
              <div class="label">Official Driver ID (Issued)</div>
              <div class="highlight-id">${driverCode}</div>
            </div>
            <div>
              <div class="label">Default Access Password</div>
              <div class="highlight-pw">${tempPassword}</div>
            </div>
          </div>

          <div class="instructions">
            <strong>Important Security Notice:</strong><br>
            Please sign in to the SmartDrive Mobile App using either your <strong>Driver ID</strong> (<code>${driverCode}</code>) or registered email. You will be prompted to choose your permanent password immediately upon first sign-in.
          </div>

          <p style="font-size: 13px; color: #94a3b8; margin: 0;">
            Safe travels on the road,<br>
            <strong style="color: #cbd5e1;">Regional Transport Authority & Fleet Command</strong>
          </p>
        </div>
        <div class="footer">
          &copy; 2026 SmartDrive System. All rights reserved. This is an automated notification.
        </div>
      </div>
    </body>
    </html>
    `;

    return this.sendMail({
      to: toEmail,
      subject,
      html,
    });
  }
}

export const emailService = new EmailService();
