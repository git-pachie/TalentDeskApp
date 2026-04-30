namespace GroceryApp.Application.DTOs.Orders;

public class OrderDto
{
    public Guid Id { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public decimal SubTotal { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal DeliveryFee { get; set; }
    public decimal PlatformFee { get; set; }
    public decimal OtherCharges { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
    public IEnumerable<OrderItemDto> Items { get; set; } = [];
    public PaymentSummaryDto? Payment { get; set; }
    public OrderAddressDto? Address { get; set; }
    public List<OrderStatusHistoryDto> StatusHistory { get; set; } = [];
    public List<OrderReviewDto> Reviews { get; set; } = [];
}

public class OrderItemDto
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string? ProductImageUrl { get; set; }
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public decimal TotalPrice { get; set; }
    public string? Remarks { get; set; }
}

public class PaymentSummaryDto
{
    public string Method { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime? PaidAt { get; set; }
}

public class OrderStatusHistoryDto
{
    public string Status { get; set; } = string.Empty;
    public string? Notes { get; set; }
    public string CreatedBy { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class CreateOrderRequest
{
    public Guid? AddressId { get; set; }
    public string? VoucherCode { get; set; }
    public string? Notes { get; set; }
    public decimal PlatformFee { get; set; } = 2m;
    public decimal OtherCharges { get; set; } = 1m;
}

public class OrderAddressDto
{
    public string Label { get; set; } = string.Empty;
    public string Street { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string Province { get; set; } = string.Empty;
    public string ZipCode { get; set; } = string.Empty;
    public string? DeliveryInstructions { get; set; }
    public string? ContactNumber { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
}

public class OrderReviewDto
{
    public Guid Id { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<OrderReviewPhotoDto> Photos { get; set; } = [];
}

public class OrderReviewPhotoDto
{
    public Guid Id { get; set; }
    public string PhotoUrl { get; set; } = string.Empty;
    public int SortOrder { get; set; }
}
