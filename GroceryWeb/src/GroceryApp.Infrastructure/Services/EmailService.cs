using System.Net;
using System.Net.Mail;
using System.Runtime.ExceptionServices;
using System.Security.Cryptography;
using System.Text;
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

    // ── Shared helpers ─────────────────────────────────────────────────────────

    private static string EmailHeader(string subtitle) =>
        $"<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\"><tr>" +
        $"<td style=\"background:linear-gradient(135deg,#059669,#047857);padding:24px 32px;border-radius:8px 8px 0 0;text-align:center;\">" +
        $"<div style=\"font-family:Arial,sans-serif;font-size:22px;font-weight:bold;color:#ffffff;margin:0;\">GroceryApp</div>" +
        $"<div style=\"font-family:Arial,sans-serif;font-size:13px;color:#d1fae5;margin:4px 0 0;\">{subtitle}</div>" +
        $"</td></tr></table>";

    private static string DetailRow(string label, string value, string valueColor = "#1f2937", bool isLast = false)
    {
        var pad = isLast ? "8px 0 0 0" : "0 0 8px 0";
        return $"<tr>" +
               $"<td style=\"font-family:Arial,sans-serif;font-size:13px;color:#6b7280;padding:{pad};\">{label}</td>" +
               $"<td style=\"font-family:Arial,sans-serif;font-size:13px;font-weight:bold;color:{valueColor};text-align:right;padding:{pad};\">{value}</td>" +
               $"</tr>";
    }

    private static string DetailBox(string bgColor, string borderColor, string rows) =>
        $"<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\" " +
        $"style=\"background:{bgColor};border:1px solid {borderColor};border-radius:8px;margin-bottom:24px;\">" +
        $"<tr><td style=\"padding:16px 20px;\">" +
        $"<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\">{rows}</table>" +
        $"</td></tr></table>";

    private static string EmailWrapper(string content) =>
        $"<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\" style=\"background:#f3f4f6;\">" +
        $"<tr><td align=\"center\" style=\"padding:32px 16px;\">" +
        $"<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\" style=\"max-width:520px;\">{content}</table>" +
        $"</td></tr></table>";

    // ── Email templates ────────────────────────────────────────────────────────

    public async Task SendEmailVerificationCodeAsync(string toEmail, string toName, string code)
    {
        var subject = "Your GroceryApp Verification Code";
        var inner =
            $"<tr><td>{EmailHeader("Email Verification")}</td></tr>" +
            $"<tr><td style=\"background:#ffffff;padding:32px;border:1px solid #e5e7eb;border-top:none;border-radius:0 0 8px 8px;\">" +
            $"<p style=\"font-family:Arial,sans-serif;font-size:15px;margin:0 0 16px;color:#1f2937;\">Hi <strong>{toName}</strong>,</p>" +
            $"<p style=\"font-family:Arial,sans-serif;font-size:14px;color:#6b7280;margin:0 0 24px;\">Use the code below to verify your email address. This code expires in <strong>10 minutes</strong>.</p>" +
            $"<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\"><tr><td align=\"center\" style=\"padding:24px 0;\">" +
            $"<span style=\"display:inline-block;background:#f0fdf4;border:2px solid #059669;border-radius:12px;padding:16px 40px;font-family:Arial,sans-serif;font-size:36px;font-weight:bold;letter-spacing:12px;color:#059669;\">{code}</span>" +
            $"</td></tr></table>" +
            $"<p style=\"font-family:Arial,sans-serif;font-size:12px;color:#9ca3af;text-align:center;margin:24px 0 0;\">If you didn't request this, you can safely ignore this email.</p>" +
            $"</td></tr>";
        await SendAsync(toEmail, subject, EmailWrapper(inner));
    }

    public async Task SendEmailVerifiedConfirmationAsync(string toEmail, string toName)
    {
        var subject = "Email Verified — Welcome to GroceryApp!";
        var inner =
            $"<tr><td>{EmailHeader("Account Verified")}</td></tr>" +
            $"<tr><td style=\"background:#ffffff;padding:32px;border:1px solid #e5e7eb;border-top:none;border-radius:0 0 8px 8px;text-align:center;\">" +
            $"<div style=\"font-size:48px;line-height:1;margin-bottom:12px;\">&#x2705;</div>" +
            $"<h2 style=\"font-family:Arial,sans-serif;font-size:20px;margin:0 0 16px;color:#059669;\">Email Verified!</h2>" +
            $"<p style=\"font-family:Arial,sans-serif;font-size:15px;margin:0 0 12px;color:#1f2937;\">Hi <strong>{toName}</strong>,</p>" +
            $"<p style=\"font-family:Arial,sans-serif;font-size:14px;color:#6b7280;margin:0 0 24px;\">Your email address has been successfully verified.<br/>You can now enjoy all features of GroceryApp.</p>" +
            $"<p style=\"font-family:Arial,sans-serif;font-size:12px;color:#9ca3af;margin:0;\">Verified on {DateTime.UtcNow:MMMM dd, yyyy 'at' HH:mm} UTC</p>" +
            $"</td></tr>";
        await SendAsync(toEmail, subject, EmailWrapper(inner));
    }

    public async Task SendOrderPlacedAsync(string toEmail, string toName, string orderNumber, decimal total, DateTime deliveryDate, string? timeSlot)
    {
        var subject = $"Order Confirmed — {orderNumber}";
        var deliveryLine = $"{deliveryDate:MMMM dd, yyyy}{(string.IsNullOrWhiteSpace(timeSlot) ? "" : $" at {timeSlot}")}";
        var rows = DetailRow("Order Number", orderNumber)
                 + DetailRow("Total Amount", $"&#8369;{total:N2}", "#059669")
                 + DetailRow("Delivery Schedule", deliveryLine, isLast: true);
        var inner =
            $"<tr><td>{EmailHeader("Order Confirmation")}</td></tr>" +
            $"<tr><td style=\"background:#ffffff;padding:32px;border:1px solid #e5e7eb;border-top:none;border-radius:0 0 8px 8px;\">" +
            $"<div style=\"text-align:center;margin-bottom:20px;\"><div style=\"font-size:48px;line-height:1;\">&#x1F6D2;</div>" +
            $"<h2 style=\"font-family:Arial,sans-serif;font-size:20px;color:#059669;margin:10px 0 0;\">Order Placed Successfully!</h2></div>" +
            $"<p style=\"font-family:Arial,sans-serif;font-size:15px;margin:0 0 12px;color:#1f2937;\">Hi <strong>{toName}</strong>,</p>" +
            $"<p style=\"font-family:Arial,sans-serif;font-size:14px;color:#6b7280;margin:0 0 20px;\">Thank you for your order! We've received it and it's now being processed.</p>" +
            DetailBox("#f9fafb", "#e5e7eb", rows) +
            $"<p style=\"font-family:Arial,sans-serif;font-size:12px;color:#9ca3af;text-align:center;margin:0;\">You'll receive another email when your order is out for delivery.</p>" +
            $"</td></tr>";
        await SendAsync(toEmail, subject, EmailWrapper(inner));
    }

    public async Task SendOrderCancelledAsync(string toEmail, string toName, string orderNumber, decimal total)
    {
        var subject = $"Order Cancelled — {orderNumber}";
        var rows = DetailRow("Order Number", orderNumber)
                 + DetailRow("Order Total", $"&#8369;{total:N2}", isLast: true);
        var inner =
            $"<tr><td>{EmailHeader("Order Update")}</td></tr>" +
            $"<tr><td style=\"background:#ffffff;padding:32px;border:1px solid #e5e7eb;border-top:none;border-radius:0 0 8px 8px;\">" +
            $"<div style=\"text-align:center;margin-bottom:20px;\"><div style=\"font-size:48px;line-height:1;\">&#x274C;</div>" +
            $"<h2 style=\"font-family:Arial,sans-serif;font-size:20px;color:#ef4444;margin:10px 0 0;\">Order Cancelled</h2></div>" +
            $"<p style=\"font-family:Arial,sans-serif;font-size:15px;margin:0 0 12px;color:#1f2937;\">Hi <strong>{toName}</strong>,</p>" +
            $"<p style=\"font-family:Arial,sans-serif;font-size:14px;color:#6b7280;margin:0 0 20px;\">Your order has been cancelled. If you did not request this cancellation or have any questions, please contact our support team.</p>" +
            DetailBox("#fef2f2", "#fecaca", rows) +
            $"<p style=\"font-family:Arial,sans-serif;font-size:12px;color:#9ca3af;text-align:center;margin:0;\">If a payment was made, a refund will be processed within 3&#8211;5 business days.</p>" +
            $"</td></tr>";
        await SendAsync(toEmail, subject, EmailWrapper(inner));
    }

    public async Task SendOrderOutForDeliveryAsync(string toEmail, string toName, string orderNumber, DateTime? deliveryDate, string? timeSlot)
    {
        var subject = $"Your Order is Out for Delivery — {orderNumber}";
        var scheduleText = deliveryDate.HasValue
            ? $"{deliveryDate.Value:MMMM dd, yyyy}{(string.IsNullOrWhiteSpace(timeSlot) ? "" : $" at {timeSlot}")}"
            : "Today";
        var rows = DetailRow("Order Number", orderNumber)
                 + DetailRow("Expected Delivery", scheduleText, "#7c3aed", isLast: true);
        var inner =
            $"<tr><td>{EmailHeader("Delivery Update")}</td></tr>" +
            $"<tr><td style=\"background:#ffffff;padding:32px;border:1px solid #e5e7eb;border-top:none;border-radius:0 0 8px 8px;\">" +
            $"<div style=\"text-align:center;margin-bottom:20px;\"><div style=\"font-size:48px;line-height:1;\">&#x1F69A;</div>" +
            $"<h2 style=\"font-family:Arial,sans-serif;font-size:20px;color:#7c3aed;margin:10px 0 0;\">Out for Delivery!</h2></div>" +
            $"<p style=\"font-family:Arial,sans-serif;font-size:15px;margin:0 0 12px;color:#1f2937;\">Hi <strong>{toName}</strong>,</p>" +
            $"<p style=\"font-family:Arial,sans-serif;font-size:14px;color:#6b7280;margin:0 0 20px;\">Great news! Your order is on its way. Please make sure someone is available to receive it.</p>" +
            DetailBox("#faf5ff", "#e9d5ff", rows) +
            $"<p style=\"font-family:Arial,sans-serif;font-size:12px;color:#9ca3af;text-align:center;margin:0;\">Open the GroceryApp to track your order in real time.</p>" +
            $"</td></tr>";
        await SendAsync(toEmail, subject, EmailWrapper(inner));
    }

    public async Task SendOrderDeliveredAsync(string toEmail, string toName, string orderNumber, decimal total)
    {
        var subject = $"Order Delivered — {orderNumber}";
        var rows = DetailRow("Order Number", orderNumber)
                 + DetailRow("Total Paid", $"&#8369;{total:N2}", "#059669")
                 + DetailRow("Delivered On", $"{DateTime.UtcNow:MMMM dd, yyyy}", isLast: true);
        var inner =
            $"<tr><td>{EmailHeader("Delivery Confirmation")}</td></tr>" +
            $"<tr><td style=\"background:#ffffff;padding:32px;border:1px solid #e5e7eb;border-top:none;border-radius:0 0 8px 8px;\">" +
            $"<div style=\"text-align:center;margin-bottom:20px;\"><div style=\"font-size:48px;line-height:1;\">&#x2705;</div>" +
            $"<h2 style=\"font-family:Arial,sans-serif;font-size:20px;color:#059669;margin:10px 0 0;\">Order Delivered!</h2></div>" +
            $"<p style=\"font-family:Arial,sans-serif;font-size:15px;margin:0 0 12px;color:#1f2937;\">Hi <strong>{toName}</strong>,</p>" +
            $"<p style=\"font-family:Arial,sans-serif;font-size:14px;color:#6b7280;margin:0 0 20px;\">Your order has been successfully delivered. We hope you enjoy your groceries!</p>" +
            DetailBox("#f0fdf4", "#bbf7d0", rows) +
            $"<p style=\"font-family:Arial,sans-serif;font-size:14px;color:#6b7280;text-align:center;margin:0 0 8px;\">Enjoyed your order? Leave a review in the app! &#x2B50;</p>" +
            $"<p style=\"font-family:Arial,sans-serif;font-size:12px;color:#9ca3af;text-align:center;margin:0;\">Thank you for shopping with GroceryApp.</p>" +
            $"</td></tr>";
        await SendAsync(toEmail, subject, EmailWrapper(inner));
    }

    private async Task SendAsync(string toEmail, string subject, string htmlBody)
    {
        var smtp = _config.GetSection("Smtp");
        var host = smtp["Host"];
        var port = int.Parse(smtp["Port"] ?? "587");
        var enableSsl = bool.Parse(smtp["EnableSsl"] ?? "true");
        var userName = smtp["UserName"];
        var password = smtp["Password"];
        var passwordForAuth = RemoveWhitespace(password);
        var fromAddress = smtp["FromAddress"] ?? userName ?? "";
        var fromName = smtp["FromName"] ?? "GroceryApp";

        await WriteEmailLogAsync(
            "CONFIG",
            "SMTP effective config: " +
            $"Host={FormatConfigValue(host)}, " +
            $"Port={port}, " +
            $"EnableSsl={enableSsl}, " +
            $"UserName={MaskEmail(userName)}, " +
            $"FromAddress={MaskEmail(fromAddress)}, " +
            $"FromName={FormatConfigValue(fromName)}, " +
            $"PasswordConfigured={!string.IsNullOrWhiteSpace(password)}, " +
            $"PasswordLength={GetLength(password)}, " +
            $"PasswordLengthWithoutWhitespace={GetLength(passwordForAuth)}, " +
            $"PasswordShape={GetPasswordShape(password)}, " +
            $"PasswordWhitespaceIndexes={GetWhitespaceIndexes(password)}, " +
            $"PasswordSha256={GetSha256(password)}, " +
            $"PasswordWithoutWhitespaceSha256={GetSha256(passwordForAuth)}");

        if (string.IsNullOrWhiteSpace(host) || string.IsNullOrWhiteSpace(userName) ||
            string.IsNullOrWhiteSpace(password) || userName.Contains("your-email") ||
            userName.Contains("REPLACE_VIA_USER_SECRETS") || password.Contains("REPLACE_VIA_USER_SECRETS"))
        {
            var message = $"SMTP not configured; cannot send email to {toEmail}. Subject: {subject}";
            _logger.LogError("{Message}", message);
            await WriteEmailLogAsync("ERROR", message);
            throw new InvalidOperationException(message);
        }

        var attempts = passwordForAuth == password
            ? [new PasswordAttempt("configured", password)]
            : new[]
            {
                new PasswordAttempt("without-whitespace", passwordForAuth),
                new PasswordAttempt("configured", password)
            };

        Exception? lastException = null;

        foreach (var attempt in attempts)
        {
            try
            {
                await SendWithPasswordAsync(host, port, enableSsl, userName, attempt.Password, fromAddress, fromName, toEmail, subject, htmlBody);

                var message = $"Sent '{subject}' to {toEmail} via {host}:{port} using password variant '{attempt.Name}'.";
                _logger.LogInformation("{Message}", message);
                await WriteEmailLogAsync("SENT", message);
                return;
            }
            catch (Exception ex) when (IsSmtpAuthenticationFailure(ex) && attempt != attempts[^1])
            {
                lastException = ex;
                var retryMessage = $"SMTP authentication failed using password variant '{attempt.Name}'. Retrying with next variant.";
                _logger.LogWarning(ex, "{Message}", retryMessage);
                await WriteEmailLogAsync("WARN", $"{retryMessage} {ex.GetType().Name}: {ex.Message}");
            }
            catch (Exception ex)
            {
                lastException = ex;
                break;
            }
        }

        if (lastException is not null)
        {
            var message = $"Failed to send '{subject}' to {toEmail} via {host}:{port}. {lastException.GetType().Name}: {lastException.Message}";
            _logger.LogError(lastException, "{Message}", message);
            await WriteEmailLogAsync("ERROR", message);
            ExceptionDispatchInfo.Capture(lastException).Throw();
        }
    }

    private static async Task SendWithPasswordAsync(
        string host,
        int port,
        bool enableSsl,
        string userName,
        string password,
        string fromAddress,
        string fromName,
        string toEmail,
        string subject,
        string htmlBody)
    {
        using var client = new SmtpClient(host, port)
        {
            EnableSsl = enableSsl,
            UseDefaultCredentials = false,
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
    }

    private static bool IsSmtpAuthenticationFailure(Exception ex)
    {
        return ex is SmtpException smtpException &&
            smtpException.Message.Contains("authenticated", StringComparison.OrdinalIgnoreCase);
    }

    private sealed record PasswordAttempt(string Name, string Password);

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

    private static string FormatConfigValue(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? "[missing]" : value;
    }

    private static int GetLength(string? value)
    {
        return string.IsNullOrEmpty(value) ? 0 : value.Length;
    }

    private static string RemoveWhitespace(string? value)
    {
        if (string.IsNullOrEmpty(value)) return "";

        var chars = new char[value.Length];
        var index = 0;

        foreach (var character in value)
        {
            if (!char.IsWhiteSpace(character))
            {
                chars[index] = character;
                index++;
            }
        }

        return new string(chars, 0, index);
    }

    private static string GetPasswordShape(string? value)
    {
        if (string.IsNullOrEmpty(value)) return "[missing]";

        return string.Concat(value.Select(character => char.IsWhiteSpace(character) ? "_" : "*"));
    }

    private static string GetWhitespaceIndexes(string? value)
    {
        if (string.IsNullOrEmpty(value)) return "[]";

        var indexes = value
            .Select((character, index) => new { character, index })
            .Where(item => char.IsWhiteSpace(item.character))
            .Select(item => item.index.ToString());

        return $"[{string.Join(",", indexes)}]";
    }

    private static string GetSha256(string? value)
    {
        if (string.IsNullOrEmpty(value)) return "[missing]";

        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(value));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }

    private static string MaskEmail(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return "[missing]";

        var atIndex = value.IndexOf('@');
        if (atIndex <= 1) return "[redacted]";

        var local = value[..atIndex];
        var domain = value[(atIndex + 1)..];
        var visibleLocal = local.Length <= 2 ? local[0].ToString() : local[..2];

        return $"{visibleLocal}***@{domain}";
    }
}
