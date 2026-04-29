using GroceryApp.Application.DTOs.Notifications;

namespace GroceryApp.Application.Interfaces;

public interface INotificationService
{
    Task<IEnumerable<NotificationDto>> GetUserNotificationsAsync(Guid userId);
    Task CreateNotificationAsync(Guid userId, string title, string message, string? type = null, string? referenceId = null);
    Task MarkAsReadAsync(Guid userId, Guid notificationId);
}
