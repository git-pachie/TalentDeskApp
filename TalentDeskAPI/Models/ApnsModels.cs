namespace TalentDeskAPI.Models;

/// <summary>
/// Request payload for sending a push notification.
/// </summary>
public class PushNotificationRequest
{
    /// <summary>
    /// The APNs device token (hex string from the iOS app).
    /// </summary>
    public required string DeviceToken { get; set; }

    /// <summary>
    /// Notification title shown to the user.
    /// </summary>
    public required string Title { get; set; }

    /// <summary>
    /// Notification body text.
    /// </summary>
    public required string Body { get; set; }

    /// <summary>
    /// Optional badge count. Null leaves the badge unchanged.
    /// </summary>
    public int? Badge { get; set; }

    /// <summary>
    /// Optional sound name. Defaults to "default".
    /// </summary>
    public string Sound { get; set; } = "default";

    /// <summary>
    /// Optional custom data dictionary sent in the payload.
    /// </summary>
    public Dictionary<string, object>? CustomData { get; set; }
}

/// <summary>
/// Response returned after attempting to send a notification.
/// </summary>
public class PushNotificationResponse
{
    public bool Success { get; set; }
    public int StatusCode { get; set; }
    public string? Reason { get; set; }
    public string? ApnsId { get; set; }
}
