using GroceryApp.Application.DTOs.Dashboard;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace GroceryApp.Application.Services;

public class DashboardService : IDashboardService
{
    private readonly IRepository<Product> _productRepo;
    private readonly IRepository<Order> _orderRepo;
    private readonly IRepository<Category> _categoryRepo;
    private readonly IRepository<Voucher> _voucherRepo;
    private readonly UserManager<User> _userManager;

    public DashboardService(
        IRepository<Product> productRepo,
        IRepository<Order> orderRepo,
        IRepository<Category> categoryRepo,
        IRepository<Voucher> voucherRepo,
        UserManager<User> userManager)
    {
        _productRepo = productRepo;
        _orderRepo = orderRepo;
        _categoryRepo = categoryRepo;
        _voucherRepo = voucherRepo;
        _userManager = userManager;
    }

    public async Task<DashboardStatsDto> GetStatsAsync()
    {
        var today = DateTime.UtcNow.Date;

        var totalProducts = await _productRepo.CountAsync(p => p.IsActive);
        var totalOrders = await _orderRepo.CountAsync();
        var totalUsers = await _userManager.Users.CountAsync();
        var totalCategories = await _categoryRepo.CountAsync();
        var activeVouchers = await _voucherRepo.CountAsync(v => v.IsActive && v.ExpiryDate > DateTime.UtcNow);
        var pendingOrders = await _orderRepo.CountAsync(o => o.Status == OrderStatus.Pending || o.Status == OrderStatus.Processing);

        var totalRevenue = await _orderRepo.Query()
            .Where(o => o.Status == OrderStatus.Delivered)
            .SumAsync(o => o.TotalAmount);

        var todayOrders = await _orderRepo.CountAsync(o => o.CreatedAt >= today);

        var recentOrders = await _orderRepo.Query()
            .Include(o => o.User)
            .OrderByDescending(o => o.CreatedAt)
            .Take(10)
            .Select(o => new RecentOrderDto
            {
                Id = o.Id,
                OrderNumber = o.OrderNumber,
                CustomerName = o.User.FirstName + " " + o.User.LastName,
                TotalAmount = o.TotalAmount,
                Status = o.Status.ToString(),
                CreatedAt = o.CreatedAt
            })
            .ToListAsync();

        return new DashboardStatsDto
        {
            TotalProducts = totalProducts,
            TotalOrders = totalOrders,
            TotalUsers = totalUsers,
            TotalCategories = totalCategories,
            ActiveVouchers = activeVouchers,
            PendingOrders = pendingOrders,
            TotalRevenue = totalRevenue,
            TodayOrders = todayOrders,
            RecentOrders = recentOrders
        };
    }
}
