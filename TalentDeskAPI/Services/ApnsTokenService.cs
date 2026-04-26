using System.Security.Cryptography;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using TalentDeskAPI.Configuration;

namespace TalentDeskAPI.Services;

/// <summary>
/// Generates and caches JWT tokens for APNs token-based authentication.
/// Tokens are valid for up to 60 minutes; this service refreshes at 50 minutes.
/// </summary>
public class ApnsTokenService
{
    private readonly ApnsSettings _settings;
    private readonly ILogger<ApnsTokenService> _logger;
    private readonly Lock _lock = new();
    private string? _cachedToken;
    private DateTime _tokenExpiry = DateTime.MinValue;

    public ApnsTokenService(IOptions<ApnsSettings> settings, ILogger<ApnsTokenService> logger)
    {
        _settings = settings.Value;
        _logger = logger;
    }

    public string GetToken()
    {
        lock (_lock)
        {
            if (_cachedToken is not null && DateTime.UtcNow < _tokenExpiry)
                return _cachedToken;

            _cachedToken = GenerateToken();
            _tokenExpiry = DateTime.UtcNow.AddMinutes(50);
            _logger.LogDebug("Generated new APNs JWT token, expires at {Expiry}", _tokenExpiry);
            return _cachedToken;
        }
    }

    private string GenerateToken()
    {
        var p8Text = File.ReadAllText(_settings.P8PrivateKeyPath).Trim();

        // Strip PEM headers if present
        p8Text = p8Text
            .Replace("-----BEGIN PRIVATE KEY-----", "")
            .Replace("-----END PRIVATE KEY-----", "")
            .Replace("\n", "")
            .Replace("\r", "");

        var keyBytes = Convert.FromBase64String(p8Text);
        var ecdsa = ECDsa.Create();
        ecdsa.ImportPkcs8PrivateKey(keyBytes, out _);

        var securityKey = new ECDsaSecurityKey(ecdsa) { KeyId = _settings.KeyId };
        var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.EcdsaSha256);

        var now = DateTime.UtcNow;
        var descriptor = new SecurityTokenDescriptor
        {
            Issuer = _settings.TeamId,
            NotBefore = now,
            IssuedAt = now,
            Expires = now.AddMinutes(60),
            SigningCredentials = credentials
        };

        var handler = new JwtSecurityTokenHandler();
        var token = handler.CreateJwtSecurityToken(descriptor);

        token.Header["kid"] = _settings.KeyId;

        return handler.WriteToken(token);
    }
}
