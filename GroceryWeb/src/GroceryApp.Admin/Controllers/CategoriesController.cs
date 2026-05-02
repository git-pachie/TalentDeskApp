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

    public IActionResult Create() => View(new CreateCategoryModel());

    [HttpPost]
    public async Task<IActionResult> Create(CreateCategoryModel model)
    {
        if (!ModelState.IsValid) return View(model);
        await _apiClient.PostAsync<CreateCategoryModel, CategoryModel>("/api/categories", model);
        TempData["Success"] = "Category created.";
        return RedirectToAction(nameof(Index));
    }

    public async Task<IActionResult> Edit(Guid id)
    {
        var category = await _apiClient.GetAsync<CategoryModel>($"/api/categories/{id}");
        if (category is null) return NotFound();
        return View(category);
    }

    [HttpPost]
    public async Task<IActionResult> Edit(Guid id, UpdateCategoryModel model)
    {
        if (!ModelState.IsValid)
        {
            var category = await _apiClient.GetAsync<CategoryModel>($"/api/categories/{id}");
            if (category is null) return NotFound();
            return View(category);
        }
        await _apiClient.PutAsync<UpdateCategoryModel, CategoryModel>($"/api/categories/{id}", model);
        TempData["Success"] = "Category updated.";
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _apiClient.DeleteAsync($"/api/categories/{id}");
        return RedirectToAction(nameof(Index));
    }

    // ── Emoji quick-save (called by JS emoji picker) ───────────────────────────
    [HttpPost]
    public async Task<IActionResult> SetEmoji(Guid id, [FromBody] SetEmojiRequest request)
    {
        var result = await _apiClient.PutAsync<UpdateCategoryModel, CategoryModel>(
            $"/api/categories/{id}",
            new UpdateCategoryModel { Emoji = request.Emoji });
        return result is null ? NotFound() : Ok(new { emoji = result.Emoji });
    }
}

public class SetEmojiRequest
{
    public string Emoji { get; set; } = string.Empty;
}
