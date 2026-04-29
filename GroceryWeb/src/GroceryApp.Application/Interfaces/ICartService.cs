using GroceryApp.Application.DTOs.Cart;

namespace GroceryApp.Application.Interfaces;

public interface ICartService
{
    Task<IEnumerable<CartItemDto>> GetCartAsync(Guid userId);
    Task<CartItemDto> AddToCartAsync(Guid userId, AddToCartRequest request);
    Task<CartItemDto?> UpdateCartItemAsync(Guid userId, Guid cartItemId, UpdateCartItemRequest request);
    Task<bool> RemoveCartItemAsync(Guid userId, Guid cartItemId);
    Task ClearCartAsync(Guid userId);
}
