using GroceryApp.Application.DTOs.Orders;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace GroceryApp.Application.Services;

public class OrderService : IOrderService
{
    private readonly IRepository<Order> _orderRepo;
    private readonly IRepository<CartItem> _cartRepo;
    private readonly IRepository<Voucher> _voucherRepo;
    private readonly IRepository<OrderStatusHistory> _statusHistoryRepo;
    private readonly IRepository<Review> _reviewRepo;
    private readonly INotificationService _notificationService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly string _productImageBaseUrl;

    public OrderService(
        IRepository<Order> orderRepo,
        IRepository<CartItem> cartRepo,
        IRepository<Voucher> voucherRepo,
        IRepository<OrderStatusHistory> statusHistoryRepo,
        IRepository<Review> reviewRepo,
        INotificationService notificationService,
        IUnitOfWork unitOfWork,
        IConfiguration configuration)
    {
        _orderRepo = orderRepo;
        _cartRepo = cartRepo;
        _voucherRepo = voucherRepo;
        _statusHistoryRepo = statusHistoryRepo;
        _reviewRepo = reviewRepo;
        _notificationService = notificationService;
        _unitOfWork = unitOfWork;
        _productImageBaseUrl = (configuration["ImageUrls:ProductImage"] ?? "").TrimEnd('/');
    }

    public async Task<OrderDto> CreateOrderAsync(Guid userId, CreateOrderRequest request)
    {
        var cartItems = await _cartRepo.Query()
            .Include(c => c.Product)
            .Where(c => c.UserId == userId)
            .ToListAsync();

        if (cartItems.Count == 0)
            throw new InvalidOperationException("Cart is empty.");

        var subTotal = cartItems.Sum(c => (c.Product.DiscountPrice ?? c.Product.Price) * c.Quantity);
        decimal discountAmount = 0;
        Guid? voucherId = null;

        if (!string.IsNullOrWhiteSpace(request.VoucherCode))
        {
            var voucher = await _voucherRepo.FirstOrDefaultAsync(
                v => v.Code == request.VoucherCode && v.IsActive && v.ExpiryDate > DateTime.UtcNow);

            if (voucher is not null && subTotal >= voucher.MinimumSpend && voucher.UsedCount < voucher.UsageLimit)
            {
                discountAmount = voucher.Type == VoucherType.Percentage
                    ? Math.Min(subTotal * voucher.Value / 100, voucher.MaxDiscount ?? decimal.MaxValue)
                    : voucher.Value;

                voucher.UsedCount++;
                _voucherRepo.Update(voucher);
                voucherId = voucher.Id;
            }
        }

        var deliveryFee = subTotal >= 1500 ? 0 : 50; // Free delivery over ₱1500
        var platformFee = 2m;
        var otherCharges = 1m;

        var order = new Order
        {
            UserId = userId,
            OrderNumber = $"ORD-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString()[..6].ToUpper()}",
            SubTotal = subTotal,
            DiscountAmount = discountAmount,
            DeliveryFee = deliveryFee,
            PlatformFee = platformFee,
            OtherCharges = otherCharges,
            TotalAmount = subTotal - discountAmount + deliveryFee + platformFee + otherCharges,
            AddressId = request.AddressId,
            VoucherId = voucherId,
            Notes = request.Notes,
            Items = cartItems.Select(c => new OrderItem
            {
                ProductId = c.ProductId,
                ProductName = c.Product.Name,
                UnitPrice = c.Product.DiscountPrice ?? c.Product.Price,
                Quantity = c.Quantity,
                TotalPrice = (c.Product.DiscountPrice ?? c.Product.Price) * c.Quantity,
                Remarks = c.Remarks
            }).ToList()
        };

        await _orderRepo.AddAsync(order);

        // Record initial status
        await _statusHistoryRepo.AddAsync(new OrderStatusHistory
        {
            OrderId = order.Id,
            Status = "Pending",
            Notes = "Order placed",
            CreatedBy = "Customer"
        });

        // Clear cart
        _cartRepo.RemoveRange(cartItems);
        await _unitOfWork.SaveChangesAsync();

        await _notificationService.CreateNotificationAsync(
            userId, "Order Placed", $"Your order {order.OrderNumber} has been placed.", "order", order.Id.ToString());

        return MapToDto(order);
    }

