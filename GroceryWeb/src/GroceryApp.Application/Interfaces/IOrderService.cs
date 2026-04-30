using GroceryApp.Application.DTOs.Orders;

namespace GroceryApp.Application.Interfaces;

public interface IOrderService
{
    Task<OrderDto> CreateOrderAsync(Guid userId, CreateOrderRequest request);
    Task<IEnumerable<OrderDto>> GetUserOrdersAsync(Guid userId);
    Task<OrderDto?> GetOrderByIdAsync(Guid userId, Guid orderId);
    Task<OrderDto?> GetOrderByIdAdminAsync(Guid orderId);
    Task<OrderDto?> UpdateOrderStatusAsync(Guid orderId, string status);
    Task<IEnumerable<OrderDto>> GetAllOrdersAsync(int page, int pageSize);
}
