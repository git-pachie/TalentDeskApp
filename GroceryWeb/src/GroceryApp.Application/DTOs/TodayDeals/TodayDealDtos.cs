using GroceryApp.Application.DTOs.Products;

namespace GroceryApp.Application.DTOs.TodayDeals;

public class TodayDealDto
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public ProductDto Product { get; set; } = null!;
}

public class CreateTodayDealRequest
{
    public Guid ProductId { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
}

public class UpdateTodayDealRequest
{
    public Guid? ProductId { get; set; }
    public int? SortOrder { get; set; }
    public bool? IsActive { get; set; }
}