    public async Task<IEnumerable<OrderDto>> GetUserOrdersAsync(Guid userId)
    {
        var orders = await _orderRepo.Query()
            .Include(o => o.Items).ThenInclude(i => i.Product).ThenInclude(p => p.Images)
            .Include(o => o.Payment)
            .Include(o => o.Address)
            .Include(o => o.StatusHistory)
            .Where(o => o.UserId == userId)
            .OrderByDescending(o => o.CreatedAt)
            .ToListAsync();

        var orderIds = orders.Select(o => o.Id).ToList();
        var reviews = await _reviewRepo.Query()
            .Include(r => r.User)
            .Include(r => r.Product)
            .Include(r => r.Photos)
            .Where(r => orderIds.Contains(r.OrderId))
            .ToListAsync();

        var reviewsByOrder = reviews.GroupBy(r => r.OrderId).ToDictionary(g => g.Key, g => g.AsEnumerable());

        return orders.Select(o => MapToDto(o, reviewsByOrder.GetValueOrDefault(o.Id)));
    }

    public async Task<OrderDto?> GetOrderByIdAsync(Guid userId, Guid orderId)
    {
        var order = await _orderRepo.Query()
            .Include(o => o.Items).ThenInclude(i => i.Product).ThenInclude(p => p.Images)
            .Include(o => o.Payment)
            .Include(o => o.Address)
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == orderId && o.UserId == userId);

        if (order is null) return null;

        var reviews = await _reviewRepo.Query()
            .Include(r => r.User)
            .Include(r => r.Product)
            .Include(r => r.Photos)
            .Where(r => r.OrderId == orderId)
            .ToListAsync();

