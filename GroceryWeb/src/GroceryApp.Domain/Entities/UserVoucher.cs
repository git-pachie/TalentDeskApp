namespace GroceryApp.Domain.Entities;

public class UserVoucher
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public Guid VoucherId { get; set; }
    public bool IsUsed { get; set; }
    public DateTime? UsedAt { get; set; }
    public DateTime AssignedAt { get; set; } = DateTime.UtcNow;
    public string AssignedBy { get; set; } = "Admin";

    // Navigation
    public User User { get; set; } = null!;
    public Voucher Voucher { get; set; } = null!;
}
