using GroceryApp.Admin.Filters;
using GroceryApp.Admin.Models;
using GroceryApp.Admin.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace GroceryApp.Admin.Controllers;

[AdminAuth]
public class ProductsController : Controller
{
    private readonly ApiClient _apiClient;
    private readonly string _productImageUrl;

    public ProductsController(ApiClient apiClient, IConfiguration configuration)
    {
        _apiClient = apiClient;
        _productImageUrl = (configuration["ImageUrls:ProductImage"] ?? "https://localhost:5001/uploads/products").TrimEnd('/');
    }

    public override void OnActionExecuting(ActionExecutingContext context)
    {
        ViewBag.ProductImageUrl = _productImageUrl;
        base.OnActionExecuting(context);
    }

    public async Task<IActionResult> Index(int page = 1, string? search = null, Guid? categoryId = null)
    {
        PagedResultModel<ProductModel>? result;

        if (!string.IsNullOrWhiteSpace(search))
        {
            // Use the dedicated search endpoint
            var searchQuery = $"/api/products/search?q={Uri.EscapeDataString(search)}&page={page}&pageSize=60";
            if (categoryId.HasValue && categoryId.Value != Guid.Empty)
                searchQuery += $"&categoryId={categoryId.Value}";
            result = await _apiClient.GetAsync<PagedResultModel<ProductModel>>(searchQuery);
        }
        else
        {
            var query = $"/api/products?page={page}&pageSize=60&includeInactive=true";
            if (categoryId.HasValue && categoryId.Value != Guid.Empty)
                query += $"&categoryId={categoryId.Value}";
            result = await _apiClient.GetAsync<PagedResultModel<ProductModel>>(query);
        }

        var categories = await _apiClient.GetAsync<List<CategoryModel>>("/api/categories");

        ViewBag.Categories = categories ?? [];
        ViewBag.CurrentSearch = search;
        ViewBag.CurrentCategoryId = categoryId;

        return View(result);
    }

    public async Task<IActionResult> Detail(Guid id)
    {
        var product = await _apiClient.GetAsync<ProductModel>($"/api/products/{id}");
        if (product is null) return NotFound();
        return View(product);
    }

    public async Task<IActionResult> Create()
    {
        var categories = await _apiClient.GetAsync<List<CategoryModel>>("/api/categories");
        ViewBag.Categories = categories ?? [];
        return View(new CreateProductModel());
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateProductModel model)
    {
        if (!ModelState.IsValid)
        {
            var categories = await _apiClient.GetAsync<List<CategoryModel>>("/api/categories");
            ViewBag.Categories = categories ?? [];
            return View(model);
        }

        await _apiClient.PostAsync<CreateProductModel, ProductModel>("/api/products", model);
        return RedirectToAction(nameof(Index));
    }

    public async Task<IActionResult> Edit(Guid id)
    {
        var product = await _apiClient.GetAsync<ProductModel>($"/api/products/{id}");
        if (product is null) return NotFound();

        var categories = await _apiClient.GetAsync<List<CategoryModel>>("/api/categories");
        ViewBag.Categories = categories ?? [];
        return View(product);
    }

    [HttpPost]
    public async Task<IActionResult> Edit(Guid id, UpdateProductModel model)
    {
        if (!ModelState.IsValid)
        {
            var product = await _apiClient.GetAsync<ProductModel>($"/api/products/{id}");
            if (product is null) return NotFound();

            var categories = await _apiClient.GetAsync<List<CategoryModel>>("/api/categories");
            ViewBag.Categories = categories ?? [];
            return View(product);
        }

        await _apiClient.PutAsync<UpdateProductModel, ProductModel>($"/api/products/{id}", model);
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _apiClient.DeleteAsync($"/api/products/{id}");
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> UploadImages(List<IFormFile> files)
    {
        if (files is null || files.Count == 0)
            return Json(new { urls = Array.Empty<string>() });

        using var content = new MultipartFormDataContent();
        foreach (var file in files)
        {
            var streamContent = new StreamContent(file.OpenReadStream());
            streamContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(file.ContentType);
            content.Add(streamContent, "files", file.FileName);
        }

        var result = await _apiClient.PostMultipartAsync<UploadResultModel>("/api/products/images/upload", content);
        return Json(result ?? new UploadResultModel());
    }
}
