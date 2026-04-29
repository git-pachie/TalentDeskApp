using GroceryApp.Application.DTOs.Orders;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace GroceryApp.Application.Services;

public class OrderService : IOrderService
{
    private readonly IRepository<Order> _orderRepo;
    private readonly IRepository<CartItem> _cartRepo;
    private readonly IRepository<Voucher> _voucherRepo;
    private readonly IRepository<OrderStatusHistory> _statusHistoryRepo;
    private readonly INotificationService _notificationService;
    private readonly IUnitOfWork _unitOfWork;

    public OrderService(
        IRepository<Order> orderRepo,
        IRepository<CartItem> cartRepo,
        IRepository<Voucher> voucherRepo,
        IRepository<OrderStatusHistory> statusHistoryRepo,
        INotificationService notificationService,
        IUnitOfWork unitOfWork)
    {
        _orderRepo = orderRepo;
        _cartRepo = cartRepo;
        _voucherRepo = voucherRepo;
        _statusHistoryRepo = statusHistoryRepo;
        _notificationService = notificationService;
        _unitOfWork = unitOfWork;
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

        var order = new Order
        {
            UserId = userId,
            OrderNumber = $"ORD-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString()[..6].ToUpper()}",
            SubTotal = subTotal,
            DiscountAmount = discountAmount,
            DeliveryFee = deliveryFee,
            TotalAmount = subTotal - discountAmount + deliveryFee,
            AddressId = request.AddressId,
            VoucherId = voucherId,
            Notes = request.Notes,
            Items = cartItems.Select(c => new OrderItem
            {
                ProductId = c.ProductId,
                ProductName = c.Product.Name,
                UnitPrice = c.Product.DiscountPrice ?? c.Product.Price,
                Quantity = c.Quantity,
                TotalPrice = (c.Product.DiscountPrice ?? c.Product.Price) * c.Quantity
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
            .Include(o => o.Items)
            .Include(o => o.Payment)
            .Include(o => o.Address)
            .Include(o => o.StatusHistory)
            .Where(o => o.UserId == userId)
            .OrderByDescending(o => o.CreatedAt)
            .ToListAsync();

        return orders.Select(MapToDto);
    }

    public async Task<OrderDto?> GetOrderByIdAsync(Guid userId, Guid orderId)
    {
        var order = await _orderRepo.Query()
            .Include(o => o.Items)
            .Include(o => o.Payment)
            .Include(o => o.Address)
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == orderId && o.UserId == userId);

        return order is null ? null : MapToDto(order);
    }

    public async Task<OrderDto?> UpdateOrderStatusAsync(Guid orderId, string status)
    {
        var order = await _orderRepo.Query()
            .Include(o => o.Items)
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

        return MapToDto(order);
    }

    public async Task<IEnumerable<OrderDto>> GetAllOrdersAsync(int page, int pageSize)
    {
        var orders = await _orderRepo.Query()
            .Include(o => o.Items)
            .Include(o => o.Payment)
            .Include(o => o.Address)
            .Include(o => o.StatusHistory)
            .OrderByDescending(o => o.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return orders.Select(MapToDto);
    }

    private static OrderDto MapToDto(Order order)
    {
        return new OrderDto
        {
            Id = order.Id,
            OrderNumber = order.OrderNumber,
            SubTotal = order.SubTotal,
            DiscountAmount = order.DiscountAmount,
            DeliveryFee = order.DeliveryFee,
            TotalAmount = order.TotalAmount,
            Status = order.Status.ToString(),
            Notes = order.Notes,
            CreatedAt = order.CreatedAt,
            Items = order.Items.Select(i => new OrderItemDto
            {
                ProductId = i.ProductId,
                ProductName = i.ProductName,
                UnitPrice = i.UnitPrice,
                Quantity = i.Quantity,
                TotalPrice = i.TotalPrice
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
                ZipCode = order.Address.ZipCode
            },
            StatusHistory = order.StatusHistory
                .OrderBy(h => h.CreatedAt)
                .Select(h => new OrderStatusHistoryDto
                {
                    Status = h.Status,
                    Notes = h.Notes,
                    CreatedBy = h.CreatedBy,
                    CreatedAt = h.CreatedAt
                }).ToList()
        };
    }
}
