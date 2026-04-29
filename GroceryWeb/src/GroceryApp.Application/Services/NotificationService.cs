using GroceryApp.Application.DTOs.Notifications;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace GroceryApp.Application.Services;

public class NotificationService : INotificationService
{
    private readonly IRepository<Notification> _notificationRepo;
    private readonly IUnitOfWork _unitOfWork;

    public NotificationService(IRepository<Notification> notificationRepo, IUnitOfWork unitOfWork)
    {
        _notificationRepo = notificationRepo;
        _unitOfWork = unitOfWork;
    }

    public async Task<IEnumerable<NotificationDto>> GetUserNotificationsAsync(Guid userId)
    {
        var notifications = await _notificationRepo.Query()
            .Where(n => n.UserId == userId)
            .OrderByDescending(n => n.CreatedAt)
            .Take(50)
            .ToListAsync();

        return notifications.Select(MapToDto);
    }

    public async Task CreateNotificationAsync(Guid userId, string title, string message, string? type = null, string? referenceId = null)
    {
        var notification = new Notification
        {
            UserId = userId,
            Title = title,
            Message = message,
            Type = type,
            ReferenceId = referenceId
        };

        await _notificationRepo.AddAsync(notification);
        await _unitOfWork.SaveChangesAsync();
    }

    public async Task MarkAsReadAsync(Guid userId, Guid notificationId)
    {
        var notification = await _notificationRepo.FirstOrDefaultAsync(
            n => n.Id == notificationId && n.UserId == userId);

        if (notification is null) return;

        notification.IsRead = true;
        _notificationRepo.Update(notification);
        await _unitOfWork.SaveChangesAsync();
    }

    private static NotificationDto MapToDto(Notification notification)
    {
        return new NotificationDto
        {
            Id = notification.Id,
            Title = notification.Title,
            Message = notification.Message,
            Type = notification.Type,
            ReferenceId = notification.ReferenceId,
            IsRead = notification.IsRead,
            CreatedAt = notification.CreatedAt
        };
    }
}
