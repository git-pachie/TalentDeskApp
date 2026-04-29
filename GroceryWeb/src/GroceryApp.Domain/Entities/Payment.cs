namespace GroceryApp.Domain.Entities;

public enum PaymentStatus
{
    Pending = 0,
    Paid = 1,
    Failed = 2,
    Refunded = 3
}

public enum PaymentMethod
{
    Card = 0,
    ApplePay = 1,
    GCash = 2,
    PayMaya = 3,
    CashOnDelivery = 4
}

public class Payment
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid OrderId { get; set; }
    public Guid UserId { get; set; }
    public decimal Amount { get; set; }
    public PaymentMethod Method { get; set; }
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    public string? ExternalTransactionId { get; set; }
    public string? ProviderReference { get; set; }
    public string? FailureReason { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? PaidAt { get; set; }

    // Navigation
    public Order Order { get; set; } = null!;
    public User User { get; set; } = null!;
}
