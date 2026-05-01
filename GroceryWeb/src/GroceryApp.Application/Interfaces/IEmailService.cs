namespace GroceryApp.Application.Interfaces;

public interface IEmailService
{
    Task SendEmailVerificationCodeAsync(string toEmail, string toName, string code);
    Task SendEmailVerifiedConfirmationAsync(string toEmail, string toName);
}
