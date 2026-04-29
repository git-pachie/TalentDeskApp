namespace GroceryApp.Domain.Entities;

public class UserPaymentMethod
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string Name { get; set; } = string.Empty; // "My Visa", "GCash Wallet"
    public string? Detail { get; set; } // masked card number, phone, etc.
    public string PaymentType { get; set; } = "CreditCard"; // CreditCard, DebitCard, ApplePay, GCash, CashOnDelivery
    public string? Icon { get; set; }
    public bool IsDefault { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public User User { get; set; } = null!;
}
