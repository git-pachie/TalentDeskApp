using System.Net;
using System.Net.Mail;
using GroceryApp.Admin.Filters;
using GroceryApp.Admin.Models;
using GroceryApp.Admin.Services;
using GroceryApp.Admin.Utilities;
using Microsoft.AspNetCore.Mvc;
using QuestPDF.Fluent;
using QuestPDF.Infrastructure;

namespace GroceryApp.Admin.Controllers;

[AdminAuth]
public class OrdersController : Controller
{
    private readonly ApiClient _apiClient;
    private readonly IConfiguration _config;

    public OrdersController(ApiClient apiClient, IConfiguration config)
    {
        _apiClient = apiClient;
        _config = config;
    }

    public async Task<IActionResult> Index(
        int page = 1,
        string? search = null,
        string? status = null,
        string? dateFrom = null,
        string? dateTo = null,
        int pageSize = 60)
    {
        var qs = $"/api/orders/search?page={page}&pageSize={pageSize}";
        if (!string.IsNullOrWhiteSpace(search))   qs += $"&search={Uri.EscapeDataString(search)}";
        if (!string.IsNullOrWhiteSpace(status))   qs += $"&status={Uri.EscapeDataString(status)}";
        if (!string.IsNullOrWhiteSpace(dateFrom)) qs += $"&dateFrom={Uri.EscapeDataString(dateFrom)}";
        if (!string.IsNullOrWhiteSpace(dateTo))   qs += $"&dateTo={Uri.EscapeDataString(dateTo)}";

        var result = await _apiClient.GetAsync<PagedResultModel<OrderModel>>(qs);

        ViewBag.Search   = search;
        ViewBag.Status   = status;
        ViewBag.DateFrom = dateFrom;
        ViewBag.DateTo   = dateTo;
        ViewBag.Page     = page;
        ViewBag.PageSize = pageSize;

        return View(result ?? new PagedResultModel<OrderModel>());
    }

    // Dropdown search — returns JSON for autocomplete; if 1 result redirects to detail
    public async Task<IActionResult> QuickSearch(string q)
    {
        if (string.IsNullOrWhiteSpace(q))
            return Json(new List<object>());

        var qs = $"/api/orders/search?page=1&pageSize=10&search={Uri.EscapeDataString(q)}";
        var result = await _apiClient.GetAsync<PagedResultModel<OrderModel>>(qs);
        var items = result?.Items ?? [];

        return Json(items.Select(o => new
        {
            id = o.Id,
            orderNumber = o.OrderNumber,
            customerName = o.CustomerName,
            total = o.TotalAmount,
            status = o.Status,
            date = o.CreatedAt.ToString("MMM dd, yyyy")
        }));
    }

    public async Task<IActionResult> Detail(Guid id)
    {
        var order = await _apiClient.GetAsync<OrderModel>($"/api/orders/admin/{id}");
        if (order is null) return NotFound();
        ViewBag.ApiBaseUrl = _config["ApiBaseUrl"] ?? string.Empty;
        ViewBag.ReviewImageBase = AdminUrlBuilder.BuildUploadsBase(_config["ApiBaseUrl"], "reviews");
        return View(order);
    }

    [HttpPost]
    public async Task<IActionResult> UpdateStatus(Guid id, string status, string? returnUrl = null)
    {
        // If changing to OutForDelivery, rider assignment is handled separately via AssignRider
        await _apiClient.PutAsync<object, object>($"/api/orders/{id}/status", new { status });
        if (!string.IsNullOrEmpty(returnUrl) && returnUrl == "index")
            return RedirectToAction(nameof(Index));
        return RedirectToAction(nameof(Detail), new { id });
    }

    [HttpPost]
    public async Task<IActionResult> AssignRider(Guid id, Guid riderId)
    {
        await _apiClient.PutAsync<object, object>($"/api/orders/{id}/assign-rider", new { riderId });
        return RedirectToAction(nameof(Detail), new { id });
    }

    // ── Export PDF ─────────────────────────────────────────────────────────────

    public async Task<IActionResult> ExportPdf(Guid id)
    {
        var order = await _apiClient.GetAsync<OrderModel>($"/api/orders/admin/{id}");
        if (order is null) return NotFound();

        QuestPDF.Settings.License = LicenseType.Community;

        var doc = new OrderPdfDocument(order);
        var bytes = doc.GeneratePdf();

        return File(bytes, "application/pdf", $"Order-{order.OrderNumber}.pdf");
    }

    // ── Print (returns printable HTML page) ───────────────────────────────────

    public async Task<IActionResult> Print(Guid id)
    {
        var order = await _apiClient.GetAsync<OrderModel>($"/api/orders/admin/{id}");
        if (order is null) return NotFound();
        return View("Print", order);
    }

    // ── Send Email ─────────────────────────────────────────────────────────────

