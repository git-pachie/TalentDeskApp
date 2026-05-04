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
    public string? PhoneNumber { get; set; }
    public string? ProfileImageUrl { get; set; }
    public bool IsActive { get; set; }
    public bool IsEmailVerified { get; set; }
    public bool IsPhoneVerified { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<string> Roles { get; set; } = [];
    public int OrderCount { get; set; }
}

public class CreateUserModel
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public List<string> Roles { get; set; } = [];
}

public class UserAddressModel
{
    public Guid Id { get; set; }
    public string Label { get; set; } = string.Empty;
    public string Street { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string Province { get; set; } = string.Empty;
    public string ZipCode { get; set; } = string.Empty;
    public string? Country { get; set; }
    public string? DeliveryInstructions { get; set; }
    public string? ContactNumber { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public bool IsDefault { get; set; }
}

public class UserPaymentMethodModel
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Detail { get; set; }
    public string PaymentType { get; set; } = string.Empty;
    public string? Icon { get; set; }
    public bool IsDefault { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class UserVoucherModel
{
    public Guid Id { get; set; }
    public Guid VoucherId { get; set; }
    public string VoucherCode { get; set; } = string.Empty;
    public string? VoucherDescription { get; set; }
    public string VoucherType { get; set; } = string.Empty;
    public decimal VoucherValue { get; set; }
    public DateTime ExpiryDate { get; set; }
    public bool IsUsed { get; set; }
    public DateTime? UsedAt { get; set; }
    public DateTime AssignedAt { get; set; }
    public string AssignedBy { get; set; } = string.Empty;
}

public class UserDeviceModel
{
    public Guid Id { get; set; }
    public Guid? UserId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string DeviceGuid { get; set; } = string.Empty;
    public string? OSVersion { get; set; }
    public string? HardwareVersion { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime LastLoginAt { get; set; }
}

public class NotificationSettingsModel
{
    public bool MarketingPromotions { get; set; }
    public bool ProductUpdates { get; set; }
    public bool NewsAnnouncements { get; set; }
    public bool TransactionsBilling { get; set; } = true;
    public bool AlertsCritical { get; set; } = true;
    public bool UsageActivity { get; set; }
    public bool AccountSecurity { get; set; } = true;
    public bool Reminders { get; set; }
    public bool MessagesSupport { get; set; }
    public bool PersonalizedRecommendations { get; set; }
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
    public Guid CategoryId { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public List<ProductCategoryItemModel> Categories { get; set; } = [];
    public List<ProductImageModel> Images { get; set; } = [];
    public double AverageRating { get; set; }
    public int ReviewCount { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class ProductCategoryItemModel
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
}

public class ProductImageModel
{
    public Guid Id { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public string FullUrl { get; set; } = string.Empty;
    public bool IsPrimary { get; set; }
    public int SortOrder { get; set; }
    public DateTime DateCreated { get; set; }
    public DateTime DateModified { get; set; }
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
    public List<Guid> CategoryIds { get; set; } = [];
    public List<CreateProductImageModel> Images { get; set; } = [];
}

public class CreateProductImageModel
{
    public string ImageUrl { get; set; } = string.Empty;
    public bool IsPrimary { get; set; }
    public int SortOrder { get; set; }
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
    public List<Guid>? CategoryIds { get; set; }
    public List<CreateProductImageModel>? Images { get; set; }
}

public class CategoryModel
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public string? Emoji { get; set; }
    public bool IsActive { get; set; }
    public int ProductCount { get; set; }
}

public class SpecialOfferModel
{
    public Guid Id { get; set; }
    public Guid? CategoryId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Subtitle { get; set; } = string.Empty;
    public string Emoji { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string BackgroundColorHex { get; set; } = string.Empty;
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class CreateSpecialOfferModel
{
    public Guid? CategoryId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Subtitle { get; set; } = string.Empty;
    public string Emoji { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string BackgroundColorHex { get; set; } = "#E8F3FF";
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
}

public class UpdateSpecialOfferModel
{
    public Guid? CategoryId { get; set; }
    public string? Title { get; set; }
    public string? Subtitle { get; set; }
    public string? Emoji { get; set; }
    public string? ImageUrl { get; set; }
    public string? BackgroundColorHex { get; set; }
    public int? SortOrder { get; set; }
    public bool? IsActive { get; set; }
}

public class TodayDealModel
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public ProductModel Product { get; set; } = new();
}

public class CreateTodayDealModel
{
    public Guid ProductId { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
}

public class UpdateTodayDealModel
{
    public Guid? ProductId { get; set; }
    public int? SortOrder { get; set; }
    public bool? IsActive { get; set; }
}

public class CreateCategoryModel
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public string? Emoji { get; set; }
}

public class UpdateCategoryModel
{
    public string? Name { get; set; }
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public string? Emoji { get; set; }
    public bool? IsActive { get; set; }
}

public class OrderModel
{
    public Guid Id { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public Guid UserId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string CustomerEmail { get; set; } = string.Empty;
    public string? CustomerPhone { get; set; }
    public decimal SubTotal { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal DeliveryFee { get; set; }
    public decimal PlatformFee { get; set; }
    public decimal OtherCharges { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? Notes { get; set; }
    public string? VoucherCode { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? DeliveryDate { get; set; }
    public string? DeliveryTimeSlot { get; set; }
    public Guid? RiderId { get; set; }
    public string? RiderName { get; set; }
    public string? RiderContact { get; set; }
    public DateTime? ActualDeliveryDate { get; set; }
    public List<OrderItemModel> Items { get; set; } = [];
    public OrderPaymentModel? Payment { get; set; }
    public OrderAddressModel? Address { get; set; }
    public List<OrderStatusHistoryModel> StatusHistory { get; set; } = [];
    public List<OrderReviewModel> Reviews { get; set; } = [];
}

public class OrderItemModel
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string? ProductImageUrl { get; set; }
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public decimal TotalPrice { get; set; }
    public string? Remarks { get; set; }
}

public class OrderPaymentModel
{
    public string Method { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime? PaidAt { get; set; }
}

public class OrderAddressModel
{
    public string Label { get; set; } = string.Empty;
    public string Street { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string Province { get; set; } = string.Empty;
    public string ZipCode { get; set; } = string.Empty;
    public string? ContactNumber { get; set; }
    public string? DeliveryInstructions { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
}

public class OrderReviewModel
{
    public Guid Id { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<OrderReviewPhotoModel> Photos { get; set; } = [];
}

public class OrderReviewPhotoModel
{
    public Guid Id { get; set; }
    public string PhotoUrl { get; set; } = string.Empty;
    public int SortOrder { get; set; }
}

public class OrderStatusHistoryModel
{
    public string Status { get; set; } = string.Empty;
    public string? Notes { get; set; }
    public string CreatedBy { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class VoucherModel
{
    public Guid Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Type { get; set; } = string.Empty;
    public decimal Value { get; set; }
    public decimal? MaxDiscount { get; set; }
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
    public int Type { get; set; } = 0; // 0 = Percentage, 1 = FixedAmount
    public decimal Value { get; set; }
    public decimal? MaxDiscount { get; set; }
    public decimal MinimumSpend { get; set; }
    public int UsageLimit { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime ExpiryDate { get; set; }
}

public class UpdateVoucherModel
{
    public string? Description { get; set; }
    public decimal? Value { get; set; }
    public decimal? MaxDiscount { get; set; }
    public decimal? MinimumSpend { get; set; }
    public int? UsageLimit { get; set; }
    public bool? IsActive { get; set; }
    public DateTime? ExpiryDate { get; set; }
}

public class ReviewModel
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public Guid ProductId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<ReviewPhotoModel> Photos { get; set; } = [];
}

public class ReviewPhotoModel
{
    public Guid Id { get; set; }
    public string PhotoUrl { get; set; } = string.Empty;
    public int SortOrder { get; set; }
}

public class DashboardStatsModel
{
    public int TotalProducts { get; set; }
    public int TotalOrders { get; set; }
    public int TotalUsers { get; set; }
    public int TotalCategories { get; set; }
    public int ActiveVouchers { get; set; }
    public int PendingOrders { get; set; }
    public decimal TotalRevenue { get; set; }
    public int TodayOrders { get; set; }
    public List<RecentOrderModel> RecentOrders { get; set; } = [];
}

public class RecentOrderModel
{
    public Guid Id { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class UploadResultModel
{
    public List<string> Urls { get; set; } = [];
}

public class RiderModel
{
    public Guid Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public int DeliveredOrderCount { get; set; }
}
