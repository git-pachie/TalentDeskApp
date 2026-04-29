using GroceryApp.Domain.Entities;

namespace GroceryApp.Application.DTOs.Payments;

public class CheckoutRequest
{
    public Guid OrderId { get; set; }
    public PaymentMethod Method { get; set; }
    public string? StripeToken { get; set; } // for Card / Apple Pay
    public string? ReturnUrl { get; set; } // for GCash / PayMaya redirect
}

public class PaymentResultDto
{
    public bool Success { get; set; }
    public Guid PaymentId { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? RedirectUrl { get; set; }
    public string? FailureReason { get; set; }
}