    [HttpPost]
    public async Task<IActionResult> SendEmail(Guid id, string toEmail, string? message)
    {
        var order = await _apiClient.GetAsync<OrderModel>($"/api/orders/admin/{id}");
        if (order is null) return NotFound();

        try
        {
            QuestPDF.Settings.License = LicenseType.Community;
            var pdfBytes = new OrderPdfDocument(order).GeneratePdf();

            // Admin SMTP is only used for invoice emails. User verification emails are sent by the API.
            var smtp = _config.GetSection("Smtp");
            using var client = new SmtpClient(smtp["Host"], int.Parse(smtp["Port"] ?? "587"))
            {
                EnableSsl = bool.Parse(smtp["EnableSsl"] ?? "true"),
                UseDefaultCredentials = false,
                Credentials = new NetworkCredential(smtp["UserName"], RemoveWhitespace(smtp["Password"]))
            };

            var from = new MailAddress(smtp["FromAddress"]!, smtp["FromName"] ?? "GroceryApp Admin");
            var to = new MailAddress(toEmail);

            using var mail = new MailMessage(from, to)
            {
                Subject = $"Order Invoice — {order.OrderNumber}",
                IsBodyHtml = true,
                Body = BuildEmailBody(order, message)
            };

            mail.Attachments.Add(new Attachment(
                new MemoryStream(pdfBytes),
                $"Order-{order.OrderNumber}.pdf",
                "application/pdf"));

            await client.SendMailAsync(mail);

            TempData["Success"] = $"Invoice sent to {toEmail}";
        }
        catch (Exception ex)
        {
            TempData["Error"] = $"Failed to send email: {ex.Message}";
        }

        return RedirectToAction(nameof(Detail), new { id });
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private static string BuildEmailBody(OrderModel order, string? customMessage)
    {
        var items = string.Join("", order.Items.Select(i =>
            $"<tr><td style='padding:6px 8px;border-bottom:1px solid #f0f0f0;'>{i.ProductName}</td>" +
            $"<td style='padding:6px 8px;border-bottom:1px solid #f0f0f0;text-align:center;'>{i.Quantity}</td>" +
            $"<td style='padding:6px 8px;border-bottom:1px solid #f0f0f0;text-align:right;'>₱{i.TotalPrice:N2}</td></tr>"));

        var customNote = string.IsNullOrWhiteSpace(customMessage)
            ? ""
            : $"<p style='background:#f9fafb;border-left:3px solid #059669;padding:10px 14px;margin:16px 0;font-size:14px;'>{customMessage}</p>";

        return $"""
        <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;color:#1f2937;">
          <div style="background:linear-gradient(135deg,#059669,#047857);padding:24px 32px;border-radius:8px 8px 0 0;">
            <h1 style="color:#fff;margin:0;font-size:22px;">GroceryApp</h1>
            <p style="color:#d1fae5;margin:4px 0 0;font-size:13px;">Order Invoice</p>
          </div>
          <div style="background:#fff;padding:24px 32px;border:1px solid #e5e7eb;border-top:none;border-radius:0 0 8px 8px;">
            <h2 style="font-size:18px;margin:0 0 4px;">{order.OrderNumber}</h2>
            <p style="color:#6b7280;font-size:13px;margin:0 0 16px;">Placed on {order.CreatedAt:MMMM dd, yyyy 'at' hh:mm tt}</p>
            {(order.DeliveryDate.HasValue
                ? $"<p style='color:#6b7280;font-size:13px;margin:0 0 16px;'>Delivery schedule: {order.DeliveryDate.Value:MMMM dd, yyyy}" +
                  $"{(string.IsNullOrWhiteSpace(order.DeliveryTimeSlot) ? " (Anytime)" : $" at {order.DeliveryTimeSlot}")}</p>"
                : "")}
            {customNote}
            <table style="width:100%;border-collapse:collapse;margin-bottom:16px;">
              <thead>
                <tr style="background:#f9fafb;">
                  <th style="padding:8px;text-align:left;font-size:12px;color:#6b7280;border-bottom:2px solid #e5e7eb;">Product</th>
                  <th style="padding:8px;text-align:center;font-size:12px;color:#6b7280;border-bottom:2px solid #e5e7eb;">Qty</th>
                  <th style="padding:8px;text-align:right;font-size:12px;color:#6b7280;border-bottom:2px solid #e5e7eb;">Total</th>
                </tr>
              </thead>
              <tbody>{items}</tbody>
            </table>
            <div style="text-align:right;border-top:2px solid #e5e7eb;padding-top:12px;">
              <table style="margin-left:auto;font-size:13px;">
                <tr><td style="padding:2px 8px;color:#6b7280;">Subtotal</td><td style="padding:2px 0;text-align:right;">₱{order.SubTotal:N2}</td></tr>
                {(order.DiscountAmount > 0 ? $"<tr><td style='padding:2px 8px;color:#059669;'>Discount</td><td style='padding:2px 0;text-align:right;color:#059669;'>-₱{order.DiscountAmount:N2}</td></tr>" : "")}
                <tr><td style="padding:2px 8px;color:#6b7280;">Delivery Fee</td><td style="padding:2px 0;text-align:right;">₱{order.DeliveryFee:N2}</td></tr>
                <tr><td style="padding:2px 8px;color:#6b7280;">Platform Fee</td><td style="padding:2px 0;text-align:right;">₱{order.PlatformFee:N2}</td></tr>
                <tr><td style="padding:2px 8px;color:#6b7280;">Other Charges</td><td style="padding:2px 0;text-align:right;">₱{order.OtherCharges:N2}</td></tr>
                <tr style="font-weight:bold;font-size:15px;"><td style="padding:6px 8px;border-top:1px solid #e5e7eb;">Total</td><td style="padding:6px 0;text-align:right;border-top:1px solid #e5e7eb;color:#059669;">₱{order.TotalAmount:N2}</td></tr>
              </table>
            </div>
            <p style="font-size:12px;color:#9ca3af;margin-top:24px;text-align:center;">
              The PDF invoice is attached to this email.<br/>
              Thank you for shopping with GroceryApp.
            </p>
          </div>
        </div>
        """;
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
}
