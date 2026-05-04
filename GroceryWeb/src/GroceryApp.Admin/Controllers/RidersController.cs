using GroceryApp.Admin.Filters;
using GroceryApp.Admin.Models;
using GroceryApp.Admin.Services;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.Admin.Controllers;

[AdminAuth]
public class RidersController : Controller
{
    private readonly ApiClient _apiClient;
    private readonly IConfiguration _configuration;

    public RidersController(ApiClient apiClient, IConfiguration configuration)
    {
        _apiClient = apiClient;
        _configuration = configuration;
    }

    public async Task<IActionResult> Index()
    {
        var riders = await _apiClient.GetAsync<List<RiderModel>>("/api/orders/riders")
                     ?? new List<RiderModel>();
        ViewBag.ApiBaseUrl = _configuration["ApiBaseUrl"] ?? string.Empty;
        return View(riders);
    }

    public async Task<IActionResult> Orders(Guid id)
    {
        var riders = await _apiClient.GetAsync<List<RiderModel>>("/api/orders/riders")
                     ?? new List<RiderModel>();
        var rider = riders.FirstOrDefault(r => r.Id == id);
        if (rider is null) return NotFound();

        var orders = await _apiClient.GetAsync<List<OrderModel>>($"/api/orders/riders/{id}")
                     ?? new List<OrderModel>();

        ViewBag.ApiBaseUrl = _configuration["ApiBaseUrl"] ?? string.Empty;
        ViewBag.Rider = rider;
        return View(orders);
    }

    [HttpPost]
    public async Task<IActionResult> UploadPhoto(Guid id, IFormFile file)
    {
        if (file is null || file.Length == 0)
        {
            TempData["Error"] = "Please choose an image to upload.";
            return RedirectToAction(nameof(Orders), new { id });
        }

        var content = new MultipartFormDataContent();
        var fileContent = new StreamContent(file.OpenReadStream());
        fileContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(file.ContentType);
        content.Add(fileContent, "file", file.FileName);

        try
        {
            await _apiClient.PostMultipartAsync<object>($"/api/riders/{id}/image", content);
            TempData["Success"] = "Rider photo updated.";
        }
        catch (Exception ex)
        {
            TempData["Error"] = ex.Message;
        }

        return RedirectToAction(nameof(Orders), new { id });
    }
}
