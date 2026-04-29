using GroceryApp.Application.DTOs.Favorites;

namespace GroceryApp.Application.Interfaces;

public interface IFavoriteService
{
    Task<IEnumerable<FavoriteDto>> GetUserFavoritesAsync(Guid userId);
    Task<FavoriteDto> AddFavoriteAsync(Guid userId, Guid productId);
    Task<bool> RemoveFavoriteAsync(Guid userId, Guid productId);
}
