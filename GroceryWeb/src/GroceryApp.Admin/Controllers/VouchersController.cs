using GroceryApp.Admin.Filters;
using GroceryApp.Admin.Models;
using GroceryApp.Admin.Services;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.Admin.Controllers;

[AdminAuth]
public class VouchersController : Controller
{
    private readonly ApiClient _apiClient;

    public VouchersController(ApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    public async Task<IActionResult> Index()
    {
        var vouchers = await _apiClient.GetAsync<List<VoucherModel>>("/api/vouchers");
        return View(vouchers ?? []);
    }

    public IActionResult Create() => View();

    [HttpPost]
    public async Task<IActionResult> Create(CreateVoucherModel model)
    {
        if (!ModelState.IsValid) return View(model);

        await _apiClient.PostAsync<CreateVoucherModel, VoucherModel>("/api/vouchers", model);
        return RedirectToAction(nameof(Index));
    }
}
