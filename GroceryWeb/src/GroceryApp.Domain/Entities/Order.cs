namespace GroceryApp.Domain.Entities;

public enum OrderStatus
{
    Pending = 0,
    Paid = 1,
    Processing = 2,
    OutForDelivery = 3,
    Delivered = 4,
    Cancelled = 5
}

public class Order
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public decimal SubTotal { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal DeliveryFee { get; set; }
    public decimal PlatformFee { get; set; }
    public decimal OtherCharges { get; set; }
    public decimal TotalAmount { get; set; }
    public OrderStatus Status { get; set; } = OrderStatus.Pending;
    public Guid? AddressId { get; set; }
    public Guid? VoucherId { get; set; }
    public string? Notes { get; set; }
    public DateTime? DeliveryDate { get; set; }
    public string? DeliveryTimeSlot { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    // Navigation
    public User User { get; set; } = null!;
    public Address? Address { get; set; }
    public Voucher? Voucher { get; set; }
    public Payment? Payment { get; set; }
    public ICollection<OrderItem> Items { get; set; } = [];
    public ICollection<OrderStatusHistory> StatusHistory { get; set; } = [];
}
