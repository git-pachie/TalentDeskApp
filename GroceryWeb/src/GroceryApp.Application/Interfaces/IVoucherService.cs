using GroceryApp.Application.DTOs.Vouchers;

namespace GroceryApp.Application.Interfaces;

public interface IVoucherService
{
    Task<VoucherValidationResult> ApplyVoucherAsync(Guid userId, ApplyVoucherRequest request);
    Task<IEnumerable<VoucherDto>> GetAllAsync();
    Task<VoucherDto?> GetByIdAsync(Guid id);
    Task<IEnumerable<VoucherDto>> GetActiveAsync();
    Task<IEnumerable<VoucherDto>> GetUserVouchersAsync(Guid userId);
    Task<VoucherDto> CreateAsync(CreateVoucherRequest request);
    Task<VoucherDto?> UpdateAsync(Guid id, UpdateVoucherRequest request);
    Task<bool> DeleteAsync(Guid id);
}
