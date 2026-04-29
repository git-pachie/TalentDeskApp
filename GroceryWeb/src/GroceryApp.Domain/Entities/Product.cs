namespace GroceryApp.Domain.Entities;

public class Product
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public decimal? DiscountPrice { get; set; }
    public int StockQuantity { get; set; }
    public string? Unit { get; set; } // kg, pcs, liters, etc.
    public bool IsActive { get; set; } = true;
    public Guid CategoryId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    // Navigation
    public Category Category { get; set; } = null!;
    public ICollection<ProductImage> Images { get; set; } = [];
    public ICollection<Review> Reviews { get; set; } = [];
    public ICollection<Favorite> Favorites { get; set; } = [];
}
