namespace GroceryApp.Application.DTOs.Auth;

public class RegisterRequest
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? DeviceGuid { get; set; }
    public string? OSVersion { get; set; }
    public string? HardwareVersion { get; set; }
}

public class LoginRequest
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string? DeviceGuid { get; set; }
    public string? OSVersion { get; set; }
    public string? HardwareVersion { get; set; }
}

public class AuthResponse
{
    public bool Success { get; set; }
    public string? Token { get; set; }
    public string? RefreshToken { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public UserDto? User { get; set; }
    public IEnumerable<string> Errors { get; set; } = [];
    public bool RequiresEmailVerification { get; set; }
}

public class UserDto
{
    public Guid Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? ProfileImageUrl { get; set; }
    public IEnumerable<string> Roles { get; set; } = [];
    public bool IsEmailVerified { get; set; }
    public bool IsPhoneVerified { get; set; }
}

public class VerifyEmailRequest
{
    public string Email { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
}

public class VerifyEmailResponse
{
    public bool Success { get; set; }
    public string? Token { get; set; }
    public string? Error { get; set; }
}
