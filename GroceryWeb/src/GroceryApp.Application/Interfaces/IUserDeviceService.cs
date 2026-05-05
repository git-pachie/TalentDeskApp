namespace GroceryApp.Application.Interfaces;

public interface IUserDeviceService
{
    Task RegisterLoginAsync(
        Guid userId,
        string email,
        string? deviceGuid,
        string? osVersion,
        string? hardwareVersion,
        string? pushToken,
        string? platform);
}
