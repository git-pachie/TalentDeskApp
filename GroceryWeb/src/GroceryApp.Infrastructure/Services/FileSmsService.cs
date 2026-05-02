using GroceryApp.Application.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace GroceryApp.Infrastructure.Services;

public class FileSmsService : ISmsService
{
    private readonly IConfiguration _config;
    private readonly ILogger<FileSmsService> _logger;

    public FileSmsService(IConfiguration config, ILogger<FileSmsService> logger)
    {
        _config = config;
        _logger = logger;
    }

    public async Task SendPhoneVerificationCodeAsync(string phoneNumber, string code)
    {
        var configuredPath = _config["SmsLog:Path"] ?? Path.Combine("Logs", "sms-log.txt");
        var path = Path.IsPathRooted(configuredPath)
            ? configuredPath
            : Path.Combine(Directory.GetCurrentDirectory(), configuredPath);

        var directory = Path.GetDirectoryName(path);
        if (!string.IsNullOrWhiteSpace(directory))
        {
            Directory.CreateDirectory(directory);
        }

        var line = $"{DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC [PHONE_VERIFICATION] Phone={phoneNumber} Code={code}{Environment.NewLine}";
        await File.AppendAllTextAsync(path, line);
        _logger.LogInformation("Wrote phone verification code to SMS log for {PhoneNumber}.", phoneNumber);
    }
}
