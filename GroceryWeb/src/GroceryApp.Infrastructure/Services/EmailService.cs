using System.Net;
using System.Net.Mail;
using GroceryApp.Application.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace GroceryApp.Infrastructure.Services;

public class EmailService : IEmailService
{
    private readonly IConfiguration _config;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IConfiguration config, ILogger<EmailService> logger)
    {
        _config = config;
        _logger = logger;
    }

    public async Task SendEmailVerificationCodeAsync(string toEmail, string toName, string code)
    {
        var subject = "Your GroceryApp Verification Code";
        var body = $"""
        <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;color:#1f2937;">
          <div style="background:linear-gradient(135deg,#059669,#047857);padding:24px 32px;border-radius:8px 8px 0 0;text-align:center;">
            <h1 style="color:#fff;margin:0;font-size:22px;">GroceryApp</h1>
            <p style="color:#d1fae5;margin:4px 0 0;font-size:13px;">Email Verification</p>
          </div>
          <div style="background:#fff;padding:32px;border:1px solid #e5e7eb;border-top:none;border-radius:0 0 8px 8px;">
            <p style="font-size:15px;margin:0 0 16px;">Hi <strong>{toName}</strong>,</p>
            <p style="font-size:14px;color:#6b7280;margin:0 0 24px;">
              Use the code below to verify your email address. This code expires in <strong>10 minutes</strong>.
            </p>
            <div style="text-align:center;margin:24px 0;">
              <span style="display:inline-block;background:#f0fdf4;border:2px solid #059669;border-radius:12px;
                           padding:16px 40px;font-size:36px;font-weight:bold;letter-spacing:12px;color:#059669;">
                {code}
              </span>
            </div>
            <p style="font-size:12px;color:#9ca3af;text-align:center;margin-top:24px;">
              If you didn't request this, you can safely ignore this email.
            </p>
          </div>
        </div>
        """;

        await SendAsync(toEmail, subject, body);
    }

    public async Task SendEmailVerifiedConfirmationAsync(string toEmail, string toName)
    {
        var subject = "Email Verified — Welcome to GroceryApp!";
        var body = $"""
        <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;color:#1f2937;">
          <div style="background:linear-gradient(135deg,#059669,#047857);padding:24px 32px;border-radius:8px 8px 0 0;text-align:center;">
            <h1 style="color:#fff;margin:0;font-size:22px;">GroceryApp</h1>
          </div>
          <div style="background:#fff;padding:32px;border:1px solid #e5e7eb;border-top:none;border-radius:0 0 8px 8px;text-align:center;">
            <div style="width:64px;height:64px;background:#f0fdf4;border-radius:50%;display:inline-flex;
                        align-items:center;justify-content:center;margin-bottom:16px;">
              <span style="font-size:32px;">✅</span>
            </div>
            <h2 style="font-size:20px;margin:0 0 8px;color:#059669;">Email Verified!</h2>
            <p style="font-size:15px;margin:0 0 16px;">Hi <strong>{toName}</strong>,</p>
            <p style="font-size:14px;color:#6b7280;margin:0 0 24px;">
              Your email address has been successfully verified.<br/>
              You can now enjoy all features of GroceryApp.
            </p>
            <p style="font-size:12px;color:#9ca3af;margin-top:24px;">
              Verified on {DateTime.UtcNow:MMMM dd, yyyy 'at' HH:mm} UTC
            </p>
          </div>
        </div>
        """;

        await SendAsync(toEmail, subject, body);
    }

    private async Task SendAsync(string toEmail, string subject, string htmlBody)
    {
        var smtp = _config.GetSection("Smtp");
        var host = smtp["Host"];
        var port = int.Parse(smtp["Port"] ?? "587");
        var enableSsl = bool.Parse(smtp["EnableSsl"] ?? "true");
        var userName = smtp["UserName"];
        var password = smtp["Password"];
        var fromAddress = smtp["FromAddress"] ?? userName ?? "";
        var fromName = smtp["FromName"] ?? "GroceryApp";

        if (string.IsNullOrWhiteSpace(host) || string.IsNullOrWhiteSpace(userName) ||
            string.IsNullOrWhiteSpace(password) || userName.Contains("your-email") ||
            userName.Contains("REPLACE_VIA_USER_SECRETS") || password.Contains("REPLACE_VIA_USER_SECRETS"))
        {
            var message = $"SMTP not configured; cannot send email to {toEmail}. Subject: {subject}";
            _logger.LogError("{Message}", message);
            await WriteEmailLogAsync("ERROR", message);
            throw new InvalidOperationException(message);
        }

        try
        {
            using var client = new SmtpClient(host, port)
            {
                EnableSsl = enableSsl,
                Credentials = new NetworkCredential(userName, password)
            };

            using var mail = new MailMessage(
                new MailAddress(fromAddress, fromName),
                new MailAddress(toEmail))
            {
                Subject = subject,
                Body = htmlBody,
                IsBodyHtml = true
            };

            await client.SendMailAsync(mail);

            var message = $"Sent '{subject}' to {toEmail} via {host}:{port}.";
            _logger.LogInformation("{Message}", message);
            await WriteEmailLogAsync("SENT", message);
        }
        catch (Exception ex)
        {
            var message = $"Failed to send '{subject}' to {toEmail} via {host}:{port}. {ex.GetType().Name}: {ex.Message}";
            _logger.LogError(ex, "{Message}", message);
            await WriteEmailLogAsync("ERROR", message);
            throw;
        }
    }

    private async Task WriteEmailLogAsync(string level, string message)
    {
        var configuredPath = _config["EmailLog:Path"] ?? Path.Combine("Logs", "email-log.txt");
        var path = Path.IsPathRooted(configuredPath)
            ? configuredPath
            : Path.Combine(Directory.GetCurrentDirectory(), configuredPath);

        var directory = Path.GetDirectoryName(path);
        if (!string.IsNullOrWhiteSpace(directory))
        {
            Directory.CreateDirectory(directory);
        }

        var line = $"{DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC [{level}] {message}{Environment.NewLine}";
        await File.AppendAllTextAsync(path, line);
    }
}
