using GroceryApp.Application.DTOs;
using GroceryApp.Application.DTOs.Products;

namespace GroceryApp.Application.Interfaces;

public interface IProductService
{
    Task<ProductDto?> GetByIdAsync(Guid id, Guid? ownerUserId = null);
    Task<PagedResult<ProductDto>> GetAllAsync(ProductQueryParams queryParams);
    Task<PagedResult<ProductDto>> SearchAsync(string query, int page, int pageSize);
    Task<ProductDto> CreateAsync(CreateProductRequest request, Guid? ownerUserId = null);
    Task<ProductDto?> UpdateAsync(Guid id, UpdateProductRequest request, Guid? ownerUserId = null);
    Task<bool> DeleteAsync(Guid id, Guid? ownerUserId = null);
}
