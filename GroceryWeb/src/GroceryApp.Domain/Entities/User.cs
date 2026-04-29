using Microsoft.AspNetCore.Identity;

namespace GroceryApp.Domain.Entities;

public class User : IdentityUser<Guid>
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    public ICollection<Order> Orders { get; set; } = [];
    public ICollection<CartItem> CartItems { get; set; } = [];
    public ICollection<Address> Addresses { get; set; } = [];
    public ICollection<Favorite> Favorites { get; set; } = [];
    public ICollection<Review> Reviews { get; set; } = [];
    public ICollection<Notification> Notifications { get; set; } = [];
}
