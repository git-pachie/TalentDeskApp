using GroceryApp.Application.DTOs.Cart;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace GroceryApp.Application.Services;

public class CartService : ICartService
{
    private readonly IRepository<CartItem> _cartRepo;
    private readonly IRepository<Product> _productRepo;
    private readonly IUnitOfWork _unitOfWork;
    private readonly string _productImageBaseUrl;

    public CartService(
        IRepository<CartItem> cartRepo,
        IRepository<Product> productRepo,
        IUnitOfWork unitOfWork,
        IConfiguration configuration)
    {
        _cartRepo = cartRepo;
        _productRepo = productRepo;
        _unitOfWork = unitOfWork;
        _productImageBaseUrl = (configuration["ImageUrls:ProductImage"] ?? "").TrimEnd('/');
    }

    public async Task<IEnumerable<CartItemDto>> GetCartAsync(Guid userId)
    {
        var items = await _cartRepo.Query()
            .Include(c => c.Product)
                .ThenInclude(p => p.Images)
            .Where(c => c.UserId == userId)
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync();

        return items.Select(MapToDto);
    }

    public async Task<CartItemDto> AddToCartAsync(Guid userId, AddToCartRequest request)
    {
        var existing = await _cartRepo.FirstOrDefaultAsync(
            c => c.UserId == userId && c.ProductId == request.ProductId);

        if (existing is not null)
        {
            existing.Quantity += request.Quantity;
            existing.UpdatedAt = DateTime.UtcNow;
            _cartRepo.Update(existing);
        }
        else
        {
            existing = new CartItem
            {
                UserId = userId,
                ProductId = request.ProductId,
                Quantity = request.Quantity
            };
            await _cartRepo.AddAsync(existing);
        }

        await _unitOfWork.SaveChangesAsync();

        var item = await _cartRepo.Query()
            .Include(c => c.Product)
                .ThenInclude(p => p.Images)
            .FirstAsync(c => c.Id == existing.Id);

        return MapToDto(item);
    }

    public async Task<CartItemDto?> UpdateCartItemAsync(Guid userId, Guid cartItemId, UpdateCartItemRequest request)
    {
        var item = await _cartRepo.Query()
            .Include(c => c.Product)
                .ThenInclude(p => p.Images)
            .FirstOrDefaultAsync(c => c.Id == cartItemId && c.UserId == userId);

        if (item is null) return null;

        item.Quantity = request.Quantity;
        item.UpdatedAt = DateTime.UtcNow;
        _cartRepo.Update(item);
        await _unitOfWork.SaveChangesAsync();

        return MapToDto(item);
    }

    public async Task<bool> RemoveCartItemAsync(Guid userId, Guid cartItemId)
    {
        var item = await _cartRepo.FirstOrDefaultAsync(c => c.Id == cartItemId && c.UserId == userId);
        if (item is null) return false;

        _cartRepo.Remove(item);
        await _unitOfWork.SaveChangesAsync();
        return true;
    }

    public async Task ClearCartAsync(Guid userId)
    {
        var items = await _cartRepo.FindAsync(c => c.UserId == userId);
        _cartRepo.RemoveRange(items);
        await _unitOfWork.SaveChangesAsync();
    }

    private CartItemDto MapToDto(CartItem item)
    {
        var primaryImage = item.Product.Images.FirstOrDefault(i => i.IsPrimary)
            ?? item.Product.Images.FirstOrDefault();

        return new CartItemDto
        {
            Id = item.Id,
            ProductId = item.ProductId,
            ProductName = item.Product.Name,
            ProductImageUrl = primaryImage?.ImageUrl,
            ProductImageFullUrl = BuildFullImageUrl(primaryImage?.ImageUrl),
            UnitPrice = item.Product.DiscountPrice ?? item.Product.Price,
            Quantity = item.Quantity,
            TotalPrice = (item.Product.DiscountPrice ?? item.Product.Price) * item.Quantity
        };
    }

    private string? BuildFullImageUrl(string? imageUrl)
    {
        if (string.IsNullOrEmpty(imageUrl)) return null;
        if (imageUrl.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
            imageUrl.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            return imageUrl;
        if (!string.IsNullOrEmpty(_productImageBaseUrl))
        {
            var fileName = imageUrl.Contains('/') ? imageUrl.Split('/').Last() : imageUrl;
            return $"{_productImageBaseUrl}/{fileName}";
        }
        return imageUrl;
    }
}
