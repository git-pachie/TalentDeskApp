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

    [HttpPost]
    public async Task<IActionResult> UpdateStatus(Guid id, string status)
    {
        await _apiClient.PutAsync<object, object>($"/api/orders/{id}/status", new { status });
        return RedirectToAction(nameof(Index));
    }
}
