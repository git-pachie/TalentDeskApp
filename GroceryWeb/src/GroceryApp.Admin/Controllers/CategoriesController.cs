using GroceryApp.Admin.Filters;
using GroceryApp.Admin.Models;
using GroceryApp.Admin.Services;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.Admin.Controllers;

[AdminAuth]
public class CategoriesController : Controller
{
    private readonly ApiClient _apiClient;

    public CategoriesController(ApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    public async Task<IActionResult> Index()
    {
        var categories = await _apiClient.GetAsync<List<CategoryModel>>("/api/categories");
        return View(categories ?? []);
    }

    public IActionResult Create() => View();

    [HttpPost]
    public async Task<IActionResult> Create(CreateCategoryModel model)
    {
        if (!ModelState.IsValid) return View(model);

        await _apiClient.PostAsync<CreateCategoryModel, CategoryModel>("/api/categories", model);
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _apiClient.DeleteAsync($"/api/categories/{id}");
        return RedirectToAction(nameof(Index));
    }
}
