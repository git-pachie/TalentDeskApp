using GroceryApp.Application.DTOs.Addresses;

namespace GroceryApp.Application.Interfaces;

public interface IAddressService
{
    Task<IEnumerable<AddressDto>> GetUserAddressesAsync(Guid userId);
    Task<AddressDto?> GetByIdAsync(Guid userId, Guid addressId);
    Task<AddressDto> CreateAsync(Guid userId, CreateAddressRequest request);
    Task<AddressDto?> UpdateAsync(Guid userId, Guid addressId, UpdateAddressRequest request);
    Task<bool> DeleteAsync(Guid userId, Guid addressId);
}
