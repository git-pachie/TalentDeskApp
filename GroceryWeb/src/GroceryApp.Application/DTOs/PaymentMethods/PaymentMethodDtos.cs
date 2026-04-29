namespace GroceryApp.Application.DTOs.PaymentMethods;

public class PaymentMethodDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Detail { get; set; }
    public string PaymentType { get; set; } = string.Empty;
    public string? Icon { get; set; }
    public bool IsDefault { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreatePaymentMethodRequest
{
    public string Name { get; set; } = string.Empty;
    public string? Detail { get; set; }
    public string PaymentType { get; set; } = "CreditCard";
    public string? Icon { get; set; }
    public bool IsDefault { get; set; }
}

public class UpdatePaymentMethodRequest
{
    public string? Name { get; set; }
    public string? Detail { get; set; }
    public string? PaymentType { get; set; }
    public string? Icon { get; set; }
    public bool? IsDefault { get; set; }
}
