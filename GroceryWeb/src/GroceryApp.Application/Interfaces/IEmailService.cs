namespace GroceryApp.Application.Interfaces;

public interface IEmailService
{
    Task SendEmailVerificationCodeAsync(string toEmail, string toName, string code);
    Task SendEmailVerifiedConfirmationAsync(string toEmail, string toName);

    // Order lifecycle emails
    Task SendOrderPlacedAsync(string toEmail, string toName, string orderNumber, decimal total, DateTime deliveryDate, string? timeSlot);
    Task SendOrderCancelledAsync(string toEmail, string toName, string orderNumber, decimal total);
    Task SendOrderOutForDeliveryAsync(string toEmail, string toName, string orderNumber, DateTime? deliveryDate, string? timeSlot);
    Task SendOrderDeliveredAsync(string toEmail, string toName, string orderNumber, decimal total);
}
