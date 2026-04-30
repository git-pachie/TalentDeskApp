using GroceryApp.Admin.Filters;
using GroceryApp.Admin.Models;
using GroceryApp.Admin.Services;
using Microsoft.AspNetCore.Mvc;

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

    public async Task<IActionResult> Detail(Guid id)
    {
        var user = await _apiClient.GetAsync<UserModel>($"/api/users/{id}");
        if (user is null) return NotFound();

        // Load all sub-lists in parallel
        var addressesTask = _apiClient.GetAsync<List<UserAddressModel>>($"/api/users/{id}/addresses");
        var ordersTask = _apiClient.GetAsync<List<OrderModel>>($"/api/users/{id}/orders");
        var paymentsTask = _apiClient.GetAsync<List<UserPaymentMethodModel>>($"/api/users/{id}/payment-methods");
        var userVouchersTask = _apiClient.GetAsync<List<UserVoucherModel>>($"/api/users/{id}/vouchers");
        var allVouchersTask = _apiClient.GetAsync<List<VoucherModel>>("/api/vouchers");

        await Task.WhenAll(addressesTask, ordersTask, paymentsTask, userVouchersTask, allVouchersTask);

        ViewBag.Addresses = addressesTask.Result ?? [];
        ViewBag.Orders = ordersTask.Result ?? [];
        ViewBag.Payments = paymentsTask.Result ?? [];
        ViewBag.UserVouchers = userVouchersTask.Result ?? [];
        ViewBag.AllVouchers = (allVouchersTask.Result ?? [])
            .Where(v => v.IsActive && v.ExpiryDate > DateTime.UtcNow)
            .ToList();

        return View(user);
    }

    // ── Toggle Active ──────────────────────────────────────────────────────────

    [HttpPost]
    public async Task<IActionResult> ToggleActive(Guid id)
    {
        await _apiClient.PostAsync<object, object>($"/api/users/{id}/toggle-active", new { });
        return RedirectToAction(nameof(Detail), new { id });
    }

    // ── Verification ───────────────────────────────────────────────────────────

    [HttpPost]
    public async Task<IActionResult> SetEmailVerified(Guid id, bool verified)
    {
        await _apiClient.PostAsync<object, object>($"/api/users/{id}/set-email-verified", new { verified });
        return RedirectToAction(nameof(Detail), new { id });
    }

    [HttpPost]
    public async Task<IActionResult> SetPhoneVerified(Guid id, bool verified)
    {
        await _apiClient.PostAsync<object, object>($"/api/users/{id}/set-phone-verified", new { verified });
        return RedirectToAction(nameof(Detail), new { id });
    }

    [HttpPost]
    public async Task<IActionResult> SendEmailVerification(Guid id)
    {
        await _apiClient.PostAsync<object, object>($"/api/users/{id}/send-email-verification", new { });
        TempData["SuccessMessage"] = "Email verification code sent successfully.";
        return RedirectToAction(nameof(Detail), new { id });
    }

    [HttpPost]
    public async Task<IActionResult> SendPhoneVerification(Guid id)
    {
        await _apiClient.PostAsync<object, object>($"/api/users/{id}/send-phone-verification", new { });
        TempData["SuccessMessage"] = "SMS verification code sent successfully.";
        return RedirectToAction(nameof(Detail), new { id });
    }

    // ── Addresses ──────────────────────────────────────────────────────────────

    [HttpPost]
    public async Task<IActionResult> AddAddress(Guid id, UserAddressModel model)
    {
        await _apiClient.PostAsync<object, object>($"/api/users/{id}/addresses", new
        {
            label = model.Label,
            street = model.Street,
            city = model.City,
            province = model.Province,
            zipCode = model.ZipCode,
            country = model.Country ?? "Philippines",
            deliveryInstructions = model.DeliveryInstructions,
            contactNumber = model.ContactNumber,
            latitude = model.Latitude,
            longitude = model.Longitude,
            isDefault = model.IsDefault
        });
        return RedirectToAction(nameof(Detail), new { id });
    }

    [HttpPost]
    public async Task<IActionResult> EditAddress(Guid id, Guid addressId, UserAddressModel model)
    {
        await _apiClient.PutAsync<object, object>($"/api/users/{id}/addresses/{addressId}", new
        {
            label = model.Label,
            street = model.Street,
            city = model.City,
            province = model.Province,
            zipCode = model.ZipCode,
            country = model.Country,
            deliveryInstructions = model.DeliveryInstructions,
            contactNumber = model.ContactNumber,
            latitude = model.Latitude,
            longitude = model.Longitude,
            isDefault = (bool?)model.IsDefault
        });
        return RedirectToAction(nameof(Detail), new { id });
    }

    [HttpPost]
    public async Task<IActionResult> DeleteAddress(Guid id, Guid addressId)
    {
        await _apiClient.DeleteAsync($"/api/users/{id}/addresses/{addressId}");
        return RedirectToAction(nameof(Detail), new { id });
    }

    // ── Payment Methods ────────────────────────────────────────────────────────

    [HttpPost]
    public async Task<IActionResult> AddPaymentMethod(Guid id, UserPaymentMethodModel model)
    {
        await _apiClient.PostAsync<object, object>($"/api/users/{id}/payment-methods", new
        {
            name = model.Name,
            detail = model.Detail,
            paymentType = model.PaymentType,
            icon = model.Icon,
            isDefault = model.IsDefault
        });
        return RedirectToAction(nameof(Detail), new { id });
    }

    [HttpPost]
    public async Task<IActionResult> EditPaymentMethod(Guid id, Guid pmId, UserPaymentMethodModel model)
    {
        await _apiClient.PutAsync<object, object>($"/api/users/{id}/payment-methods/{pmId}", new
        {
            name = model.Name,
            detail = model.Detail,
            paymentType = model.PaymentType,
            icon = model.Icon,
            isDefault = (bool?)model.IsDefault
        });
        return RedirectToAction(nameof(Detail), new { id });
    }

    [HttpPost]
    public async Task<IActionResult> DeletePaymentMethod(Guid id, Guid pmId)
    {
        await _apiClient.DeleteAsync($"/api/users/{id}/payment-methods/{pmId}");
        return RedirectToAction(nameof(Detail), new { id });
    }

    // ── Vouchers ───────────────────────────────────────────────────────────────

    [HttpPost]
    public async Task<IActionResult> AssignVoucher(Guid id, Guid voucherId)
    {
        await _apiClient.PostAsync<object, object>($"/api/users/{id}/vouchers", new { voucherId });
        return RedirectToAction(nameof(Detail), new { id });
    }

    [HttpPost]
    public async Task<IActionResult> RevokeVoucher(Guid id, Guid userVoucherId)
    {
        await _apiClient.DeleteAsync($"/api/users/{id}/vouchers/{userVoucherId}");
        return RedirectToAction(nameof(Detail), new { id });
    }
}
