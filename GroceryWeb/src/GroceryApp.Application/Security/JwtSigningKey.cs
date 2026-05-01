using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace GroceryApp.Application.Security;

public static class JwtSigningKey
{
    private const int MinimumKeySizeInBytes = 32;

    public static SymmetricSecurityKey Create(IConfiguration configuration)
    {
        var key = configuration["Jwt:Key"];
        if (string.IsNullOrWhiteSpace(key))
        {
            throw new InvalidOperationException("JWT key is not configured. Set Jwt:Key to a secret with at least 32 UTF-8 bytes.");
        }

        var keyBytes = Encoding.UTF8.GetBytes(key);
        if (keyBytes.Length < MinimumKeySizeInBytes)
        {
            throw new InvalidOperationException(
                $"JWT key is too short for HS256. Set Jwt:Key to at least {MinimumKeySizeInBytes} UTF-8 bytes; current value is {keyBytes.Length} bytes.");
        }

        return new SymmetricSecurityKey(keyBytes);
    }
}
