using GroceryApp.Admin.Filters;
using GroceryApp.Admin.Models;
using GroceryApp.Admin.Services;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.Admin.Controllers;

[AdminAuth]
public class RidersController : Controller
{
    private readonly ApiClient _apiClient;

    public RidersController(ApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    public async Task<IActionResult> Index()
    {
        var riders = await _apiClient.GetAsync<List<RiderModel>>("/api/orders/riders")
                     ?? new List<RiderModel>();
        return View(riders);
    }

    public async Task<IActionResult> Orders(Guid id)
    {
        var riders = await _apiClient.GetAsync<List<RiderModel>>("/api/orders/riders")
                     ?? new List<RiderModel>();
        var rider = riders.FirstOrDefault(r => r.Id == id);
        if (rider is null) return NotFound();

        var orders = await _apiClient.GetAsync<List<OrderModel>>($"/api/orders/riders/{id}")
                     ?? new List<OrderModel>();

        ViewBag.Rider = rider;
        return View(orders);
    }
}
