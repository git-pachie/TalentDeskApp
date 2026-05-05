using System.Security.Claims;
using GroceryApp.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.API.Controllers;

[ApiController]
[Route("api/user-devices")]
[Authorize]
public class UserDevicesController : ControllerBase
{
    private readonly IUserDeviceService _userDeviceService;

    public UserDevicesController(IUserDeviceService userDeviceService)
    {
        _userDeviceService = userDeviceService;
    }

    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    private string Email => User.FindFirstValue(ClaimTypes.Email) ?? string.Empty;

    /// <summary>
    /// Register/update the current user's device info (used for push notifications).
    /// </summary>
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterDeviceRequest request)
    {
        await _userDeviceService.RegisterLoginAsync(
            UserId,
            Email,
            request.DeviceGuid,
            request.OSVersion,
            request.HardwareVersion,
            request.PushToken,
            request.Platform);

        return Ok(new { success = true });
    }
}

public class RegisterDeviceRequest
{
    public string? DeviceGuid { get; set; }
    public string? OSVersion { get; set; }
    public string? HardwareVersion { get; set; }
    public string? PushToken { get; set; }
    public string? Platform { get; set; }
}

