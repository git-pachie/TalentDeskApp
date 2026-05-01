using Microsoft.AspNetCore.Identity;

namespace GroceryApp.Domain.Entities;

public class User : IdentityUser<Guid>
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
    public bool IsEmailVerified { get; set; }
    public bool IsPhoneVerified { get; set; }
    public string? EmailVerificationCode { get; set; }
    public DateTime? EmailVerificationSentAt { get; set; }
    public string? PhoneVerificationCode { get; set; }
    public DateTime? PhoneVerificationSentAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    public ICollection<Order> Orders { get; set; } = [];
    public ICollection<CartItem> CartItems { get; set; } = [];
    public ICollection<Address> Addresses { get; set; } = [];
    public ICollection<Favorite> Favorites { get; set; } = [];
    public ICollection<Review> Reviews { get; set; } = [];
    public ICollection<Notification> Notifications { get; set; } = [];
    public ICollection<UserPaymentMethod> PaymentMethods { get; set; } = [];
    public ICollection<UserSetting> Settings { get; set; } = [];
    public ICollection<UserVoucher> UserVouchers { get; set; } = [];
    public ICollection<UserDevice> Devices { get; set; } = [];
}
