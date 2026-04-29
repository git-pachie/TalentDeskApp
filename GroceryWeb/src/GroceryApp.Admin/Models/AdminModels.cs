namespace GroceryApp.Admin.Models;

public class LoginViewModel
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class AuthResponseModel
{
    public bool Success { get; set; }
    public string? Token { get; set; }
    public UserModel? User { get; set; }
}

public class UserModel
{
    public Guid Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public List<string> Roles { get; set; } = [];
}

public class PagedResultModel<T>
{
    public List<T> Items { get; set; } = [];
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages { get; set; }
}

public class ProductModel
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public decimal? DiscountPrice { get; set; }
    public int StockQuantity { get; set; }
    public string? Unit { get; set; }
    public bool IsActive { get; set; }
    public string CategoryName { get; set; } = string.Empty;
}

public class CreateProductModel
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public decimal? DiscountPrice { get; set; }
    public int StockQuantity { get; set; }
    public string? Unit { get; set; }
    public Guid CategoryId { get; set; }
}

public class UpdateProductModel
{
    public string? Name { get; set; }
    public string? Description { get; set; }
    public decimal? Price { get; set; }
    public decimal? DiscountPrice { get; set; }
    public int? StockQuantity { get; set; }
    public string? Unit { get; set; }
    public bool? IsActive { get; set; }
    public Guid? CategoryId { get; set; }
}

public class CategoryModel
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsActive { get; set; }
    public int ProductCount { get; set; }
}

public class CreateCategoryModel
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
}

public class OrderModel
{
    public Guid Id { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class VoucherModel
{
    public Guid Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Type { get; set; } = string.Empty;
    public decimal Value { get; set; }
    public decimal MinimumSpend { get; set; }
    public int UsageLimit { get; set; }
    public int UsedCount { get; set; }
    public bool IsActive { get; set; }
    public DateTime ExpiryDate { get; set; }
}

public class CreateVoucherModel
{
    public string Code { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Type { get; set; } = "Percentage";
    public decimal Value { get; set; }
    public decimal? MaxDiscount { get; set; }
    public decimal MinimumSpend { get; set; }
    public int UsageLimit { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime ExpiryDate { get; set; }
}
