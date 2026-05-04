using System.Security.Claims;
using GroceryApp.Application.DTOs.Orders;
using GroceryApp.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.API.Controllers;

[ApiController]
[Route("api/orders")]
[Authorize]
public class OrdersController : ControllerBase
{
    private readonly IOrderService _orderService;

    public OrdersController(IOrderService orderService)
    {
        _orderService = orderService;
    }

    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpPost]
    public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest request)
    {
        try
        {
            var order = await _orderService.CreateOrderAsync(UserId, request);
            return CreatedAtAction(nameof(GetById), new { id = order.Id }, order);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet]
    public async Task<IActionResult> GetOrders()
    {
        var orders = await _orderService.GetUserOrdersAsync(UserId);
        return Ok(orders);
    }

    [HttpGet("all")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAllOrders([FromQuery] int page = 1, [FromQuery] int pageSize = 50)
    {
        var orders = await _orderService.GetAllOrdersAsync(page, pageSize);
        return Ok(orders);
    }

    [HttpGet("search")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> SearchOrders(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 60,
        [FromQuery] string? search = null,
        [FromQuery] string? status = null,
        [FromQuery] DateTime? dateFrom = null,
        [FromQuery] DateTime? dateTo = null)
    {
        var result = await _orderService.SearchOrdersAsync(page, pageSize, search, status, dateFrom, dateTo);
        return Ok(result);
    }

    [HttpGet("admin/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetOrderAdmin(Guid id)
    {
        var order = await _orderService.GetOrderByIdAdminAsync(id);
        return order is null ? NotFound() : Ok(order);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var order = await _orderService.GetOrderByIdAsync(UserId, id);
        return order is null ? NotFound() : Ok(order);
    }

    [HttpPut("{id:guid}/status")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] UpdateOrderStatusRequest request)
    {
        var order = await _orderService.UpdateOrderStatusAsync(id, request.Status);
        return order is null ? NotFound() : Ok(order);
    }

    [HttpPut("{id:guid}/assign-rider")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> AssignRider(Guid id, [FromBody] AssignRiderRequest request)
    {
        var order = await _orderService.AssignRiderAsync(id, request.RiderId);
        return order is null ? NotFound() : Ok(order);
    }

    [HttpGet("riders")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetRiders()
    {
        var riders = await _orderService.GetRidersAsync();
        return Ok(riders);
    }

    [HttpGet("riders/{riderId:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetRiderOrders(Guid riderId)
    {
        var orders = await _orderService.GetOrdersByRiderAsync(riderId);
        return Ok(orders);
    }
}

public class UpdateOrderStatusRequest
{
    public string Status { get; set; } = string.Empty;
}

public class AssignRiderRequest
{
    public Guid RiderId { get; set; }
}
