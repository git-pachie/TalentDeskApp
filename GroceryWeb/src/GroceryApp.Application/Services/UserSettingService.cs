using GroceryApp.Application.DTOs.UserSettings;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace GroceryApp.Application.Services;

public class UserSettingService : IUserSettingService
{
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

    public async Task<bool> DeleteSettingAsync(Guid userId, string key)
    {
        var setting = await _settingRepo.FirstOrDefaultAsync(s => s.UserId == userId && s.SettingKey == key);
        if (setting is null) return false;

        _settingRepo.Remove(setting);
        await _unitOfWork.SaveChangesAsync();
        return true;
    }
}
