using GroceryApp.Application.DTOs.UserSettings;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace GroceryApp.Application.Services;

public class UserSettingService : IUserSettingService
{
    private const string NotificationSettingsPrefix = "notifications.";

    private static readonly Dictionary<string, bool> NotificationDefaults = new()
    {
        ["marketingPromotions"] = false,
        ["productUpdates"] = false,
        ["newsAnnouncements"] = false,
        ["transactionsBilling"] = true,
        ["alertsCritical"] = true,
        ["usageActivity"] = false,
        ["accountSecurity"] = true,
        ["reminders"] = false,
        ["messagesSupport"] = false,
        ["personalizedRecommendations"] = false
    };

    private readonly IRepository<UserSetting> _settingRepo;
    private readonly IUnitOfWork _unitOfWork;

    public UserSettingService(IRepository<UserSetting> settingRepo, IUnitOfWork unitOfWork)
    {
        _settingRepo = settingRepo;
        _unitOfWork = unitOfWork;
    }

    public async Task<IEnumerable<UserSettingDto>> GetUserSettingsAsync(Guid userId)
    {
        var settings = await _settingRepo.Query()
            .Where(s => s.UserId == userId)
            .ToListAsync();

        return settings.Select(s => new UserSettingDto { Key = s.SettingKey, Value = s.SettingValue });
    }

    public async Task<UserSettingDto?> GetSettingAsync(Guid userId, string key)
    {
        var setting = await _settingRepo.FirstOrDefaultAsync(s => s.UserId == userId && s.SettingKey == key);
        return setting is null ? null : new UserSettingDto { Key = setting.SettingKey, Value = setting.SettingValue };
    }

    public async Task<UserSettingDto> UpsertSettingAsync(Guid userId, UpdateUserSettingRequest request)
    {
        var existing = await _settingRepo.FirstOrDefaultAsync(s => s.UserId == userId && s.SettingKey == request.Key);

        if (existing is not null)
        {
            existing.SettingValue = request.Value;
            _settingRepo.Update(existing);
        }
        else
        {
            var setting = new UserSetting
            {
                UserId = userId,
                SettingKey = request.Key,
                SettingValue = request.Value
            };
            await _settingRepo.AddAsync(setting);
        }

        await _unitOfWork.SaveChangesAsync();
        return new UserSettingDto { Key = request.Key, Value = request.Value };
    }

    public async Task<NotificationSettingsDto> GetNotificationSettingsAsync(Guid userId)
    {
        var settings = await _settingRepo.Query()
            .Where(s => s.UserId == userId && s.SettingKey.StartsWith(NotificationSettingsPrefix))
            .ToDictionaryAsync(
                s => s.SettingKey.Substring(NotificationSettingsPrefix.Length),
                s => bool.TryParse(s.SettingValue, out var value) && value);

        return MapNotificationSettings(settings);
    }

    public async Task<NotificationSettingsDto> UpdateNotificationSettingsAsync(Guid userId, NotificationSettingsDto request)
    {
        var requestedValues = ToDictionary(request);
        var existing = await _settingRepo.Query()
            .Where(s => s.UserId == userId && s.SettingKey.StartsWith(NotificationSettingsPrefix))
            .ToDictionaryAsync(s => s.SettingKey);

        foreach (var (key, value) in requestedValues)
        {
            var settingKey = NotificationSettingsPrefix + key;
            var settingValue = value.ToString();

            if (existing.TryGetValue(settingKey, out var setting))
            {
                setting.SettingValue = settingValue;
                _settingRepo.Update(setting);
            }
            else
            {
                await _settingRepo.AddAsync(new UserSetting
                {
                    UserId = userId,
                    SettingKey = settingKey,
                    SettingValue = settingValue
                });
            }
        }

        await _unitOfWork.SaveChangesAsync();
        return MapNotificationSettings(requestedValues);
    }

    public async Task<bool> DeleteSettingAsync(Guid userId, string key)
    {
        var setting = await _settingRepo.FirstOrDefaultAsync(s => s.UserId == userId && s.SettingKey == key);
        if (setting is null) return false;

        _settingRepo.Remove(setting);
        await _unitOfWork.SaveChangesAsync();
        return true;
    }

    private static NotificationSettingsDto MapNotificationSettings(IReadOnlyDictionary<string, bool> settings)
    {
        bool Value(string key) => settings.TryGetValue(key, out var value) ? value : NotificationDefaults[key];

        return new NotificationSettingsDto
        {
            MarketingPromotions = Value("marketingPromotions"),
            ProductUpdates = Value("productUpdates"),
            NewsAnnouncements = Value("newsAnnouncements"),
            TransactionsBilling = Value("transactionsBilling"),
            AlertsCritical = Value("alertsCritical"),
            UsageActivity = Value("usageActivity"),
            AccountSecurity = Value("accountSecurity"),
            Reminders = Value("reminders"),
            MessagesSupport = Value("messagesSupport"),
            PersonalizedRecommendations = Value("personalizedRecommendations")
        };
    }

    private static Dictionary<string, bool> ToDictionary(NotificationSettingsDto settings) => new()
    {
        ["marketingPromotions"] = settings.MarketingPromotions,
        ["productUpdates"] = settings.ProductUpdates,
        ["newsAnnouncements"] = settings.NewsAnnouncements,
        ["transactionsBilling"] = settings.TransactionsBilling,
        ["alertsCritical"] = settings.AlertsCritical,
        ["usageActivity"] = settings.UsageActivity,
        ["accountSecurity"] = settings.AccountSecurity,
        ["reminders"] = settings.Reminders,
        ["messagesSupport"] = settings.MessagesSupport,
        ["personalizedRecommendations"] = settings.PersonalizedRecommendations
    };
}
