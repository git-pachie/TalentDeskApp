using GroceryApp.Application.DTOs;
using GroceryApp.Application.DTOs.Addresses;
using GroceryApp.Application.DTOs.Orders;
using GroceryApp.Application.DTOs.PaymentMethods;
using GroceryApp.Application.DTOs.Vouchers;

namespace GroceryApp.Application.Interfaces;

public interface IUserService
{
    Task<PagedResult<UserDto>> GetAllUsersAsync(int page, int pageSize, string? search = null);
    Task<UserDto?> GetByIdAsync(Guid id);
    Task<bool> ToggleActiveAsync(Guid id);
    Task<IEnumerable<string>> GetAvailableRolesAsync();
    Task<UserDto> CreateUserAsync(CreateUserRequest request);
    Task<UserDto?> UpdateUserRolesAsync(Guid userId, UpdateUserRolesRequest request);

    // Profile modules
    Task<IEnumerable<AddressDto>> GetUserAddressesAsync(Guid userId);
    Task<AddressDto> AdminCreateAddressAsync(Guid userId, CreateAddressRequest request);
    Task<AddressDto?> AdminUpdateAddressAsync(Guid userId, Guid addressId, UpdateAddressRequest request);
    Task<bool> AdminDeleteAddressAsync(Guid userId, Guid addressId);

    Task<IEnumerable<OrderDto>> GetUserOrdersAsync(Guid userId);

    Task<IEnumerable<PaymentMethodDto>> GetUserPaymentMethodsAsync(Guid userId);
    Task<PaymentMethodDto> AdminCreatePaymentMethodAsync(Guid userId, CreatePaymentMethodRequest request);
    Task<PaymentMethodDto?> AdminUpdatePaymentMethodAsync(Guid userId, Guid id, UpdatePaymentMethodRequest request);
    Task<bool> AdminDeletePaymentMethodAsync(Guid userId, Guid id);

    Task<IEnumerable<UserVoucherDto>> GetUserVouchersAsync(Guid userId);
    Task<UserVoucherDto> AssignVoucherAsync(Guid userId, Guid voucherId);
    Task<bool> RevokeVoucherAsync(Guid userId, Guid userVoucherId);
    Task<IEnumerable<UserDeviceDto>> GetUserDevicesAsync(Guid userId);

    // Verification
    Task<bool> SetEmailVerifiedAsync(Guid userId, bool verified);
    Task<bool> SetPhoneVerifiedAsync(Guid userId, bool verified);
    Task<bool> SendEmailVerificationAsync(Guid userId);
    Task<bool> SendPhoneVerificationAsync(Guid userId);
}

public class UserDto
{
    public Guid Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? ProfileImageUrl { get; set; }
    public bool IsActive { get; set; }
    public bool IsEmailVerified { get; set; }
    public bool IsPhoneVerified { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<string> Roles { get; set; } = [];
    public int OrderCount { get; set; }
}

public class CreateUserRequest
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public List<string> Roles { get; set; } = [];
}

public class UpdateUserRolesRequest
{
    public List<string> Roles { get; set; } = [];
}

public class UserDeviceDto
{
    public Guid Id { get; set; }
    public Guid? UserId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string DeviceGuid { get; set; } = string.Empty;
    public string? OSVersion { get; set; }
    public string? HardwareVersion { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime LastLoginAt { get; set; }
}
