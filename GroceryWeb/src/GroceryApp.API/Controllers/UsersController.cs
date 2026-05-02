using GroceryApp.Application.DTOs.Addresses;
using GroceryApp.Application.DTOs.PaymentMethods;
using GroceryApp.Application.DTOs.UserSettings;
using GroceryApp.Application.DTOs.Vouchers;
using GroceryApp.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.API.Controllers;

[ApiController]
[Route("api/users")]
[Authorize(Roles = "Admin")]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly IUserSettingService _userSettingService;

    public UsersController(IUserService userService, IUserSettingService userSettingService)
    {
        _userService = userService;
        _userSettingService = userSettingService;
    }

    // ── Users ──────────────────────────────────────────────────────────────────

    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null)
    {
        var result = await _userService.GetAllUsersAsync(page, pageSize, search);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var user = await _userService.GetByIdAsync(id);
        return user is null ? NotFound() : Ok(user);
    }

    [HttpPost("{id:guid}/toggle-active")]
    public async Task<IActionResult> ToggleActive(Guid id)
    {
        var result = await _userService.ToggleActiveAsync(id);
        return result ? Ok() : NotFound();
    }

    [HttpGet("roles")]
    public async Task<IActionResult> GetRoles()
    {
        return Ok(await _userService.GetAvailableRolesAsync());
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateUserRequest request)
    {
        var user = await _userService.CreateUserAsync(request);
        return Ok(user);
    }

    [HttpPut("{id:guid}/roles")]
    public async Task<IActionResult> UpdateRoles(Guid id, [FromBody] UpdateUserRolesRequest request)
    {
        var user = await _userService.UpdateUserRolesAsync(id, request);
        return user is null ? NotFound() : Ok(user);
    }

    // ── Verification ───────────────────────────────────────────────────────────

    [HttpPost("{id:guid}/set-email-verified")]
    public async Task<IActionResult> SetEmailVerified(Guid id, [FromBody] SetVerifiedRequest request)
    {
        var result = await _userService.SetEmailVerifiedAsync(id, request.Verified);
        return result ? Ok() : NotFound();
    }

    [HttpPost("{id:guid}/set-phone-verified")]
    public async Task<IActionResult> SetPhoneVerified(Guid id, [FromBody] SetVerifiedRequest request)
    {
        var result = await _userService.SetPhoneVerifiedAsync(id, request.Verified);
        return result ? Ok() : NotFound();
    }

    [HttpPost("{id:guid}/send-email-verification")]
    public async Task<IActionResult> SendEmailVerification(Guid id)
    {
        var user = await _userService.GetByIdAsync(id);
        if (user is null) return NotFound();

        var result = await _userService.SendEmailVerificationAsync(id);
        return result
            ? Ok(new { message = "Email verification code sent." })
            : StatusCode(StatusCodes.Status500InternalServerError, new { error = "Failed to send email verification code. Check SMTP settings and API email log." });
    }

    [HttpPost("{id:guid}/send-phone-verification")]
    public async Task<IActionResult> SendPhoneVerification(Guid id)
    {
        var result = await _userService.SendPhoneVerificationAsync(id);
        return result ? Ok() : NotFound();
    }

    // ── Addresses ──────────────────────────────────────────────────────────────

    [HttpGet("{id:guid}/addresses")]
    public async Task<IActionResult> GetAddresses(Guid id)
    {
        var addresses = await _userService.GetUserAddressesAsync(id);
        return Ok(addresses);
    }

    [HttpPost("{id:guid}/addresses")]
    public async Task<IActionResult> CreateAddress(Guid id, [FromBody] CreateAddressRequest request)
    {
        var address = await _userService.AdminCreateAddressAsync(id, request);
        return Ok(address);
    }

    [HttpPut("{id:guid}/addresses/{addressId:guid}")]
    public async Task<IActionResult> UpdateAddress(Guid id, Guid addressId, [FromBody] UpdateAddressRequest request)
    {
        var address = await _userService.AdminUpdateAddressAsync(id, addressId, request);
        return address is null ? NotFound() : Ok(address);
    }

    [HttpDelete("{id:guid}/addresses/{addressId:guid}")]
    public async Task<IActionResult> DeleteAddress(Guid id, Guid addressId)
    {
        var result = await _userService.AdminDeleteAddressAsync(id, addressId);
        return result ? NoContent() : NotFound();
    }

    // ── Orders ─────────────────────────────────────────────────────────────────

    [HttpGet("{id:guid}/orders")]
    public async Task<IActionResult> GetOrders(Guid id)
    {
        var orders = await _userService.GetUserOrdersAsync(id);
        return Ok(orders);
    }

    // ── Payment Methods ────────────────────────────────────────────────────────

    [HttpGet("{id:guid}/payment-methods")]
    public async Task<IActionResult> GetPaymentMethods(Guid id)
    {
        var methods = await _userService.GetUserPaymentMethodsAsync(id);
        return Ok(methods);
    }

    [HttpPost("{id:guid}/payment-methods")]
    public async Task<IActionResult> CreatePaymentMethod(Guid id, [FromBody] CreatePaymentMethodRequest request)
    {
        var method = await _userService.AdminCreatePaymentMethodAsync(id, request);
        return Ok(method);
    }

    [HttpPut("{id:guid}/payment-methods/{pmId:guid}")]
    public async Task<IActionResult> UpdatePaymentMethod(Guid id, Guid pmId, [FromBody] UpdatePaymentMethodRequest request)
    {
        var method = await _userService.AdminUpdatePaymentMethodAsync(id, pmId, request);
        return method is null ? NotFound() : Ok(method);
    }

    [HttpDelete("{id:guid}/payment-methods/{pmId:guid}")]
    public async Task<IActionResult> DeletePaymentMethod(Guid id, Guid pmId)
    {
        var result = await _userService.AdminDeletePaymentMethodAsync(id, pmId);
        return result ? NoContent() : NotFound();
    }

    // ── Vouchers ───────────────────────────────────────────────────────────────

    [HttpGet("{id:guid}/vouchers")]
    public async Task<IActionResult> GetVouchers(Guid id)
    {
        var vouchers = await _userService.GetUserVouchersAsync(id);
        return Ok(vouchers);
    }

    [HttpGet("{id:guid}/devices")]
    public async Task<IActionResult> GetDevices(Guid id)
    {
        var devices = await _userService.GetUserDevicesAsync(id);
        return Ok(devices);
    }

    [HttpGet("{id:guid}/notification-settings")]
    public async Task<IActionResult> GetNotificationSettings(Guid id)
    {
        var user = await _userService.GetByIdAsync(id);
        if (user is null) return NotFound();

        var settings = await _userSettingService.GetNotificationSettingsAsync(id);
        return Ok(settings);
    }

    [HttpPut("{id:guid}/notification-settings")]
    public async Task<IActionResult> UpdateNotificationSettings(Guid id, [FromBody] NotificationSettingsDto request)
    {
        var user = await _userService.GetByIdAsync(id);
        if (user is null) return NotFound();

        var settings = await _userSettingService.UpdateNotificationSettingsAsync(id, request);
        return Ok(settings);
    }

    [HttpPost("{id:guid}/vouchers")]
    public async Task<IActionResult> AssignVoucher(Guid id, [FromBody] AssignVoucherRequest request)
    {
        try
        {
            var uv = await _userService.AssignVoucherAsync(id, request.VoucherId);
            return Ok(uv);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpDelete("{id:guid}/vouchers/{userVoucherId:guid}")]
    public async Task<IActionResult> RevokeVoucher(Guid id, Guid userVoucherId)
    {
        var result = await _userService.RevokeVoucherAsync(id, userVoucherId);
        return result ? NoContent() : NotFound();
    }
}

public class SetVerifiedRequest
{
    public bool Verified { get; set; }
}
