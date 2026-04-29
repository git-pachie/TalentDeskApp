using System.Security.Claims;
using GroceryApp.Application.DTOs.Vouchers;
using GroceryApp.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.API.Controllers;

[ApiController]
[Route("api/vouchers")]
public class VouchersController : ControllerBase
{
    private readonly IVoucherService _voucherService;

    public VouchersController(IVoucherService voucherService)
    {
        _voucherService = voucherService;
    }

    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAll()
    {
        var vouchers = await _voucherService.GetAllAsync();
        return Ok(vouchers);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] CreateVoucherRequest request)
    {
        var voucher = await _voucherService.CreateAsync(request);
        return Ok(voucher);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateVoucherRequest request)
    {
        var voucher = await _voucherService.UpdateAsync(id, request);
        return voucher is null ? NotFound() : Ok(voucher);
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var result = await _voucherService.DeleteAsync(id);
        return result ? NoContent() : NotFound();
    }

    [HttpPost("apply")]
    [Authorize]
    public async Task<IActionResult> Apply([FromBody] ApplyVoucherRequest request)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var result = await _voucherService.ApplyVoucherAsync(userId, request);
        return result.IsValid ? Ok(result) : BadRequest(result);
    }
}
