using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using GroceryApp.Application.DTOs.Auth;
using GroceryApp.Application.Interfaces;
using GroceryApp.Application.Security;
using GroceryApp.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace GroceryApp.Application.Services;

public class AuthService : IAuthService
{
    private readonly UserManager<User> _userManager;
    private readonly IConfiguration _configuration;
    private readonly IEmailService _emailService;
    private readonly IUserDeviceService _userDeviceService;

    public AuthService(
        UserManager<User> userManager,
        IConfiguration configuration,
        IEmailService emailService,
        IUserDeviceService userDeviceService)
    {
        _userManager = userManager;
        _configuration = configuration;
        _emailService = emailService;
        _userDeviceService = userDeviceService;
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
    {
        var existingUser = await _userManager.FindByEmailAsync(request.Email);
        if (existingUser is not null)
        {
            return new AuthResponse { Success = false, Errors = ["Email is already registered."] };
        }

        var user = new User
        {
            FirstName = request.FirstName,
            LastName = request.LastName,
            Email = request.Email,
            UserName = request.Email,
            PhoneNumber = request.PhoneNumber
        };

        var result = await _userManager.CreateAsync(user, request.Password);
        if (!result.Succeeded)
        {
            return new AuthResponse { Success = false, Errors = result.Errors.Select(e => e.Description) };
        }

        await _userManager.AddToRoleAsync(user, "User");
        await _userDeviceService.RegisterLoginAsync(
            user.Id,
            user.Email!,
            request.DeviceGuid,
            request.OSVersion,
            request.HardwareVersion);

        var roles = await _userManager.GetRolesAsync(user);
        if (!roles.Contains("Admin"))
        {
            if (!await TrySendVerificationCodeAsync(user))
            {
                return new AuthResponse { Success = false, Errors = ["Failed to send verification email."] };
            }

            return new AuthResponse
            {
                Success = false,
                RequiresEmailVerification = true,
                Errors = ["Please verify your email before logging in."]
            };
        }

        return await GenerateAuthResponse(user);
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request)
    {
        var user = await _userManager.FindByEmailAsync(request.Email);
        if (user is null)
            return new AuthResponse { Success = false, Errors = ["Invalid email or password."] };

        var validPassword = await _userManager.CheckPasswordAsync(user, request.Password);
        if (!validPassword)
            return new AuthResponse { Success = false, Errors = ["Invalid email or password."] };

        // Check email verification — skip for Admin role
        var roles = await _userManager.GetRolesAsync(user);
        if (!user.IsEmailVerified && !roles.Contains("Admin"))
        {
            if (!await TrySendVerificationCodeAsync(user))
            {
                return new AuthResponse { Success = false, Errors = ["Failed to send verification email."] };
            }

            return new AuthResponse
            {
                Success = false,
                RequiresEmailVerification = true,
                Errors = ["Please verify your email before logging in."]
            };
        }

        await _userDeviceService.RegisterLoginAsync(
            user.Id,
            user.Email!,
            request.DeviceGuid,
            request.OSVersion,
            request.HardwareVersion);
        return await GenerateAuthResponse(user);
    }

    public async Task<VerifyEmailResponse> VerifyEmailAsync(VerifyEmailRequest request)
    {
        var user = await _userManager.FindByEmailAsync(request.Email);
        if (user is null)
            return new VerifyEmailResponse { Success = false, Error = "User not found." };

        if (string.IsNullOrEmpty(user.EmailVerificationCode))
            return new VerifyEmailResponse { Success = false, Error = "No verification code was sent. Please log in again." };

        // Code expires after 10 minutes
        if (user.EmailVerificationSentAt.HasValue &&
            DateTime.UtcNow > user.EmailVerificationSentAt.Value.AddMinutes(10))
            return new VerifyEmailResponse { Success = false, Error = "Verification code has expired. Please log in again to get a new code." };

        if (user.EmailVerificationCode != request.Code.Trim())
            return new VerifyEmailResponse { Success = false, Error = "Incorrect code. Please try again." };

        // Mark verified
        user.IsEmailVerified = true;
        user.EmailVerificationCode = null;
        user.EmailVerificationSentAt = null;
        user.UpdatedAt = DateTime.UtcNow;
        await _userManager.UpdateAsync(user);

        // Do not block email verification if the confirmation email fails.
        var fullName = $"{user.FirstName} {user.LastName}".Trim();
        try
        {
            await _emailService.SendEmailVerifiedConfirmationAsync(user.Email!, fullName);
        }
        catch
        {
            // EmailService already writes the error to the application log file.
        }

        // Return a full auth token so the user is logged in immediately
        var authResponse = await GenerateAuthResponse(user);
        return new VerifyEmailResponse
        {
            Success = true,
            Token = authResponse.Token
        };
    }

    public async Task<bool> SendEmailVerificationCodeAsync(Guid userId)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user is null) return false;
        if (user.IsEmailVerified) return false; // already verified

        return await TrySendVerificationCodeAsync(user);
    }

    private async Task<bool> TrySendVerificationCodeAsync(User user)
    {
        var code = VerificationCodeGenerator.CreateFourDigitCode();
        user.EmailVerificationCode = code;
        user.EmailVerificationSentAt = DateTime.UtcNow;
        user.UpdatedAt = DateTime.UtcNow;
        await _userManager.UpdateAsync(user);

        var fullName = $"{user.FirstName} {user.LastName}".Trim();
        try
        {
            await _emailService.SendEmailVerificationCodeAsync(user.Email!, fullName, code);
            return true;
        }
        catch
        {
            // EmailService already writes the error to the application log file.
            return false;
        }
    }

    public async Task<DTOs.Auth.UserDto?> GetCurrentUserAsync(Guid userId)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user is null) return null;
        var roles = await _userManager.GetRolesAsync(user);
        return new DTOs.Auth.UserDto
        {
            Id = user.Id,
            FirstName = user.FirstName,
            LastName = user.LastName,
            Email = user.Email!,
            PhoneNumber = user.PhoneNumber,
            ProfileImageUrl = user.ProfileImageUrl,
            Roles = roles,
            IsEmailVerified = user.IsEmailVerified,
            IsPhoneVerified = user.IsPhoneVerified
        };
    }

    private async Task<AuthResponse> GenerateAuthResponse(User user)
    {
        var roles = await _userManager.GetRolesAsync(user);
        var token = GenerateJwtToken(user, roles);

        return new AuthResponse
        {
            Success = true,
            Token = token,
            ExpiresAt = DateTime.UtcNow.AddDays(7),
            User = new DTOs.Auth.UserDto
            {
                Id = user.Id,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Email = user.Email!,
                PhoneNumber = user.PhoneNumber,
                ProfileImageUrl = user.ProfileImageUrl,
                Roles = roles,
                IsEmailVerified = user.IsEmailVerified,
                IsPhoneVerified = user.IsPhoneVerified
            }
        };
    }

    private string GenerateJwtToken(User user, IList<string> roles)
    {
        var key = JwtSigningKey.Create(_configuration);

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Email, user.Email!),
            new(ClaimTypes.Name, $"{user.FirstName} {user.LastName}"),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        claims.AddRange(roles.Select(role => new Claim(ClaimTypes.Role, role)));

        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddDays(7),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
