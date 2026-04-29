using GroceryApp.Admin.Filters;
using GroceryApp.Admin.Models;
using GroceryApp.Admin.Services;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.Admin.Controllers;

[AdminAuth]
public class DashboardController : Controller
{
    private readonly ApiClient _apiClient;

    public DashboardController(ApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    public async Task<IActionResult> Index()
    {
        ViewBag.UserName = HttpContext.Session.GetString("UserName");

        DashboardStatsModel? stats = null;
        try
        {
            stats = await _apiClient.GetAsync<DashboardStatsModel>("/api/dashboard/stats");
        }
        catch
        {
            // Fallback to empty stats if API call fails
        }

        return View(stats ?? new DashboardStatsModel());
    }
}
