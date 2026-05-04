using GroceryApp.Application.DTOs.Orders;
using GroceryApp.Application.Interfaces;
using GroceryApp.Application.Utilities;
using GroceryApp.Domain.Entities;
using Microsoft.AspNetCore.Identity;
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
    private readonly IEmailService _emailService;
    private readonly UserManager<User> _userManager;
    private readonly IUnitOfWork _unitOfWork;
    private readonly string _appBaseUrl;

    public OrderService(
        IRepository<Order> orderRepo,
        IRepository<CartItem> cartRepo,
        IRepository<Voucher> voucherRepo,
        IRepository<OrderStatusHistory> statusHistoryRepo,
        IRepository<Review> reviewRepo,
        INotificationService notificationService,
        IEmailService emailService,
        UserManager<User> userManager,
        IUnitOfWork unitOfWork,
        IConfiguration configuration)
    {
        _orderRepo = orderRepo;
        _cartRepo = cartRepo;
        _voucherRepo = voucherRepo;
        _statusHistoryRepo = statusHistoryRepo;
        _reviewRepo = reviewRepo;
        _notificationService = notificationService;
        _emailService = emailService;
        _userManager = userManager;
        _unitOfWork = unitOfWork;
        _appBaseUrl = (configuration["App:BaseUrl"] ?? "").TrimEnd('/');
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
        var platformFee = request.PlatformFee;
        var otherCharges = request.OtherCharges;

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
            // Parse the "yyyy-MM-dd" date string sent by the mobile client directly —
            // no DateTime involved so no UTC timezone shift can occur.
            DeliveryDate = !string.IsNullOrWhiteSpace(request.DeliveryDate) &&
                           DateOnly.TryParseExact(request.DeliveryDate, "yyyy-MM-dd", out var parsedDate)
                ? parsedDate.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc)
                : DateTime.UtcNow.Date.AddDays(1),
            DeliveryTimeSlot = string.IsNullOrWhiteSpace(request.DeliveryTimeSlot) ? null : request.DeliveryTimeSlot.Trim(),
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

        // Resolve user data before leaving the request scope, then send email in background.
        var userForEmail = await _userManager.FindByIdAsync(userId.ToString());
        if (userForEmail?.Email is not null)
        {
            var emailAddress    = userForEmail.Email;
            var fullName        = $"{userForEmail.FirstName} {userForEmail.LastName}".Trim();
            var orderNumber     = order.OrderNumber;
            var totalAmount     = order.TotalAmount;
            var deliveryDate    = order.DeliveryDate ?? DateTime.UtcNow.Date.AddDays(1);
            var timeSlot        = order.DeliveryTimeSlot;

            _ = Task.Run(async () =>
            {
                try
                {
                    await _emailService.SendOrderPlacedAsync(emailAddress, fullName, orderNumber, totalAmount, deliveryDate, timeSlot);
                }
                catch { /* Email failure must never affect order placement */ }
            });
        }

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
            .Include(o => o.Voucher)
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
            .Include(o => o.User)
            .Include(o => o.Voucher)
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
            if (newStatus == OrderStatus.Delivered)
                order.ActualDeliveryDate = DateTime.UtcNow;
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

            // Resolve user data synchronously before leaving the request scope,
            // then send the email in a background task (scoped services are disposed after the request).
            var userForEmail = await _userManager.FindByIdAsync(order.UserId.ToString());
            if (userForEmail?.Email is not null)
            {
                var emailAddress = userForEmail.Email;
                var fullName     = $"{userForEmail.FirstName} {userForEmail.LastName}".Trim();
                var orderNumber  = order.OrderNumber;
                var totalAmount  = order.TotalAmount;
                var deliveryDate = order.DeliveryDate;
                var timeSlot     = order.DeliveryTimeSlot;

                _ = Task.Run(async () =>
                {
                    try
                    {
                        switch (newStatus)
                        {
                            case OrderStatus.Cancelled:
                                await _emailService.SendOrderCancelledAsync(emailAddress, fullName, orderNumber, totalAmount);
                                break;
                            case OrderStatus.OutForDelivery:
                                await _emailService.SendOrderOutForDeliveryAsync(emailAddress, fullName, orderNumber, deliveryDate, timeSlot);
                                break;
                            case OrderStatus.Delivered:
                                await _emailService.SendOrderDeliveredAsync(emailAddress, fullName, orderNumber, totalAmount);
                                break;
                        }
                    }
                    catch { /* Email failure must never affect status update */ }
                });
            }
        }

        var reviews = await _reviewRepo.Query()
            .Include(r => r.User)
            .Include(r => r.Product)
            .Include(r => r.Photos)
            .Where(r => r.OrderId == orderId)
            .ToListAsync();

        return MapToDto(order, reviews);
    }

    public async Task<OrderDto?> AssignRiderAsync(Guid orderId, Guid riderId)
    {
        var order = await _orderRepo.Query()
            .Include(o => o.Items).ThenInclude(i => i.Product).ThenInclude(p => p.Images)
            .Include(o => o.Payment)
            .Include(o => o.Address)
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == orderId);
        if (order is null) return null;

        var rider = await _userManager.FindByIdAsync(riderId.ToString());
        if (rider is null) return null;

        order.RiderId = riderId;
        order.RiderName = $"{rider.FirstName} {rider.LastName}".Trim();
        order.RiderContact = rider.PhoneNumber;
        order.UpdatedAt = DateTime.UtcNow;
        _orderRepo.Update(order);
        await _unitOfWork.SaveChangesAsync();

        return MapToDto(order);
    }

    public async Task<IEnumerable<RiderDto>> GetRidersAsync()
    {
        var riders = await _userManager.GetUsersInRoleAsync("Rider");
        var result = new List<RiderDto>();
        foreach (var rider in riders.OrderBy(r => r.FirstName))
        {
            var deliveredCount = await _orderRepo.Query()
                .CountAsync(o => o.RiderId == rider.Id && o.Status == OrderStatus.Delivered);
            result.Add(new RiderDto
            {
                Id = rider.Id,
                FullName = $"{rider.FirstName} {rider.LastName}".Trim(),
                Email = rider.Email ?? string.Empty,
                PhoneNumber = rider.PhoneNumber,
                DeliveredOrderCount = deliveredCount
            });
        }
        return result;
    }

    public async Task<IEnumerable<OrderDto>> GetOrdersByRiderAsync(Guid riderId)
    {
        var orders = await _orderRepo.Query()
            .Include(o => o.User)
            .Include(o => o.Items).ThenInclude(i => i.Product).ThenInclude(p => p.Images)
            .Include(o => o.Payment)
            .Include(o => o.Address)
            .Include(o => o.StatusHistory)
            .Where(o => o.RiderId == riderId)
            .OrderByDescending(o => o.CreatedAt)
            .ToListAsync();
        return orders.Select(o => MapToDto(o));
    }

    public async Task<IEnumerable<OrderDto>> GetAllOrdersAsync(int page, int pageSize)    {
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

    public async Task<OrderListResult> SearchOrdersAsync(
        int page, int pageSize, string? search, string? status, DateTime? dateFrom, DateTime? dateTo)
    {
        var query = _orderRepo.Query()
            .Include(o => o.User)
            .Include(o => o.Payment)
            .AsQueryable();

        // Search: order number, customer name, email
        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(o =>
                o.OrderNumber.ToLower().Contains(term) ||
                (o.User != null && (
                    o.User.FirstName.ToLower().Contains(term) ||
                    o.User.LastName.ToLower().Contains(term) ||
                    o.User.Email!.ToLower().Contains(term))));
        }

        // Status filter
        if (!string.IsNullOrWhiteSpace(status) &&
            Enum.TryParse<OrderStatus>(status, true, out var parsedStatus))
        {
            query = query.Where(o => o.Status == parsedStatus);
        }

        // Date range
        if (dateFrom.HasValue)
            query = query.Where(o => o.CreatedAt >= dateFrom.Value.Date);
        if (dateTo.HasValue)
            query = query.Where(o => o.CreatedAt < dateTo.Value.Date.AddDays(1));

        var totalCount = await query.CountAsync();

        var orders = await query
            .OrderByDescending(o => o.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Include(o => o.Items).ThenInclude(i => i.Product).ThenInclude(p => p.Images)
            .Include(o => o.Address)
            .Include(o => o.StatusHistory)
            .ToListAsync();

        var items = orders.Select(o => MapToDto(o)).ToList();

        return new OrderListResult
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    private OrderDto MapToDto(Order order, IEnumerable<Review>? reviews = null)
    {
        return new OrderDto
        {
            Id = order.Id,
            OrderNumber = order.OrderNumber,
            UserId = order.UserId,
            CustomerName = order.User is not null ? $"{order.User.FirstName} {order.User.LastName}".Trim() : string.Empty,
            CustomerEmail = order.User?.Email ?? string.Empty,
            CustomerPhone = order.User?.PhoneNumber,
            SubTotal = order.SubTotal,
            DiscountAmount = order.DiscountAmount,
            DeliveryFee = order.DeliveryFee,
            PlatformFee = order.PlatformFee,
            OtherCharges = order.OtherCharges,
            TotalAmount = order.TotalAmount,
            Status = order.Status.ToString(),
            Notes = order.Notes,
            VoucherCode = order.Voucher?.Code,
            CreatedAt = order.CreatedAt,
            DeliveryDate = order.DeliveryDate,
            DeliveryTimeSlot = order.DeliveryTimeSlot,
            RiderId = order.RiderId,
            RiderName = order.RiderName,
            RiderContact = order.RiderContact,
            ActualDeliveryDate = order.ActualDeliveryDate,
            Items = order.Items.Select(i =>
            {
                var primaryImage = i.Product?.Images?.FirstOrDefault(img => img.IsPrimary)
                    ?? i.Product?.Images?.FirstOrDefault();
                return new OrderItemDto
                {
                    ProductId = i.ProductId,
                    ProductName = i.ProductName,
                    ProductImageUrl = BuildFullImageUrl(primaryImage?.ImageUrl),
                    ProductImageDateModified = primaryImage?.DateModified,
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
                    PhotoUrl = AppUrlBuilder.BuildUploadUrl(_appBaseUrl, "reviews", p.PhotoUrl) ?? p.PhotoUrl,
                    SortOrder = p.SortOrder
                }).ToList()
            }).ToList()
        };
    }

    private string? BuildFullImageUrl(string? imageUrl)
    {
        return AppUrlBuilder.BuildUploadUrl(_appBaseUrl, "products", imageUrl);
    }
}
