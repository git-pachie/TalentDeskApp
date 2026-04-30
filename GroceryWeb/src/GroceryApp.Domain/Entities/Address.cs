namespace GroceryApp.Domain.Entities;

public class Address
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string Label { get; set; } = string.Empty; // Home, Work, etc.
    public string Street { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string Province { get; set; } = string.Empty;
    public string ZipCode { get; set; } = string.Empty;
    public string? Country { get; set; } = "Philippines";
    public string? DeliveryInstructions { get; set; }
    public string? ContactNumber { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public bool IsDefault { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public User User { get; set; } = null!;
}
