using GroceryApp.Admin.Filters;
using GroceryApp.Admin.Models;
using GroceryApp.Admin.Services;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.Admin.Controllers;

[AdminAuth]
public class UsersController : Controller
{
    private readonly ApiClient _apiClient;

    public UsersController(ApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    public async Task<IActionResult> Index(int page = 1, string? search = null)
    {
        var queryString = $"/api/users?page={page}&pageSize=20";
        if (!string.IsNullOrWhiteSpace(search))
            queryString += $"&search={Uri.EscapeDataString(search)}";

        var result = await _apiClient.GetAsync<PagedResultModel<UserModel>>(queryString);
        ViewBag.Search = search;
        ViewBag.CurrentPage = page;
        return View(result);
    }

    public async Task<IActionResult> Detail(Guid id)
    {
        var user = await _apiClient.GetAsync<UserModel>($"/api/users/{id}");
        if (user is null) return NotFound();
        return View(user);
    }

    [HttpPost]
    public async Task<IActionResult> ToggleActive(Guid id)
    {
        await _apiClient.PostAsync<object, object>($"/api/users/{id}/toggle-active", new { });
        return RedirectToAction(nameof(Index));
    }
}
