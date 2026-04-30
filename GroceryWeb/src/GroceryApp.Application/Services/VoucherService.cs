using GroceryApp.Application.DTOs.Vouchers;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;

namespace GroceryApp.Application.Services;

public class VoucherService : IVoucherService
{
    private readonly IRepository<Voucher> _voucherRepo;
    private readonly IUnitOfWork _unitOfWork;

    public VoucherService(IRepository<Voucher> voucherRepo, IUnitOfWork unitOfWork)
    {
        _voucherRepo = voucherRepo;
        _unitOfWork = unitOfWork;
    }

    public async Task<VoucherValidationResult> ApplyVoucherAsync(Guid userId, ApplyVoucherRequest request)
    {
        var voucher = await _voucherRepo.FirstOrDefaultAsync(v => v.Code == request.Code);

        if (voucher is null)
            return new VoucherValidationResult { IsValid = false, ErrorMessage = "Voucher not found." };

        if (!voucher.IsActive)
            return new VoucherValidationResult { IsValid = false, ErrorMessage = "Voucher is inactive." };

        if (DateTime.UtcNow < voucher.StartDate)
            return new VoucherValidationResult { IsValid = false, ErrorMessage = "Voucher is not yet active." };

        if (DateTime.UtcNow > voucher.ExpiryDate)
            return new VoucherValidationResult { IsValid = false, ErrorMessage = "Voucher has expired." };

        if (voucher.UsedCount >= voucher.UsageLimit)
            return new VoucherValidationResult { IsValid = false, ErrorMessage = "Voucher usage limit reached." };

        if (request.CartTotal < voucher.MinimumSpend)
            return new VoucherValidationResult { IsValid = false, ErrorMessage = $"Minimum spend of {voucher.MinimumSpend:C} required." };

        var discount = voucher.Type == VoucherType.Percentage
            ? Math.Min(request.CartTotal * voucher.Value / 100, voucher.MaxDiscount ?? decimal.MaxValue)
            : voucher.Value;

        return new VoucherValidationResult
        {
            IsValid = true,
            DiscountAmount = discount,
            Voucher = MapToDto(voucher)
        };
    }

    public async Task<IEnumerable<VoucherDto>> GetAllAsync()
    {
        var vouchers = await _voucherRepo.GetAllAsync();
        return vouchers.Select(MapToDto);
    }

    public async Task<VoucherDto?> GetByIdAsync(Guid id)
    {
        var voucher = await _voucherRepo.GetByIdAsync(id);
        return voucher is null ? null : MapToDto(voucher);
    }

    public async Task<IEnumerable<VoucherDto>> GetActiveAsync()
    {
        var now = DateTime.UtcNow;
        var vouchers = await _voucherRepo.FindAsync(
            v => v.IsActive && v.StartDate <= now && v.ExpiryDate > now && v.UsedCount < v.UsageLimit);
        return vouchers.Select(MapToDto);
    }

    public async Task<VoucherDto> CreateAsync(CreateVoucherRequest request)
    {
        var voucher = new Voucher
        {
            Code = request.Code.ToUpper(),
            Description = request.Description,
            Type = request.Type,
            Value = request.Value,
            MaxDiscount = request.MaxDiscount,
            MinimumSpend = request.MinimumSpend,
            UsageLimit = request.UsageLimit,
            StartDate = request.StartDate,
            ExpiryDate = request.ExpiryDate
        };

        await _voucherRepo.AddAsync(voucher);
        await _unitOfWork.SaveChangesAsync();

        return MapToDto(voucher);
    }

    public async Task<VoucherDto?> UpdateAsync(Guid id, UpdateVoucherRequest request)
    {
        var voucher = await _voucherRepo.GetByIdAsync(id);
        if (voucher is null) return null;

        if (request.Description is not null) voucher.Description = request.Description;
        if (request.Value.HasValue) voucher.Value = request.Value.Value;
        if (request.MaxDiscount.HasValue) voucher.MaxDiscount = request.MaxDiscount.Value;
        if (request.MinimumSpend.HasValue) voucher.MinimumSpend = request.MinimumSpend.Value;
        if (request.UsageLimit.HasValue) voucher.UsageLimit = request.UsageLimit.Value;
        if (request.IsActive.HasValue) voucher.IsActive = request.IsActive.Value;
        if (request.ExpiryDate.HasValue) voucher.ExpiryDate = request.ExpiryDate.Value;

        _voucherRepo.Update(voucher);
        await _unitOfWork.SaveChangesAsync();

        return MapToDto(voucher);
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var voucher = await _voucherRepo.GetByIdAsync(id);
        if (voucher is null) return false;

        _voucherRepo.Remove(voucher);
        await _unitOfWork.SaveChangesAsync();
        return true;
    }

    private static VoucherDto MapToDto(Voucher voucher)
    {
        return new VoucherDto
        {
            Id = voucher.Id,
            Code = voucher.Code,
            Description = voucher.Description,
            Type = voucher.Type.ToString(),
            Value = voucher.Value,
            MaxDiscount = voucher.MaxDiscount,
            MinimumSpend = voucher.MinimumSpend,
            UsageLimit = voucher.UsageLimit,
            UsedCount = voucher.UsedCount,
            IsActive = voucher.IsActive,
            StartDate = voucher.StartDate,
            ExpiryDate = voucher.ExpiryDate
        };
    }
}
