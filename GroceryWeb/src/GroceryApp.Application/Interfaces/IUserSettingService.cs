using GroceryApp.Application.DTOs.UserSettings;

namespace GroceryApp.Application.Interfaces;

public interface IUserSettingService
{
    Task<IEnumerable<UserSettingDto>> GetUserSettingsAsync(Guid userId);
    Task<UserSettingDto?> GetSettingAsync(Guid userId, string key);
    Task<UserSettingDto> UpsertSettingAsync(Guid userId, UpdateUserSettingRequest request);
    Task<NotificationSettingsDto> GetNotificationSettingsAsync(Guid userId);
    Task<NotificationSettingsDto> UpdateNotificationSettingsAsync(Guid userId, NotificationSettingsDto request);
    Task<bool> DeleteSettingAsync(Guid userId, string key);
}
