using GroceryApp.Admin.Filters;
using GroceryApp.Admin.Models;
using GroceryApp.Admin.Services;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json;

namespace GroceryApp.Admin.Controllers;

[AdminAuth]
public class UsersController : Controller
{
    private readonly ApiClient _apiClient;

    public UsersController(ApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    // ── List ───────────────────────────────────────────────────────────────────

    public async Task<IActionResult> Index(int page = 1, string? search = null)
    {
        var qs = $"/api/users?page={page}&pageSize=20";
        if (!string.IsNullOrWhiteSpace(search))
            qs += $"&search={Uri.EscapeDataString(search)}";

        var result = await _apiClient.GetAsync<PagedResultModel<UserModel>>(qs);
        ViewBag.Search = search;
        ViewBag.CurrentPage = page;
        return View(result);
    }

    // ── Detail (profile hub) ───────────────────────────────────────────────────

    public async Task<IActionResult> Detail(Guid id, string? tab = null)
    {
        var user = await _apiClient.GetAsync<UserModel>($"/api/users/{id}");
        if (user is null) return NotFound();

        var loadErrors = new List<string>();
        var addresses = await LoadListAsync<UserAddressModel>($"/api/users/{id}/addresses", "addresses", loadErrors);
        var orders = await LoadListAsync<OrderModel>($"/api/users/{id}/orders", "orders", loadErrors);
        var payments = await LoadListAsync<UserPaymentMethodModel>($"/api/users/{id}/payment-methods", "payment methods", loadErrors);
        var userVouchers = await LoadListAsync<UserVoucherModel>($"/api/users/{id}/vouchers", "assigned vouchers", loadErrors);
        var allVouchers = await LoadListAsync<VoucherModel>("/api/vouchers", "available vouchers", loadErrors);

        ViewBag.Addresses    = addresses;
        ViewBag.Orders       = orders;
        ViewBag.Payments     = payments;
        ViewBag.UserVouchers = userVouchers;
        ViewBag.AllVouchers  = allVouchers
            .Where(v => v.IsActive && v.ExpiryDate > DateTime.UtcNow).ToList();
        ViewBag.ActiveTab    = NormalizeTab(tab);
        ViewBag.LoadErrors   = loadErrors;

        return View(user);
    }

    // ── Toggle Active ──────────────────────────────────────────────────────────

    [HttpPost]
    public async Task<IActionResult> ToggleActive(Guid id)
    {
        await _apiClient.PostVoidAsync($"/api/users/{id}/toggle-active", new { });
        TempData["SuccessMessage"] = "Account status updated.";
        return RedirectToAction(nameof(Detail), new { id });
    }

    // ── Verification ───────────────────────────────────────────────────────────

    [HttpPost]
    public async Task<IActionResult> SetEmailVerified(Guid id, bool verified)
    {
        try
        {
            await _apiClient.PostVoidAsync($"/api/users/{id}/set-email-verified", new { verified });
            TempData["SuccessMessage"] = verified ? "Email marked as verified." : "Email verification revoked.";
        }
        catch (Exception ex)
        {
            TempData["ErrorMessage"] = $"Failed to update email verification: {ex.Message}";
        }
        return RedirectToAction(nameof(Detail), new { id });
    }

    [HttpPost]
    public async Task<IActionResult> SetPhoneVerified(Guid id, bool verified)
    {
        try
        {
            await _apiClient.PostVoidAsync($"/api/users/{id}/set-phone-verified", new { verified });
            TempData["SuccessMessage"] = verified ? "Mobile marked as verified." : "Mobile verification revoked.";
        }
        catch (Exception ex)
        {
            TempData["ErrorMessage"] = $"Failed to update mobile verification: {ex.Message}";
        }
        return RedirectToAction(nameof(Detail), new { id });
    }

    [HttpPost]
    public async Task<IActionResult> SendEmailVerification(Guid id)
    {
        await _apiClient.PostVoidAsync($"/api/users/{id}/send-email-verification", new { });
        TempData["SuccessMessage"] = "Email verification code sent.";
        return RedirectToAction(nameof(Detail), new { id });
    }

    [HttpPost]
    public async Task<IActionResult> SendPhoneVerification(Guid id)
    {
        await _apiClient.PostVoidAsync($"/api/users/{id}/send-phone-verification", new { });
        TempData["SuccessMessage"] = "SMS verification code sent.";
        return RedirectToAction(nameof(Detail), new { id });
    }

    // ── Addresses ──────────────────────────────────────────────────────────────

    [HttpPost]
    public async Task<IActionResult> AddAddress(Guid id, UserAddressModel model)
    {
        await _apiClient.PostAsync<object, object>($"/api/users/{id}/addresses", new
        {
            label = model.Label, street = model.Street, city = model.City,
            province = model.Province, zipCode = model.ZipCode,
            country = model.Country ?? "Philippines",
            deliveryInstructions = model.DeliveryInstructions,
            contactNumber = model.ContactNumber,
            latitude = model.Latitude, longitude = model.Longitude,
            isDefault = model.IsDefault
        });
        TempData["SuccessMessage"] = "Address added.";
        return RedirectToAction(nameof(Detail), new { id, tab = "addresses" });
    }

    [HttpPost]
    public async Task<IActionResult> EditAddress(Guid id, Guid addressId, UserAddressModel model)
    {
        await _apiClient.PutAsync<object, object>($"/api/users/{id}/addresses/{addressId}", new
        {
            label = model.Label, street = model.Street, city = model.City,
            province = model.Province, zipCode = model.ZipCode,
            country = model.Country,
            deliveryInstructions = model.DeliveryInstructions,
            contactNumber = model.ContactNumber,
            latitude = model.Latitude, longitude = model.Longitude,
            isDefault = (bool?)model.IsDefault
        });
        TempData["SuccessMessage"] = "Address updated.";
        return RedirectToAction(nameof(Detail), new { id, tab = "addresses" });
    }

    [HttpPost]
    public async Task<IActionResult> DeleteAddress(Guid id, Guid addressId)
    {
        await _apiClient.DeleteAsync($"/api/users/{id}/addresses/{addressId}");
        TempData["SuccessMessage"] = "Address deleted.";
        return RedirectToAction(nameof(Detail), new { id, tab = "addresses" });
    }

    // ── Payment Methods ────────────────────────────────────────────────────────

    [HttpPost]
    public async Task<IActionResult> AddPaymentMethod(Guid id, UserPaymentMethodModel model)
    {
        await _apiClient.PostAsync<object, object>($"/api/users/{id}/payment-methods", new
        {
            name = model.Name, detail = model.Detail,
            paymentType = model.PaymentType, icon = model.Icon,
            isDefault = model.IsDefault
        });
        TempData["SuccessMessage"] = "Payment method added.";
        return RedirectToAction(nameof(Detail), new { id, tab = "payments" });
    }

    [HttpPost]
    public async Task<IActionResult> EditPaymentMethod(Guid id, Guid pmId, UserPaymentMethodModel model)
    {
        await _apiClient.PutAsync<object, object>($"/api/users/{id}/payment-methods/{pmId}", new
        {
            name = model.Name, detail = model.Detail,
            paymentType = model.PaymentType, icon = model.Icon,
            isDefault = (bool?)model.IsDefault
        });
        TempData["SuccessMessage"] = "Payment method updated.";
        return RedirectToAction(nameof(Detail), new { id, tab = "payments" });
    }

    [HttpPost]
    public async Task<IActionResult> DeletePaymentMethod(Guid id, Guid pmId)
    {
        await _apiClient.DeleteAsync($"/api/users/{id}/payment-methods/{pmId}");
        TempData["SuccessMessage"] = "Payment method deleted.";
        return RedirectToAction(nameof(Detail), new { id, tab = "payments" });
    }

    // ── Vouchers ───────────────────────────────────────────────────────────────

    [HttpPost]
    public async Task<IActionResult> AssignVoucher(Guid id, Guid voucherId)
    {
        try
        {
            await _apiClient.PostAsync<object, object>($"/api/users/{id}/vouchers", new { voucherId });
            TempData["SuccessMessage"] = "Voucher assigned.";
        }
        catch (HttpRequestException ex) when (ex.Message.Contains("400"))
        {
            TempData["ErrorMessage"] = "Voucher is already assigned to this user or could not be assigned.";
        }
        catch
        {
            TempData["ErrorMessage"] = "Failed to assign voucher. Please try again.";
        }
        return RedirectToAction(nameof(Detail), new { id, tab = "vouchers" });
    }

    [HttpPost]
    public async Task<IActionResult> RevokeVoucher(Guid id, Guid userVoucherId)
    {
        await _apiClient.DeleteAsync($"/api/users/{id}/vouchers/{userVoucherId}");
        TempData["SuccessMessage"] = "Voucher revoked.";
        return RedirectToAction(nameof(Detail), new { id, tab = "vouchers" });
    }

    private static string NormalizeTab(string? tab) => tab switch
    {
        "orders" => "orders",
        "payments" => "payments",
        "vouchers" => "vouchers",
        _ => "addresses"
    };

    private async Task<List<T>> LoadListAsync<T>(string endpoint, string label, List<string> errors)
    {
        try
        {
            return await _apiClient.GetAsync<List<T>>(endpoint) ?? [];
        }
        catch (Exception ex) when (ex is HttpRequestException or JsonException or TaskCanceledException)
        {
            errors.Add($"Unable to load {label}.");
            return [];
        }
    }
}
