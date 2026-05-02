using GroceryApp.Application.DTOs.Auth;
using GroceryApp.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace GroceryApp.API.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        var result = await _authService.RegisterAsync(request);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        var result = await _authService.LoginAsync(request);
        if (result.Success) return Ok(result);
        if (result.RequiresEmailVerification) return Ok(result);
        return BadRequest(result); // Use 400 not 401 — 401 is reserved for missing/expired token
    }

    [HttpPost("verify-email")]
    public async Task<IActionResult> VerifyEmail([FromBody] VerifyEmailRequest request)
    {
        var result = await _authService.VerifyEmailAsync(request);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    /// <summary>Authenticated user requests a new email verification code.</summary>
    [HttpPost("send-email-code")]
    [Authorize]
    public async Task<IActionResult> SendEmailCode()
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (userId is null) return Unauthorized();
        var result = await _authService.SendEmailVerificationCodeAsync(Guid.Parse(userId));
        return result ? Ok(new { message = "Verification code sent." }) : BadRequest(new { error = "Failed to send code." });
    }

    /// <summary>Authenticated user requests a new phone verification code.</summary>
    [HttpPost("send-phone-code")]
    [Authorize]
    public async Task<IActionResult> SendPhoneCode()
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (userId is null) return Unauthorized();
        var result = await _authService.SendPhoneVerificationCodeAsync(Guid.Parse(userId));
        return result ? Ok(new { message = "Verification code sent." }) : BadRequest(new { error = "Failed to send code." });
    }

    [HttpPost("verify-phone")]
    [Authorize]
    public async Task<IActionResult> VerifyPhone([FromBody] VerifyPhoneRequest request)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (userId is null) return Unauthorized();
        var result = await _authService.VerifyPhoneAsync(Guid.Parse(userId), request);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    [HttpGet("me")]
    [Authorize]
    public async Task<IActionResult> Me()
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (userId is null) return Unauthorized();
        var user = await _authService.GetCurrentUserAsync(Guid.Parse(userId));
        return user is null ? NotFound() : Ok(user);
    }
}
