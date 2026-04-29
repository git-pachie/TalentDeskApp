using GroceryApp.Application.DTOs;
using GroceryApp.Application.DTOs.Products;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace GroceryApp.Application.Services;

public class ProductService : IProductService
{
    private readonly IRepository<Product> _productRepo;
    private readonly IRepository<ProductImage> _imageRepo;
    private readonly IUnitOfWork _unitOfWork;

    public ProductService(
        IRepository<Product> productRepo,
        IRepository<ProductImage> imageRepo,
        IUnitOfWork unitOfWork)
    {
        _productRepo = productRepo;
        _imageRepo = imageRepo;
        _unitOfWork = unitOfWork;
    }

    public async Task<ProductDto?> GetByIdAsync(Guid id)
    {
        var product = await _productRepo.Query()
            .Include(p => p.Category)
            .Include(p => p.Images)
            .Include(p => p.Reviews)
            .FirstOrDefaultAsync(p => p.Id == id);

        return product is null ? null : MapToDto(product);
    }

    public async Task<PagedResult<ProductDto>> GetAllAsync(ProductQueryParams queryParams)
    {
        var query = _productRepo.Query()
            .Include(p => p.Category)
            .Include(p => p.Images)
            .Include(p => p.Reviews)
            .Where(p => p.IsActive);

        if (queryParams.CategoryId.HasValue)
            query = query.Where(p => p.CategoryId == queryParams.CategoryId.Value);

        if (queryParams.MinPrice.HasValue)
            query = query.Where(p => p.Price >= queryParams.MinPrice.Value);

        if (queryParams.MaxPrice.HasValue)
            query = query.Where(p => p.Price <= queryParams.MaxPrice.Value);

        query = queryParams.SortBy?.ToLower() switch
        {
            "name" => queryParams.SortDescending ? query.OrderByDescending(p => p.Name) : query.OrderBy(p => p.Name),
            "price" => queryParams.SortDescending ? query.OrderByDescending(p => p.Price) : query.OrderBy(p => p.Price),
            "newest" => query.OrderByDescending(p => p.CreatedAt),
            _ => query.OrderByDescending(p => p.CreatedAt)
        };

        var totalCount = await query.CountAsync();
        var items = await query
            .Skip((queryParams.Page - 1) * queryParams.PageSize)
            .Take(queryParams.PageSize)
            .ToListAsync();

        return new PagedResult<ProductDto>
        {
            Items = items.Select(MapToDto),
            TotalCount = totalCount,
            Page = queryParams.Page,
            PageSize = queryParams.PageSize
        };
    }

    public async Task<PagedResult<ProductDto>> SearchAsync(string searchQuery, int page, int pageSize)
    {
        var query = _productRepo.Query()
            .Include(p => p.Category)
            .Include(p => p.Images)
            .Include(p => p.Reviews)
            .Where(p => p.IsActive &&
                (p.Name.Contains(searchQuery) || (p.Description != null && p.Description.Contains(searchQuery))));

        var totalCount = await query.CountAsync();
        var items = await query
            .OrderByDescending(p => p.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<ProductDto>
        {
            Items = items.Select(MapToDto),
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<ProductDto> CreateAsync(CreateProductRequest request)
    {
        var product = new Product
        {
            Name = request.Name,
            Description = request.Description,
            Price = request.Price,
            DiscountPrice = request.DiscountPrice,
            StockQuantity = request.StockQuantity,
            Unit = request.Unit,
            CategoryId = request.CategoryId,
            Images = request.Images.Select(i => new ProductImage
            {
                ImageUrl = i.ImageUrl,
                IsPrimary = i.IsPrimary,
                SortOrder = i.SortOrder
            }).ToList()
        };

        await _productRepo.AddAsync(product);
        await _unitOfWork.SaveChangesAsync();

        return (await GetByIdAsync(product.Id))!;
    }

    public async Task<ProductDto?> UpdateAsync(Guid id, UpdateProductRequest request)
    {
        var product = await _productRepo.Query()
            .Include(p => p.Images)
            .FirstOrDefaultAsync(p => p.Id == id);

        if (product is null) return null;

        if (request.Name is not null) product.Name = request.Name;
        if (request.Description is not null) product.Description = request.Description;
        if (request.Price.HasValue) product.Price = request.Price.Value;
        if (request.DiscountPrice.HasValue) product.DiscountPrice = request.DiscountPrice.Value;
        if (request.StockQuantity.HasValue) product.StockQuantity = request.StockQuantity.Value;
        if (request.Unit is not null) product.Unit = request.Unit;
        if (request.IsActive.HasValue) product.IsActive = request.IsActive.Value;
        if (request.CategoryId.HasValue) product.CategoryId = request.CategoryId.Value;
        product.UpdatedAt = DateTime.UtcNow;

        if (request.Images is not null)
        {
            _imageRepo.RemoveRange(product.Images);
            product.Images = request.Images.Select(i => new ProductImage
            {
                ProductId = product.Id,
                ImageUrl = i.ImageUrl,
                IsPrimary = i.IsPrimary,
                SortOrder = i.SortOrder
            }).ToList();
        }

        _productRepo.Update(product);
        await _unitOfWork.SaveChangesAsync();

        return (await GetByIdAsync(product.Id))!;
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var product = await _productRepo.GetByIdAsync(id);
        if (product is null) return false;

        product.IsActive = false;
        product.UpdatedAt = DateTime.UtcNow;
        _productRepo.Update(product);
        await _unitOfWork.SaveChangesAsync();
        return true;
    }

    private static ProductDto MapToDto(Product product)
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
            Images = product.Images.OrderBy(i => i.SortOrder).Select(i => new ProductImageDto
            {
                Id = i.Id,
                ImageUrl = i.ImageUrl,
                IsPrimary = i.IsPrimary,
                SortOrder = i.SortOrder
            }),
            AverageRating = product.Reviews.Count != 0 ? product.Reviews.Average(r => r.Rating) : 0,
            ReviewCount = product.Reviews.Count
        };
    }
}
