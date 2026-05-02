using GroceryApp.Application.DTOs.TodayDeals;

namespace GroceryApp.Application.Interfaces;

public interface ITodayDealService
{
    Task<IEnumerable<TodayDealDto>> GetAllAsync(bool includeInactive = false, Guid? ownerUserId = null);
    Task<TodayDealDto?> GetByIdAsync(Guid id, Guid? ownerUserId = null);
    Task<TodayDealDto> CreateAsync(CreateTodayDealRequest request, Guid? ownerUserId = null);
    Task<TodayDealDto?> UpdateAsync(Guid id, UpdateTodayDealRequest request, Guid? ownerUserId = null);
    Task<bool> DeleteAsync(Guid id, Guid? ownerUserId = null);
}
