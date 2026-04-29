using GroceryApp.Admin.Filters;
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
        // Dashboard data would be fetched from API
        return View();
    }
}
