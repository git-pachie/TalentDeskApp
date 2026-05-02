using GroceryApp.Application.DTOs;
using GroceryApp.Application.DTOs.Products;
using GroceryApp.Application.Interfaces;
using GroceryApp.Application.Utilities;
using GroceryApp.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace GroceryApp.Application.Services;

public class ProductService : IProductService
{
    private readonly IRepository<Product> _productRepo;
    private readonly IRepository<ProductImage> _imageRepo;
    private readonly IRepository<ProductCategory> _productCategoryRepo;
    private readonly IUnitOfWork _unitOfWork;
    private readonly string _appBaseUrl;

    public ProductService(
        IRepository<Product> productRepo,
        IRepository<ProductImage> imageRepo,
        IRepository<ProductCategory> productCategoryRepo,
        IUnitOfWork unitOfWork,
        IConfiguration configuration)
    {
        _productRepo = productRepo;
        _imageRepo = imageRepo;
        _productCategoryRepo = productCategoryRepo;
        _unitOfWork = unitOfWork;
        _appBaseUrl = (configuration["App:BaseUrl"] ?? "").TrimEnd('/');
    }

    public async Task<ProductDto?> GetByIdAsync(Guid id)
    {
        var product = await _productRepo.Query()
            .Include(p => p.Category)
            .Include(p => p.ProductCategories).ThenInclude(pc => pc.Category)
            .Include(p => p.Images)
            .Include(p => p.Reviews)
            .FirstOrDefaultAsync(p => p.Id == id);

        return product is null ? null : MapToDto(product);
    }

    public async Task<PagedResult<ProductDto>> GetAllAsync(ProductQueryParams queryParams)
    {
        var query = _productRepo.Query()
            .Include(p => p.Category)
            .Include(p => p.ProductCategories).ThenInclude(pc => pc.Category)
            .Include(p => p.Images)
            .Include(p => p.Reviews)
            .AsQueryable();

        if (!queryParams.IncludeInactive)
            query = query.Where(p => p.IsActive);

        if (!string.IsNullOrWhiteSpace(queryParams.Search))
        {
            var searchTerm = queryParams.Search.Trim();
            query = query.Where(p => EF.Functions.Like(p.Name, $"%{searchTerm}%")
                || (p.Description != null && EF.Functions.Like(p.Description, $"%{searchTerm}%")));
        }

        if (queryParams.CategoryId.HasValue)
            query = query.Where(p => p.CategoryId == queryParams.CategoryId.Value
                || p.ProductCategories.Any(pc => pc.CategoryId == queryParams.CategoryId.Value));

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
            .Include(p => p.ProductCategories).ThenInclude(pc => pc.Category)
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
                SortOrder = i.SortOrder,
                DateCreated = DateTime.UtcNow,
                DateModified = DateTime.UtcNow
            }).ToList()
        };

        // Add additional categories via junction table
        if (request.CategoryIds.Count > 0)
        {
            product.ProductCategories = request.CategoryIds
                .Distinct()
                .Select(cid => new ProductCategory { CategoryId = cid })
                .ToList();
        }

        await _productRepo.AddAsync(product);
        await _unitOfWork.SaveChangesAsync();

        return (await GetByIdAsync(product.Id))!;
    }

    public async Task<ProductDto?> UpdateAsync(Guid id, UpdateProductRequest request)
    {
        var product = await _productRepo.Query()
            .Include(p => p.Images)
            .Include(p => p.ProductCategories)
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

        // Remove old categories and images first, then save
        var needsIntermediateSave = false;

        if (request.CategoryIds is not null && product.ProductCategories.Count > 0)
        {
            _productCategoryRepo.RemoveRange(product.ProductCategories);
            needsIntermediateSave = true;
        }

        if (request.Images is not null && product.Images.Count > 0)
        {
            _imageRepo.RemoveRange(product.Images);
            needsIntermediateSave = true;
        }

        _productRepo.Update(product);

        if (needsIntermediateSave)
        {
            await _unitOfWork.SaveChangesAsync();
        }

        // Now add new categories
        if (request.CategoryIds is not null)
        {
            foreach (var cid in request.CategoryIds.Distinct())
            {
                await _productCategoryRepo.AddAsync(new ProductCategory { ProductId = product.Id, CategoryId = cid });
            }
        }

        // Now add new images
        if (request.Images is not null)
        {
            foreach (var (img, idx) in request.Images.Select((img, idx) => (img, idx)))
            {
                await _imageRepo.AddAsync(new ProductImage
                {
                    ProductId = product.Id,
                    ImageUrl = img.ImageUrl,
                    IsPrimary = img.IsPrimary,
                    SortOrder = img.SortOrder,
                    DateCreated = DateTime.UtcNow,
                    DateModified = DateTime.UtcNow
                });
            }
        }

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

    private ProductDto MapToDto(Product product)
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
                FullUrl = BuildFullImageUrl(i.ImageUrl),
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

    /// Build the full image URL.
    /// - If the stored value is already a full URL (http/https), return as-is.
    /// - If it's a path starting with /, treat as relative to the API base.
    /// - Otherwise it's a filename — prepend the configured product image base URL.
    private string BuildFullImageUrl(string imageUrl)
    {
        return AppUrlBuilder.BuildUploadUrl(_appBaseUrl, "products", imageUrl) ?? imageUrl;
    }
}
