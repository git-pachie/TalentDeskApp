using System.Security.Claims;
using GroceryApp.Application.DTOs.PaymentMethods;
using GroceryApp.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.API.Controllers;

[ApiController]
[Route("api/payment-methods")]
[Authorize]
public class PaymentMethodsController : ControllerBase
{
    private readonly IPaymentMethodService _paymentMethodService;

    public PaymentMethodsController(IPaymentMethodService paymentMethodService)
    {
        _paymentMethodService = paymentMethodService;
    }

    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var methods = await _paymentMethodService.GetUserPaymentMethodsAsync(UserId);
        return Ok(methods);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var method = await _paymentMethodService.GetByIdAsync(UserId, id);
        return method is null ? NotFound() : Ok(method);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreatePaymentMethodRequest request)
    {
        var method = await _paymentMethodService.CreateAsync(UserId, request);
        return CreatedAtAction(nameof(GetById), new { id = method.Id }, method);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdatePaymentMethodRequest request)
    {
        var method = await _paymentMethodService.UpdateAsync(UserId, id, request);
        return method is null ? NotFound() : Ok(method);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var result = await _paymentMethodService.DeleteAsync(UserId, id);
        return result ? NoContent() : NotFound();
    }
}