        return MapToDto(order, reviews);
    }

    public async Task<OrderDto?> GetOrderByIdAdminAsync(Guid orderId)
    {
        var order = await _orderRepo.Query()
            .Include(o => o.Items).ThenInclude(i => i.Product).ThenInclude(p => p.Images)
            .Include(o => o.Payment)
            .Include(o => o.Address)
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == orderId);

        if (order is null) return null;

        var reviews = await _reviewRepo.Query()
            .Include(r => r.User)
            .Include(r => r.Product)
            .Include(r => r.Photos)
            .Where(r => r.OrderId == orderId)
            .ToListAsync();

        return MapToDto(order, reviews);
    }

    public async Task<OrderDto?> UpdateOrderStatusAsync(Guid orderId, string status)
    {
        var order = await _orderRepo.Query()
            .Include(o => o.Items).ThenInclude(i => i.Product).ThenInclude(p => p.Images)
            .Include(o => o.Payment)
            .Include(o => o.Address)
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == orderId);

        if (order is null) return null;

        if (Enum.TryParse<OrderStatus>(status, true, out var newStatus))
        {
            order.Status = newStatus;
            order.UpdatedAt = DateTime.UtcNow;
            _orderRepo.Update(order);

            // Record status change
            await _statusHistoryRepo.AddAsync(new OrderStatusHistory
            {
                OrderId = orderId,
                Status = newStatus.ToString(),
                Notes = $"Status changed to {newStatus}",
                CreatedBy = "Admin"
            });

            await _unitOfWork.SaveChangesAsync();

            await _notificationService.CreateNotificationAsync(
                order.UserId, "Order Updated", $"Your order {order.OrderNumber} is now {newStatus}.", "order", order.Id.ToString());
        }

        var reviews = await _reviewRepo.Query()
            .Include(r => r.User)
            .Include(r => r.Product)
            .Include(r => r.Photos)
            .Where(r => r.OrderId == orderId)
            .ToListAsync();

        return MapToDto(order, reviews);
    }

    public async Task<IEnumerable<OrderDto>> GetAllOrdersAsync(int page, int pageSize)
    {
        var orders = await _orderRepo.Query()
            .Include(o => o.Items).ThenInclude(i => i.Product).ThenInclude(p => p.Images)
            .Include(o => o.Payment)
            .Include(o => o.Address)
            .Include(o => o.StatusHistory)
            .OrderByDescending(o => o.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var orderIds = orders.Select(o => o.Id).ToList();
        var reviews = await _reviewRepo.Query()
            .Include(r => r.User)
            .Include(r => r.Product)
            .Include(r => r.Photos)
            .Where(r => orderIds.Contains(r.OrderId))
            .ToListAsync();

        var reviewsByOrder = reviews.GroupBy(r => r.OrderId).ToDictionary(g => g.Key, g => g.AsEnumerable());

        return orders.Select(o => MapToDto(o, reviewsByOrder.GetValueOrDefault(o.Id)));
    }

    private OrderDto MapToDto(Order order, IEnumerable<Review>? reviews = null)
    {
        return new OrderDto
        {
            Id = order.Id,
            OrderNumber = order.OrderNumber,
            SubTotal = order.SubTotal,
            DiscountAmount = order.DiscountAmount,
            DeliveryFee = order.DeliveryFee,
            PlatformFee = order.PlatformFee,
            OtherCharges = order.OtherCharges,
            TotalAmount = order.TotalAmount,
            Status = order.Status.ToString(),
            Notes = order.Notes,
            CreatedAt = order.CreatedAt,
            Items = order.Items.Select(i =>
            {
                var primaryImage = i.Product?.Images?.FirstOrDefault(img => img.IsPrimary)
                    ?? i.Product?.Images?.FirstOrDefault();
                return new OrderItemDto
                {
                    ProductId = i.ProductId,
                    ProductName = i.ProductName,
                    ProductImageUrl = BuildFullImageUrl(primaryImage?.ImageUrl),
                    UnitPrice = i.UnitPrice,
                    Quantity = i.Quantity,
                    TotalPrice = i.TotalPrice,
                    Remarks = i.Remarks
                };
            }),
            Payment = order.Payment is null ? null : new PaymentSummaryDto
            {
                Method = order.Payment.Method.ToString(),
                Status = order.Payment.Status.ToString(),
                PaidAt = order.Payment.PaidAt
            },
            Address = order.Address is null ? null : new OrderAddressDto
            {
                Label = order.Address.Label,
                Street = order.Address.Street,
                City = order.Address.City,
                Province = order.Address.Province,
                ZipCode = order.Address.ZipCode,
                DeliveryInstructions = order.Address.DeliveryInstructions,
                ContactNumber = order.Address.ContactNumber,
                Latitude = order.Address.Latitude,
                Longitude = order.Address.Longitude
            },
            StatusHistory = order.StatusHistory
                .OrderBy(h => h.CreatedAt)
                .Select(h => new OrderStatusHistoryDto
                {
                    Status = h.Status,
                    Notes = h.Notes,
                    CreatedBy = h.CreatedBy,
                    CreatedAt = h.CreatedAt
                }).ToList(),
            Reviews = (reviews ?? []).Select(r => new OrderReviewDto
            {
                Id = r.Id,
                UserName = r.User is not null ? $"{r.User.FirstName} {r.User.LastName}" : "Anonymous",
                ProductName = r.Product?.Name ?? "Unknown Product",
                Rating = r.Rating,
                Comment = r.Comment,
                CreatedAt = r.CreatedAt,
                Photos = r.Photos.OrderBy(p => p.SortOrder).Select(p => new OrderReviewPhotoDto
                {
                    Id = p.Id,
                    PhotoUrl = p.PhotoUrl,
                    SortOrder = p.SortOrder
                }).ToList()
            }).ToList()
        };
    }

    private string? BuildFullImageUrl(string? imageUrl)
    {
        if (string.IsNullOrEmpty(imageUrl)) return null;
        if (imageUrl.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
            imageUrl.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            return imageUrl;
        if (!string.IsNullOrEmpty(_productImageBaseUrl))
        {
            var fileName = imageUrl.Contains('/') ? imageUrl.Split('/').Last() : imageUrl;
            return $"{_productImageBaseUrl}/{fileName}";
        }
        return imageUrl;
    }
}
