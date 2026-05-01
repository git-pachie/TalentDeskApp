using GroceryApp.Application.DTOs.Auth;

namespace GroceryApp.Application.Interfaces;

public interface IAuthService
{
    Task<AuthResponse> RegisterAsync(RegisterRequest request);
    Task<AuthResponse> LoginAsync(LoginRequest request);
    Task<VerifyEmailResponse> VerifyEmailAsync(VerifyEmailRequest request);
    Task<bool> SendEmailVerificationCodeAsync(Guid userId);
    Task<DTOs.Auth.UserDto?> GetCurrentUserAsync(Guid userId);
}
