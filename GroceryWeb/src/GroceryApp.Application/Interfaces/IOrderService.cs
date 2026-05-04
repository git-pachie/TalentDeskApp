using GroceryApp.Application.DTOs.Orders;

namespace GroceryApp.Application.Interfaces;

public interface IOrderService
{
    Task<OrderDto> CreateOrderAsync(Guid userId, CreateOrderRequest request);
    Task<IEnumerable<OrderDto>> GetUserOrdersAsync(Guid userId);
    Task<OrderDto?> GetOrderByIdAsync(Guid userId, Guid orderId);
    Task<OrderDto?> GetOrderByIdAdminAsync(Guid orderId);
    Task<OrderDto?> UpdateOrderStatusAsync(Guid orderId, string status);
    Task<OrderDto?> AssignRiderAsync(Guid orderId, Guid riderId);
    Task<IEnumerable<OrderDto>> GetAllOrdersAsync(int page, int pageSize);
    Task<OrderListResult> SearchOrdersAsync(int page, int pageSize, string? search, string? status, DateTime? dateFrom, DateTime? dateTo);
    Task<IEnumerable<RiderDto>> GetRidersAsync();
    Task<IEnumerable<OrderDto>> GetOrdersByRiderAsync(Guid riderId);
}
