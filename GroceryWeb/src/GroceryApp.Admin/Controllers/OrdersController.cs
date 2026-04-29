using GroceryApp.Admin.Filters;
using GroceryApp.Admin.Models;
using GroceryApp.Admin.Services;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.Admin.Controllers;

[AdminAuth]
public class OrdersController : Controller
{
    private readonly ApiClient _apiClient;

    public OrdersController(ApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    public async Task<IActionResult> Index()
    {
        var orders = await _apiClient.GetAsync<List<OrderModel>>("/api/orders/all");
        return View(orders ?? []);
    }

    public async Task<IActionResult> Detail(Guid id)
    {
        // The admin endpoint returns all orders; we need to find the specific one
        // For now, use the all-orders endpoint and filter client-side
        var orders = await _apiClient.GetAsync<List<OrderModel>>("/api/orders/all");
        var order = orders?.FirstOrDefault(o => o.Id == id);
        if (order is null) return NotFound();
        return View(order);
    }

    [HttpPost]
    public async Task<IActionResult> UpdateStatus(Guid id, string status)
    {
        await _apiClient.PutAsync<object, object>($"/api/orders/{id}/status", new { status });
        return RedirectToAction(nameof(Index));
    }
}
