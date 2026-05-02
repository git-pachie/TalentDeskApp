using GroceryApp.Application.DTOs.Products;
using GroceryApp.Application.DTOs.TodayDeals;
using GroceryApp.Application.Interfaces;
using GroceryApp.Application.Utilities;
using GroceryApp.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace GroceryApp.Application.Services;

public class TodayDealService : ITodayDealService
{
    private readonly IRepository<TodayDeal> _todayDealRepo;
    private readonly IUnitOfWork _unitOfWork;
    private readonly string _appBaseUrl;

    public TodayDealService(IRepository<TodayDeal> todayDealRepo, IUnitOfWork unitOfWork, IConfiguration configuration)
    {
        _todayDealRepo = todayDealRepo;
        _unitOfWork = unitOfWork;
        _appBaseUrl = (configuration["App:BaseUrl"] ?? "").TrimEnd('/');
    }

    public async Task<IEnumerable<TodayDealDto>> GetAllAsync(bool includeInactive = false, Guid? ownerUserId = null)
    {
        var query = BuildScopedQuery(ownerUserId);
        if (!includeInactive)
            query = query.Where(d => d.IsActive);

        var deals = await query
            .OrderBy(d => d.SortOrder)
            .ThenBy(d => d.CreatedAt)
            .ToListAsync();

        return deals.Select(MapToDto);
    }

    public async Task<TodayDealDto?> GetByIdAsync(Guid id, Guid? ownerUserId = null)
    {
        var deal = await BuildScopedQuery(ownerUserId).FirstOrDefaultAsync(d => d.Id == id);
        return deal is null ? null : MapToDto(deal);
    }

    public async Task<TodayDealDto> CreateAsync(CreateTodayDealRequest request, Guid? ownerUserId = null)
    {
        var duplicateExists = await BuildScopedQuery(ownerUserId)
            .AnyAsync(d => d.ProductId == request.ProductId);
        if (duplicateExists)
            throw new InvalidOperationException("This product is already added to Today's Deals.");

        var deal = new TodayDeal
        {
            ProductId = request.ProductId,
            OwnerUserId = ownerUserId,
            SortOrder = request.SortOrder,
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        await _todayDealRepo.AddAsync(deal);
        await _unitOfWork.SaveChangesAsync();

        return (await GetByIdAsync(deal.Id, ownerUserId))!;
    }

    public async Task<TodayDealDto?> UpdateAsync(Guid id, UpdateTodayDealRequest request, Guid? ownerUserId = null)
    {
        var deal = await BuildScopedQuery(ownerUserId).FirstOrDefaultAsync(d => d.Id == id);
        if (deal is null) return null;

        if (request.ProductId.HasValue && request.ProductId.Value != deal.ProductId)
        {
            var duplicateExists = await BuildScopedQuery(ownerUserId)
                .AnyAsync(d => d.Id != id && d.ProductId == request.ProductId.Value);
            if (duplicateExists)
                throw new InvalidOperationException("This product is already added to Today's Deals.");

            deal.ProductId = request.ProductId.Value;
        }
        if (request.SortOrder.HasValue) deal.SortOrder = request.SortOrder.Value;
        if (request.IsActive.HasValue) deal.IsActive = request.IsActive.Value;
        deal.UpdatedAt = DateTime.UtcNow;

        _todayDealRepo.Update(deal);
        await _unitOfWork.SaveChangesAsync();
        return (await GetByIdAsync(deal.Id, ownerUserId))!;
    }

    public async Task<bool> DeleteAsync(Guid id, Guid? ownerUserId = null)
    {
        var deal = await BuildScopedQuery(ownerUserId).FirstOrDefaultAsync(d => d.Id == id);
        if (deal is null) return false;
        _todayDealRepo.Remove(deal);
        await _unitOfWork.SaveChangesAsync();
        return true;
    }

    private IQueryable<TodayDeal> BuildScopedQuery(Guid? ownerUserId)
    {
        var query = _todayDealRepo.Query()
            .Include(d => d.Product).ThenInclude(p => p.Category)
            .Include(d => d.Product).ThenInclude(p => p.ProductCategories).ThenInclude(pc => pc.Category)
            .Include(d => d.Product).ThenInclude(p => p.Images)
            .Include(d => d.Product).ThenInclude(p => p.Reviews)
            .AsQueryable();

        if (ownerUserId.HasValue)
            query = query.Where(d => d.OwnerUserId == ownerUserId.Value);

        return query;
    }

    private TodayDealDto MapToDto(TodayDeal deal) => new()
    {
        Id = deal.Id,
        ProductId = deal.ProductId,
        SortOrder = deal.SortOrder,
        IsActive = deal.IsActive,
        CreatedAt = deal.CreatedAt,
        UpdatedAt = deal.UpdatedAt,
        Product = MapProduct(deal.Product)
    };

    private ProductDto MapProduct(Product product)
    {
        return new ProductDto
        {
            Id = product.Id,
            Name = product.Name,
            Description = product.Description,
            Price = product.Price,
            DiscountPrice = product.DiscountPrice,
            StockQuantity = product.StockQuantity,
            Unit = product.Unit,
            IsActive = product.IsActive,
            CategoryId = product.CategoryId,
            CategoryName = product.Category?.Name ?? string.Empty,
            Categories = product.ProductCategories
                .Where(pc => pc.Category is not null)
                .Select(pc => new ProductCategoryDto { Id = pc.CategoryId, Name = pc.Category.Name })
                .ToList(),
            Images = product.Images.OrderBy(i => i.SortOrder).Select(i => new ProductImageDto
            {
                Id = i.Id,
                ImageUrl = i.ImageUrl,
                FullUrl = AppUrlBuilder.BuildUploadUrl(_appBaseUrl, "products", i.ImageUrl) ?? i.ImageUrl,
                IsPrimary = i.IsPrimary,
                SortOrder = i.SortOrder,
                DateCreated = i.DateCreated,
                DateModified = i.DateModified
            }),
            AverageRating = product.Reviews.Count != 0 ? product.Reviews.Average(r => r.Rating) : 0,
            ReviewCount = product.Reviews.Count,
            CreatedAt = product.CreatedAt
        };
    }
}
