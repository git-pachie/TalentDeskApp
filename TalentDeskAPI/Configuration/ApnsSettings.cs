namespace TalentDeskAPI.Configuration;

/// <summary>
/// APNs configuration bound from appsettings.json.
/// </summary>
public class ApnsSettings
{
    public const string SectionName = "Apns";

    /// <summary>
    /// Path to the .p8 private key file from Apple Developer portal.
    /// If relative, it is resolved against the app content root.
    /// </summary>
    public string? P8PrivateKeyPath { get; set; }

    /// <summary>
    /// Raw .p8 private key contents (PEM). Prefer setting this via user-secrets or env vars.
    /// If provided, <see cref="P8PrivateKeyPath"/> is not required.
    /// </summary>
    public string? P8PrivateKey { get; set; }

    /// <summary>
    /// The 10-character Key ID from Apple Developer portal.
    /// </summary>
    public required string KeyId { get; set; }

    /// <summary>
    /// The 10-character Team ID from Apple Developer portal.
    /// </summary>
    public required string TeamId { get; set; }

    /// <summary>
    /// The app bundle identifier (e.g. com.example.ClientRegistrationApp).
    /// </summary>
    public required string BundleId { get; set; }

    /// <summary>
    /// True to use the production APNs server, false for sandbox.
    /// </summary>
    public bool IsProduction { get; set; } = false;

    public string ServerUrl => IsProduction
        ? "https://api.push.apple.com"
        : "https://api.sandbox.push.apple.com";
}
