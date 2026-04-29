namespace GroceryApp.Application.DTOs.Favorites;

public class FavoriteDto
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal? DiscountPrice { get; set; }
    public string? ImageUrl { get; set; }
    public DateTime AddedAt { get; set; }
}
