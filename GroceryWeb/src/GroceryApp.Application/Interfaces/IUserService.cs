using GroceryApp.Application.DTOs;
using GroceryApp.Application.DTOs.Auth;

namespace GroceryApp.Application.Interfaces;

public interface IUserService
{
    Task<PagedResult<UserDto>> GetAllUsersAsync(int page, int pageSize, string? search = null);
    Task<UserDto?> GetByIdAsync(Guid id);
    Task<bool> ToggleActiveAsync(Guid id);
}

public class UserDto
{
    public Guid Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<string> Roles { get; set; } = [];
    public int OrderCount { get; set; }
}
