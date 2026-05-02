namespace GroceryApp.Application.Interfaces;

public interface ISmsService
{
    Task SendPhoneVerificationCodeAsync(string phoneNumber, string code);
}
