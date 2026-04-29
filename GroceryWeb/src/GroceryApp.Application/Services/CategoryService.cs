using GroceryApp.Application.DTOs.Categories;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace GroceryApp.Application.Services;

public class CategoryService : ICategoryService
{
    private readonly IRepository<Category> _categoryRepo;
    private readonly IUnitOfWork _unitOfWork;

    public CategoryService(IRepository<Category> categoryRepo, IUnitOfWork unitOfWork)
    {
        _categoryRepo = categoryRepo;
        _unitOfWork = unitOfWork;
    }

    public async Task<IEnumerable<CategoryDto>> GetAllAsync()
    {
        var categories = await _categoryRepo.Query()
            .Include(c => c.Products)
            .OrderBy(c => c.Name)
            .ToListAsync();

        return categories.Select(MapToDto);
    }

    public async Task<CategoryDto?> GetByIdAsync(Guid id)
    {
        var category = await _categoryRepo.Query()
            .Include(c => c.Products)
            .FirstOrDefaultAsync(c => c.Id == id);

        return category is null ? null : MapToDto(category);
    }

    public async Task<CategoryDto> CreateAsync(CreateCategoryRequest request)
    {
        var category = new Category
        {
            Name = request.Name,
            Description = request.Description,
            ImageUrl = request.ImageUrl
        };

        await _categoryRepo.AddAsync(category);
        await _unitOfWork.SaveChangesAsync();

        return MapToDto(category);
    }

    public async Task<CategoryDto?> UpdateAsync(Guid id, UpdateCategoryRequest request)
    {
        var category = await _categoryRepo.GetByIdAsync(id);
        if (category is null) return null;

        if (request.Name is not null) category.Name = request.Name;
        if (request.Description is not null) category.Description = request.Description;
        if (request.ImageUrl is not null) category.ImageUrl = request.ImageUrl;
        if (request.IsActive.HasValue) category.IsActive = request.IsActive.Value;

        _categoryRepo.Update(category);
        await _unitOfWork.SaveChangesAsync();

        return MapToDto(category);
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var category = await _categoryRepo.GetByIdAsync(id);
        if (category is null) return false;

        _categoryRepo.Remove(category);
        await _unitOfWork.SaveChangesAsync();
        return true;
    }

    private static CategoryDto MapToDto(Category category)
    {
        return new CategoryDto
        {
            Id = category.Id,
            Name = category.Name,
            Description = category.Description,
            ImageUrl = category.ImageUrl,
            IsActive = category.IsActive,
            ProductCount = category.Products?.Count(p => p.IsActive) ?? 0
        };
    }
}
