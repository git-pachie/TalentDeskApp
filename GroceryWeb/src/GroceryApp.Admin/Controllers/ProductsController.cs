using GroceryApp.Admin.Filters;
using GroceryApp.Admin.Models;
using GroceryApp.Admin.Services;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.Admin.Controllers;

[AdminAuth]
public class ProductsController : Controller
{
    private readonly ApiClient _apiClient;

    public ProductsController(ApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    public async Task<IActionResult> Index(int page = 1)
    {
        var result = await _apiClient.GetAsync<PagedResultModel<ProductModel>>($"/api/products?page={page}&pageSize=20");
        return View(result);
    }

    public IActionResult Create() => View();

    [HttpPost]
    public async Task<IActionResult> Create(CreateProductModel model)
    {
        if (!ModelState.IsValid) return View(model);

        await _apiClient.PostAsync<CreateProductModel, ProductModel>("/api/products", model);
        return RedirectToAction(nameof(Index));
    }

    public async Task<IActionResult> Edit(Guid id)
    {
        var product = await _apiClient.GetAsync<ProductModel>($"/api/products/{id}");
        if (product is null) return NotFound();
        return View(product);
    }

    [HttpPost]
    public async Task<IActionResult> Edit(Guid id, UpdateProductModel model)
    {
        if (!ModelState.IsValid) return View(model);

        await _apiClient.PutAsync<UpdateProductModel, ProductModel>($"/api/products/{id}", model);
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _apiClient.DeleteAsync($"/api/products/{id}");
        return RedirectToAction(nameof(Index));
    }
}
