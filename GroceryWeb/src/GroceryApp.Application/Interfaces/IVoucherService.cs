using GroceryApp.Application.DTOs.Vouchers;

namespace GroceryApp.Application.Interfaces;

public interface IVoucherService
{
    Task<VoucherValidationResult> ApplyVoucherAsync(Guid userId, ApplyVoucherRequest request);
    Task<IEnumerable<VoucherDto>> GetAllAsync();
    Task<VoucherDto> CreateAsync(CreateVoucherRequest request);
    Task<VoucherDto?> UpdateAsync(Guid id, UpdateVoucherRequest request);
    Task<bool> DeleteAsync(Guid id);
}
