namespace GroceryApp.Domain.Entities;

public enum VoucherType
{
    Percentage = 0,
    FixedAmount = 1
}

public class Voucher
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Code { get; set; } = string.Empty;
    public string? Description { get; set; }
    public VoucherType Type { get; set; }
    public decimal Value { get; set; } // percentage or fixed amount
    public decimal? MaxDiscount { get; set; } // cap for percentage vouchers
    public decimal MinimumSpend { get; set; }
    public int UsageLimit { get; set; }
    public int UsedCount { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime StartDate { get; set; }
    public DateTime ExpiryDate { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public ICollection<UserVoucher> UserVouchers { get; set; } = [];
}
