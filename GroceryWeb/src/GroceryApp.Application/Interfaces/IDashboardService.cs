using GroceryApp.Application.DTOs.Dashboard;

namespace GroceryApp.Application.Interfaces;

public interface IDashboardService
{
    Task<DashboardStatsDto> GetStatsAsync();
}
