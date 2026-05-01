using System.Security.Cryptography;

namespace GroceryApp.Application.Security;

public static class VerificationCodeGenerator
{
    public static string CreateFourDigitCode()
    {
        return RandomNumberGenerator.GetInt32(1000, 10000).ToString();
    }
}
