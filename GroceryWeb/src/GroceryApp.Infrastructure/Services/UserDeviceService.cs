using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using GroceryApp.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace GroceryApp.Infrastructure.Services;

public class UserDeviceService : IUserDeviceService
{
    private readonly AppDbContext _context;

    public UserDeviceService(AppDbContext context)
    {
        _context = context;
    }

    public async Task RegisterLoginAsync(
        Guid userId,
        string email,
        string? deviceGuid,
        string? osVersion,
        string? hardwareVersion)
    {
        if (string.IsNullOrWhiteSpace(deviceGuid)) return;

        var normalizedDeviceGuid = deviceGuid.Trim();
        var normalizedEmail = email.Trim();
        var now = DateTime.UtcNow;

        var device = await _context.UserDevices
            .FirstOrDefaultAsync(d => d.DeviceGuid == normalizedDeviceGuid);

        if (device is null)
        {
            await _context.UserDevices.AddAsync(new UserDevice
            {
                UserId = userId,
                Email = normalizedEmail,
                DeviceGuid = normalizedDeviceGuid,
                OSVersion = string.IsNullOrWhiteSpace(osVersion) ? null : osVersion.Trim(),
                HardwareVersion = string.IsNullOrWhiteSpace(hardwareVersion) ? null : hardwareVersion.Trim(),
                CreatedAt = now,
                LastLoginAt = now
            });
        }
        else
        {
            device.UserId = userId;
            device.Email = normalizedEmail;
            device.OSVersion = string.IsNullOrWhiteSpace(osVersion) ? device.OSVersion : osVersion.Trim();
            device.HardwareVersion = string.IsNullOrWhiteSpace(hardwareVersion) ? device.HardwareVersion : hardwareVersion.Trim();
            device.LastLoginAt = now;
            device.UpdatedAt = now;
        }

        await _context.SaveChangesAsync();
    }
}
