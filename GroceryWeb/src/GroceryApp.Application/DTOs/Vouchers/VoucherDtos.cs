using GroceryApp.Domain.Entities;

namespace GroceryApp.Application.DTOs.Vouchers;

public class VoucherDto
{
    public Guid Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Type { get; set; } = string.Empty;
    public decimal Value { get; set; }
    public decimal? MaxDiscount { get; set; }
    public decimal MinimumSpend { get; set; }
    public int UsageLimit { get; set; }
    public int UsedCount { get; set; }
    public bool IsActive { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime ExpiryDate { get; set; }
}

public class ApplyVoucherRequest
{
    public string Code { get; set; } = string.Empty;
    public decimal CartTotal { get; set; }
}

public class VoucherValidationResult
{
    public bool IsValid { get; set; }
    public string? ErrorMessage { get; set; }
    public decimal DiscountAmount { get; set; }
    public VoucherDto? Voucher { get; set; }
}

public class CreateVoucherRequest
{
    public string Code { get; set; } = string.Empty;
    public string? Description { get; set; }
    public VoucherType Type { get; set; }
    public decimal Value { get; set; }
    public decimal? MaxDiscount { get; set; }
    public decimal MinimumSpend { get; set; }
    public int UsageLimit { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime ExpiryDate { get; set; }
}

public class UpdateVoucherRequest
{
    public string? Description { get; set; }
    public decimal? Value { get; set; }
    public decimal? MaxDiscount { get; set; }
    public decimal? MinimumSpend { get; set; }
    public int? UsageLimit { get; set; }
    public bool? IsActive { get; set; }
    public DateTime? ExpiryDate { get; set; }
}

public class UserVoucherDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid VoucherId { get; set; }
    public string VoucherCode { get; set; } = string.Empty;
    public string? VoucherDescription { get; set; }
    public string VoucherType { get; set; } = string.Empty;
    public decimal VoucherValue { get; set; }
    public DateTime ExpiryDate { get; set; }
    public bool IsUsed { get; set; }
    public DateTime? UsedAt { get; set; }
    public DateTime AssignedAt { get; set; }
    public string AssignedBy { get; set; } = string.Empty;
}

public class AssignVoucherRequest
{
    public Guid VoucherId { get; set; }
}
