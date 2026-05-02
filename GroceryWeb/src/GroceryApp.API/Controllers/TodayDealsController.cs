using GroceryApp.Application.DTOs.TodayDeals;
using GroceryApp.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace GroceryApp.API.Controllers;

[ApiController]
[Route("api/today-deals")]
public class TodayDealsController : ControllerBase
{
    private readonly ITodayDealService _todayDealService;

    public TodayDealsController(ITodayDealService todayDealService)
    {
        _todayDealService = todayDealService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] bool includeInactive = false)
    {
        var deals = await _todayDealService.GetAllAsync(includeInactive, User.IsInRole("StoreOwner") ? GetCurrentUserId() : null);
        return Ok(deals);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var deal = await _todayDealService.GetByIdAsync(id, User.IsInRole("StoreOwner") ? GetCurrentUserId() : null);
        return deal is null ? NotFound() : Ok(deal);
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Staff,StoreOwner")]
    public async Task<IActionResult> Create([FromBody] CreateTodayDealRequest request)
    {
        try
        {
            var deal = await _todayDealService.CreateAsync(request, User.IsInRole("StoreOwner") ? GetCurrentUserId() : null);
            return CreatedAtAction(nameof(GetById), new { id = deal.Id }, deal);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(ex.Message);
        }
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = "Admin,Staff,StoreOwner")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateTodayDealRequest request)
    {
        try
        {
            var deal = await _todayDealService.UpdateAsync(id, request, User.IsInRole("StoreOwner") ? GetCurrentUserId() : null);
            return deal is null ? NotFound() : Ok(deal);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(ex.Message);
        }
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "Admin,Staff,StoreOwner")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var deleted = await _todayDealService.DeleteAsync(id, User.IsInRole("StoreOwner") ? GetCurrentUserId() : null);
        return deleted ? NoContent() : NotFound();
    }

    private Guid? GetCurrentUserId()
    {
        var claim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(claim, out var userId) ? userId : null;
    }
}
