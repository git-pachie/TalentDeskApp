using GroceryApp.Admin.Filters;
using GroceryApp.Admin.Models;
using GroceryApp.Admin.Services;
using System.Net;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.Admin.Controllers;

[AdminAuth]
public class SpecialOffersController : Controller
{
    private readonly ApiClient _apiClient;

    public SpecialOffersController(ApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    public async Task<IActionResult> Index()
    {
        try
        {
            var offers = await _apiClient.GetAsync<List<SpecialOfferModel>>("/api/special-offers?includeInactive=true");
            return View(offers ?? []);
        }
        catch (HttpRequestException ex) when (ex.StatusCode == HttpStatusCode.NotFound)
        {
            ViewBag.ErrorMessage = "Special Offers is not available on the current API deployment yet. Deploy the latest API build and apply the Special Offers migration.";
            return View(new List<SpecialOfferModel>());
        }
    }

    public IActionResult Create() => View(new CreateSpecialOfferModel());

    [HttpPost]
    public async Task<IActionResult> Create(CreateSpecialOfferModel model)
    {
        if (!ModelState.IsValid) return View(model);
        try
        {
            await _apiClient.PostAsync<CreateSpecialOfferModel, SpecialOfferModel>("/api/special-offers", model);
            TempData["SuccessMessage"] = "Special offer created.";
            return RedirectToAction(nameof(Index));
        }
        catch (HttpRequestException ex) when (ex.StatusCode == HttpStatusCode.NotFound)
        {
            TempData["ErrorMessage"] = "Special Offers is not available on the current API deployment yet. Deploy the latest API build and apply the Special Offers migration.";
            return RedirectToAction(nameof(Index));
        }
    }

    public async Task<IActionResult> Edit(Guid id)
    {
        try
        {
            var offer = await _apiClient.GetAsync<SpecialOfferModel>($"/api/special-offers/{id}");
            return offer is null ? NotFound() : View(new UpdateSpecialOfferModel
            {
                Title = offer.Title,
                Subtitle = offer.Subtitle,
                Emoji = offer.Emoji,
                BackgroundColorHex = offer.BackgroundColorHex,
                SortOrder = offer.SortOrder,
                IsActive = offer.IsActive
            });
        }
        catch (HttpRequestException ex) when (ex.StatusCode == HttpStatusCode.NotFound)
        {
            TempData["ErrorMessage"] = "Special Offers is not available on the current API deployment yet. Deploy the latest API build and apply the Special Offers migration.";
            return RedirectToAction(nameof(Index));
        }
    }

    [HttpPost]
    public async Task<IActionResult> Edit(Guid id, UpdateSpecialOfferModel model)
    {
        if (!ModelState.IsValid) return View(model);
        try
        {
            await _apiClient.PutAsync<UpdateSpecialOfferModel, SpecialOfferModel>($"/api/special-offers/{id}", model);
            TempData["SuccessMessage"] = "Special offer updated.";
            return RedirectToAction(nameof(Index));
        }
        catch (HttpRequestException ex) when (ex.StatusCode == HttpStatusCode.NotFound)
        {
            TempData["ErrorMessage"] = "Special Offers is not available on the current API deployment yet. Deploy the latest API build and apply the Special Offers migration.";
            return RedirectToAction(nameof(Index));
        }
    }

    [HttpPost]
    public async Task<IActionResult> Delete(Guid id)
    {
        try
        {
            await _apiClient.DeleteAsync($"/api/special-offers/{id}");
            TempData["SuccessMessage"] = "Special offer deleted.";
        }
        catch (HttpRequestException ex) when (ex.StatusCode == HttpStatusCode.NotFound)
        {
            TempData["ErrorMessage"] = "Special Offers is not available on the current API deployment yet. Deploy the latest API build and apply the Special Offers migration.";
        }
        return RedirectToAction(nameof(Index));
    }
}
