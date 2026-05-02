using GroceryApp.Admin.Filters;
using GroceryApp.Admin.Models;
using GroceryApp.Admin.Services;
using Microsoft.AspNetCore.Mvc;
using System.Net;

namespace GroceryApp.Admin.Controllers;

[AdminAuth("Admin", "Staff", "StoreOwner")]
public class TodayDealsController : Controller
{
    private readonly ApiClient _apiClient;

    public TodayDealsController(ApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    public async Task<IActionResult> Index()
    {
        var deals = await _apiClient.GetAsync<List<TodayDealModel>>("/api/today-deals?includeInactive=true") ?? [];
        return View(deals);
    }

    public async Task<IActionResult> Create()
    {
        ViewBag.Products = await _apiClient.GetAsync<PagedResultModel<ProductModel>>("/api/products?page=1&pageSize=200&includeInactive=true");
        return View(new CreateTodayDealModel());
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateTodayDealModel model)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.Products = await _apiClient.GetAsync<PagedResultModel<ProductModel>>("/api/products?page=1&pageSize=200&includeInactive=true");
            return View(model);
        }

        try
        {
            await _apiClient.PostAsync<CreateTodayDealModel, TodayDealModel>("/api/today-deals", model);
            TempData["SuccessMessage"] = "Today's deal created.";
            return RedirectToAction(nameof(Index));
        }
        catch (HttpRequestException ex) when (ex.StatusCode == HttpStatusCode.Conflict)
        {
            ModelState.AddModelError(string.Empty, "This product is already added to Today's Deals.");
            ViewBag.Products = await _apiClient.GetAsync<PagedResultModel<ProductModel>>("/api/products?page=1&pageSize=200&includeInactive=true");
            return View(model);
        }
    }

    public async Task<IActionResult> Edit(Guid id)
    {
        var deal = await _apiClient.GetAsync<TodayDealModel>($"/api/today-deals/{id}");
        if (deal is null) return NotFound();
        ViewBag.Products = await _apiClient.GetAsync<PagedResultModel<ProductModel>>("/api/products?page=1&pageSize=200&includeInactive=true");
        return View(new UpdateTodayDealModel
        {
            ProductId = deal.ProductId,
            SortOrder = deal.SortOrder,
            IsActive = deal.IsActive
        });
    }

    [HttpPost]
    public async Task<IActionResult> Edit(Guid id, UpdateTodayDealModel model)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.Products = await _apiClient.GetAsync<PagedResultModel<ProductModel>>("/api/products?page=1&pageSize=200&includeInactive=true");
            return View(model);
        }

        try
        {
            await _apiClient.PutAsync<UpdateTodayDealModel, TodayDealModel>($"/api/today-deals/{id}", model);
            TempData["SuccessMessage"] = "Today's deal updated.";
            return RedirectToAction(nameof(Index));
        }
        catch (HttpRequestException ex) when (ex.StatusCode == HttpStatusCode.Conflict)
        {
            ModelState.AddModelError(string.Empty, "This product is already added to Today's Deals.");
            ViewBag.Products = await _apiClient.GetAsync<PagedResultModel<ProductModel>>("/api/products?page=1&pageSize=200&includeInactive=true");
            return View(model);
        }
    }

    [HttpPost]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _apiClient.DeleteAsync($"/api/today-deals/{id}");
        TempData["SuccessMessage"] = "Today's deal deleted.";
        return RedirectToAction(nameof(Index));
    }
}
