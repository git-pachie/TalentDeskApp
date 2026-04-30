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

    public async Task<IActionResult> Edit(Guid id)
    {
        var voucher = await _apiClient.GetAsync<VoucherModel>($"/api/vouchers/{id}");
        if (voucher is null) return NotFound();
        return View(voucher);
    }

    [HttpPost]
    public async Task<IActionResult> Edit(Guid id, UpdateVoucherModel model)
    {
        if (!ModelState.IsValid)
        {
            var voucher = await _apiClient.GetAsync<VoucherModel>($"/api/vouchers/{id}");
            if (voucher is null) return NotFound();
            return View(voucher);
        }

        await _apiClient.PutAsync<UpdateVoucherModel, VoucherModel>($"/api/vouchers/{id}", model);
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _apiClient.DeleteAsync($"/api/vouchers/{id}");
        return RedirectToAction(nameof(Index));
    }
}
