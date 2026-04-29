using GroceryApp.Application.DTOs.Favorites;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace GroceryApp.Application.Services;

public class FavoriteService : IFavoriteService
{
    private readonly IRepository<Favorite> _favoriteRepo;
    private readonly IUnitOfWork _unitOfWork;

    public FavoriteService(IRepository<Favorite> favoriteRepo, IUnitOfWork unitOfWork)
    {
        _favoriteRepo = favoriteRepo;
        _unitOfWork = unitOfWork;
    }

    public async Task<IEnumerable<FavoriteDto>> GetUserFavoritesAsync(Guid userId)
    {
        var favorites = await _favoriteRepo.Query()
            .Include(f => f.Product)
                .ThenInclude(p => p.Images)
            .Where(f => f.UserId == userId)
            .OrderByDescending(f => f.CreatedAt)
            .ToListAsync();

        return favorites.Select(MapToDto);
    }

    public async Task<FavoriteDto> AddFavoriteAsync(Guid userId, Guid productId)
    {
        var existing = await _favoriteRepo.FirstOrDefaultAsync(
            f => f.UserId == userId && f.ProductId == productId);

        if (existing is not null)
            throw new InvalidOperationException("Product is already in favorites.");

        var favorite = new Favorite
        {
            UserId = userId,
            ProductId = productId
        };

        await _favoriteRepo.AddAsync(favorite);
        await _unitOfWork.SaveChangesAsync();

        var saved = await _favoriteRepo.Query()
            .Include(f => f.Product)
                .ThenInclude(p => p.Images)
            .FirstAsync(f => f.Id == favorite.Id);

        return MapToDto(saved);
    }

    public async Task<bool> RemoveFavoriteAsync(Guid userId, Guid productId)
    {
        var favorite = await _favoriteRepo.FirstOrDefaultAsync(
            f => f.UserId == userId && f.ProductId == productId);

        if (favorite is null) return false;

        _favoriteRepo.Remove(favorite);
        await _unitOfWork.SaveChangesAsync();
        return true;
    }

    private static FavoriteDto MapToDto(Favorite favorite)
    {
        var primaryImage = favorite.Product.Images.FirstOrDefault(i => i.IsPrimary)
            ?? favorite.Product.Images.FirstOrDefault();

        return new FavoriteDto
        {
            ProductId = favorite.ProductId,
            ProductName = favorite.Product.Name,
            Price = favorite.Product.Price,
            DiscountPrice = favorite.Product.DiscountPrice,
            ImageUrl = primaryImage?.ImageUrl,
            AddedAt = favorite.CreatedAt
        };
    }
}
