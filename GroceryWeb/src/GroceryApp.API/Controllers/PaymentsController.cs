using System.Security.Claims;
using GroceryApp.Application.DTOs.Payments;
using GroceryApp.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.API.Controllers;

[ApiController]
[Route("api/payments")]
public class PaymentsController : ControllerBase
{
    private readonly IPaymentService _paymentService;

    public PaymentsController(IPaymentService paymentService)
    {
        _paymentService = paymentService;
    }

    [HttpPost("checkout")]
    [Authorize]
    public async Task<IActionResult> Checkout([FromBody] CheckoutRequest request)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        try
        {
            var result = await _paymentService.ProcessCheckoutAsync(userId, request);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("webhook/stripe")]
    public async Task<IActionResult> StripeWebhook()
    {
        var payload = await new StreamReader(HttpContext.Request.Body).ReadToEndAsync();
        var signature = Request.Headers["Stripe-Signature"].FirstOrDefault();

        try
        {
            await _paymentService.HandleWebhookAsync("Card", payload, signature);
            return Ok();
        }
        catch (InvalidOperationException)
        {
            return BadRequest();
        }
    }

    [HttpPost("webhook/gcash")]
    public async Task<IActionResult> GCashWebhook()
    {
        var payload = await new StreamReader(HttpContext.Request.Body).ReadToEndAsync();
        var signature = Request.Headers["X-Webhook-Signature"].FirstOrDefault();

        try
        {
            await _paymentService.HandleWebhookAsync("GCash", payload, signature);
            return Ok();
        }
        catch (InvalidOperationException)
        {
            return BadRequest();
        }
    }

    [HttpPost("webhook/paymaya")]
    public async Task<IActionResult> PayMayaWebhook()
    {
        var payload = await new StreamReader(HttpContext.Request.Body).ReadToEndAsync();
        var signature = Request.Headers["X-Webhook-Signature"].FirstOrDefault();

        try
        {
            await _paymentService.HandleWebhookAsync("PayMaya", payload, signature);
            return Ok();
        }
        catch (InvalidOperationException)
        {
            return BadRequest();
        }
    }
}
