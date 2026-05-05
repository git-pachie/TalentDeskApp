namespace GroceryApp.Domain.Entities;

public class UserDevice
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid? UserId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string DeviceGuid { get; set; } = string.Empty;
    public string? OSVersion { get; set; }
    public string? HardwareVersion { get; set; }
    public string? PushToken { get; set; }
    public string? Platform { get; set; } // iOS / Android / Web
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    public DateTime LastLoginAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
}
