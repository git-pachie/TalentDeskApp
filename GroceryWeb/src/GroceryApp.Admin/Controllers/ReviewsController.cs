using GroceryApp.Admin.Filters;
using GroceryApp.Admin.Models;
using GroceryApp.Admin.Services;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.Admin.Controllers;

[AdminAuth]
public class ReviewsController : Controller
{
    private readonly ApiClient _apiClient;

    public ReviewsController(ApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    public async Task<IActionResult> Index(int page = 1)
    {
        var reviews = await _apiClient.GetAsync<List<ReviewModel>>($"/api/reviews?page={page}&pageSize=50");
        ViewBag.CurrentPage = page;
        return View(reviews ?? []);
    }

    [HttpPost]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _apiClient.DeleteAsync($"/api/reviews/{id}");
        return RedirectToAction(nameof(Index));
    }
}
