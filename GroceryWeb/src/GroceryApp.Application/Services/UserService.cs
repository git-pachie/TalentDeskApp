using GroceryApp.Application.DTOs;
using GroceryApp.Application.DTOs.Addresses;
using GroceryApp.Application.DTOs.Orders;
using GroceryApp.Application.DTOs.PaymentMethods;
using GroceryApp.Application.DTOs.Vouchers;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace GroceryApp.Application.Services;

public class UserService : IUserService
{
    private readonly UserManager<User> _userManager;
    private readonly IRepository<Address> _addressRepo;
    private readonly IRepository<Order> _orderRepo;
    private readonly IRepository<UserPaymentMethod> _paymentMethodRepo;
    private readonly IRepository<UserVoucher> _userVoucherRepo;
    private readonly IRepository<Voucher> _voucherRepo;
    private readonly IUnitOfWork _unitOfWork;

    public UserService(
        UserManager<User> userManager,
        IRepository<Address> addressRepo,
        IRepository<Order> orderRepo,
        IRepository<UserPaymentMethod> paymentMethodRepo,
        IRepository<UserVoucher> userVoucherRepo,
        IRepository<Voucher> voucherRepo,
        IUnitOfWork unitOfWork)
    {
        _userManager = userManager;
        _addressRepo = addressRepo;
        _orderRepo = orderRepo;
        _paymentMethodRepo = paymentMethodRepo;
        _userVoucherRepo = userVoucherRepo;
        _voucherRepo = voucherRepo;
        _unitOfWork = unitOfWork;
    }

    // ── List / Detail ──────────────────────────────────────────────────────────

    public async Task<PagedResult<UserDto>> GetAllUsersAsync(int page, int pageSize, string? search = null)
    {
        var query = _userManager.Users.AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.ToLower();
            query = query.Where(u =>
                u.FirstName.ToLower().Contains(term) ||
                u.LastName.ToLower().Contains(term) ||
                u.Email!.ToLower().Contains(term));
        }

        var totalCount = await query.CountAsync();

        var users = await query
            .OrderByDescending(u => u.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Include(u => u.Orders)
            .ToListAsync();

        var items = new List<UserDto>();
        foreach (var user in users)
        {
            var roles = await _userManager.GetRolesAsync(user);
            items.Add(MapToDto(user, roles, user.Orders.Count));
        }

        return new PagedResult<UserDto>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<UserDto?> GetByIdAsync(Guid id)
    {
        var user = await _userManager.Users
            .Include(u => u.Orders)
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user is null) return null;

        var roles = await _userManager.GetRolesAsync(user);
        return MapToDto(user, roles, user.Orders.Count);
    }

    public async Task<bool> ToggleActiveAsync(Guid id)
    {
        var user = await _userManager.FindByIdAsync(id.ToString());
        if (user is null) return false;

        var isCurrentlyActive = user.LockoutEnd is null || user.LockoutEnd <= DateTimeOffset.UtcNow;
        await _userManager.SetLockoutEndDateAsync(user,
            isCurrentlyActive ? DateTimeOffset.UtcNow.AddYears(100) : null);
        return true;
    }

    // ── Addresses ──────────────────────────────────────────────────────────────

    public async Task<IEnumerable<AddressDto>> GetUserAddressesAsync(Guid userId)
    {
        var addresses = await _addressRepo.FindAsync(a => a.UserId == userId);
        return addresses.OrderByDescending(a => a.IsDefault).ThenBy(a => a.Label).Select(MapAddress);
    }

    public async Task<AddressDto> AdminCreateAddressAsync(Guid userId, CreateAddressRequest request)
    {
        var address = new Address
        {
            UserId = userId,
            Label = request.Label,
            Street = request.Street,
            City = request.City,
            Province = request.Province,
            ZipCode = request.ZipCode,
            Country = request.Country ?? "Philippines",
            DeliveryInstructions = request.DeliveryInstructions,
            ContactNumber = request.ContactNumber,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            IsDefault = request.IsDefault
        };

        if (request.IsDefault)
        {
            var existing = await _addressRepo.FindAsync(a => a.UserId == userId && a.IsDefault);
            foreach (var e in existing) { e.IsDefault = false; _addressRepo.Update(e); }
        }

        await _addressRepo.AddAsync(address);
        await _unitOfWork.SaveChangesAsync();
        return MapAddress(address);
    }

    public async Task<AddressDto?> AdminUpdateAddressAsync(Guid userId, Guid addressId, UpdateAddressRequest request)
    {
        var address = await _addressRepo.FirstOrDefaultAsync(a => a.Id == addressId && a.UserId == userId);
        if (address is null) return null;

        if (request.Label is not null) address.Label = request.Label;
        if (request.Street is not null) address.Street = request.Street;
        if (request.City is not null) address.City = request.City;
        if (request.Province is not null) address.Province = request.Province;
        if (request.ZipCode is not null) address.ZipCode = request.ZipCode;
        if (request.Country is not null) address.Country = request.Country;
        if (request.DeliveryInstructions is not null) address.DeliveryInstructions = request.DeliveryInstructions;
        if (request.ContactNumber is not null) address.ContactNumber = request.ContactNumber;
        if (request.Latitude.HasValue) address.Latitude = request.Latitude;
        if (request.Longitude.HasValue) address.Longitude = request.Longitude;
        if (request.IsDefault.HasValue && request.IsDefault.Value)
        {
            var existing = await _addressRepo.FindAsync(a => a.UserId == userId && a.IsDefault && a.Id != addressId);
            foreach (var e in existing) { e.IsDefault = false; _addressRepo.Update(e); }
            address.IsDefault = true;
        }

        _addressRepo.Update(address);
        await _unitOfWork.SaveChangesAsync();
        return MapAddress(address);
    }

    public async Task<bool> AdminDeleteAddressAsync(Guid userId, Guid addressId)
    {
        var address = await _addressRepo.FirstOrDefaultAsync(a => a.Id == addressId && a.UserId == userId);
        if (address is null) return false;
        _addressRepo.Remove(address);
        await _unitOfWork.SaveChangesAsync();
        return true;
    }

    // ── Orders ─────────────────────────────────────────────────────────────────

    public async Task<IEnumerable<OrderDto>> GetUserOrdersAsync(Guid userId)
    {
        var orders = await _orderRepo.Query()
            .Where(o => o.UserId == userId)
            .OrderByDescending(o => o.CreatedAt)
            .ToListAsync();

        return orders.Select(o => new OrderDto
        {
            Id = o.Id,
            OrderNumber = o.OrderNumber,
            SubTotal = o.SubTotal,
            DiscountAmount = o.DiscountAmount,
            DeliveryFee = o.DeliveryFee,
            PlatformFee = o.PlatformFee,
            OtherCharges = o.OtherCharges,
            TotalAmount = o.TotalAmount,
            Status = o.Status.ToString(),
            Notes = o.Notes,
            CreatedAt = o.CreatedAt
        });
    }

    // ── Payment Methods ────────────────────────────────────────────────────────

    public async Task<IEnumerable<PaymentMethodDto>> GetUserPaymentMethodsAsync(Guid userId)
    {
        var methods = await _paymentMethodRepo.FindAsync(p => p.UserId == userId);
        return methods.OrderByDescending(p => p.IsDefault).ThenBy(p => p.Name).Select(MapPaymentMethod);
    }

    public async Task<PaymentMethodDto> AdminCreatePaymentMethodAsync(Guid userId, CreatePaymentMethodRequest request)
    {
        if (request.IsDefault)
        {
            var existing = await _paymentMethodRepo.FindAsync(p => p.UserId == userId && p.IsDefault);
            foreach (var e in existing) { e.IsDefault = false; _paymentMethodRepo.Update(e); }
        }

        var method = new UserPaymentMethod
        {
            UserId = userId,
            Name = request.Name,
            Detail = request.Detail,
            PaymentType = request.PaymentType,
            Icon = request.Icon,
            IsDefault = request.IsDefault
        };

        await _paymentMethodRepo.AddAsync(method);
        await _unitOfWork.SaveChangesAsync();
        return MapPaymentMethod(method);
    }

    public async Task<PaymentMethodDto?> AdminUpdatePaymentMethodAsync(Guid userId, Guid id, UpdatePaymentMethodRequest request)
    {
        var method = await _paymentMethodRepo.FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);
        if (method is null) return null;

        if (request.Name is not null) method.Name = request.Name;
        if (request.Detail is not null) method.Detail = request.Detail;
        if (request.PaymentType is not null) method.PaymentType = request.PaymentType;
        if (request.Icon is not null) method.Icon = request.Icon;
        if (request.IsDefault.HasValue && request.IsDefault.Value)
        {
            var existing = await _paymentMethodRepo.FindAsync(p => p.UserId == userId && p.IsDefault && p.Id != id);
            foreach (var e in existing) { e.IsDefault = false; _paymentMethodRepo.Update(e); }
            method.IsDefault = true;
        }

        _paymentMethodRepo.Update(method);
        await _unitOfWork.SaveChangesAsync();
        return MapPaymentMethod(method);
    }

    public async Task<bool> AdminDeletePaymentMethodAsync(Guid userId, Guid id)
    {
        var method = await _paymentMethodRepo.FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);
        if (method is null) return false;
        _paymentMethodRepo.Remove(method);
        await _unitOfWork.SaveChangesAsync();
        return true;
    }

    // ── User Vouchers ──────────────────────────────────────────────────────────

    public async Task<IEnumerable<UserVoucherDto>> GetUserVouchersAsync(Guid userId)
    {
        var uvs = await _userVoucherRepo.Query()
            .Include(uv => uv.Voucher)
            .Where(uv => uv.UserId == userId)
            .OrderByDescending(uv => uv.AssignedAt)
            .ToListAsync();

        return uvs.Select(MapUserVoucher);
    }

    public async Task<UserVoucherDto> AssignVoucherAsync(Guid userId, Guid voucherId)
    {
        var existing = await _userVoucherRepo.FirstOrDefaultAsync(
            uv => uv.UserId == userId && uv.VoucherId == voucherId);
        if (existing is not null)
            throw new InvalidOperationException("Voucher already assigned to this user.");

        var voucher = await _voucherRepo.GetByIdAsync(voucherId)
            ?? throw new InvalidOperationException("Voucher not found.");

        var uv = new UserVoucher
        {
            UserId = userId,
            VoucherId = voucherId,
            AssignedBy = "Admin"
        };

        await _userVoucherRepo.AddAsync(uv);
        await _unitOfWork.SaveChangesAsync();

        uv.Voucher = voucher;
        return MapUserVoucher(uv);
    }

    public async Task<bool> RevokeVoucherAsync(Guid userId, Guid userVoucherId)
    {
        var uv = await _userVoucherRepo.FirstOrDefaultAsync(
            uv => uv.Id == userVoucherId && uv.UserId == userId);
        if (uv is null) return false;
        _userVoucherRepo.Remove(uv);
        await _unitOfWork.SaveChangesAsync();
        return true;
    }

    // ── Verification ───────────────────────────────────────────────────────────

    public async Task<bool> SetEmailVerifiedAsync(Guid userId, bool verified)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user is null) return false;
        user.IsEmailVerified = verified;
        user.UpdatedAt = DateTime.UtcNow;
        await _userManager.UpdateAsync(user);
        return true;
    }

    public async Task<bool> SetPhoneVerifiedAsync(Guid userId, bool verified)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user is null) return false;
        user.IsPhoneVerified = verified;
        user.UpdatedAt = DateTime.UtcNow;
        await _userManager.UpdateAsync(user);
        return true;
    }

    public async Task<bool> SendEmailVerificationAsync(Guid userId)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user is null) return false;

        // Generate a 6-digit code
        var code = new Random().Next(100000, 999999).ToString();
        user.EmailVerificationCode = code;
        user.EmailVerificationSentAt = DateTime.UtcNow;
        user.UpdatedAt = DateTime.UtcNow;
        await _userManager.UpdateAsync(user);

        // TODO: Integrate with email provider (SendGrid, SMTP, etc.)
        // For now, the code is stored and can be validated from the mobile app.
        return true;
    }

    public async Task<bool> SendPhoneVerificationAsync(Guid userId)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user is null) return false;

        // Generate a 6-digit code
        var code = new Random().Next(100000, 999999).ToString();
        user.PhoneVerificationCode = code;
        user.PhoneVerificationSentAt = DateTime.UtcNow;
        user.UpdatedAt = DateTime.UtcNow;
        await _userManager.UpdateAsync(user);

        // TODO: Integrate with SMS provider (Twilio, Semaphore, etc.)
        // For now, the code is stored and can be validated from the mobile app.
        return true;
    }

    // ── Mappers ────────────────────────────────────────────────────────────────

    private static UserDto MapToDto(User user, IList<string> roles, int orderCount) => new()
    {
        Id = user.Id,
        FirstName = user.FirstName,
        LastName = user.LastName,
        Email = user.Email ?? string.Empty,
        PhoneNumber = user.PhoneNumber,
        ProfileImageUrl = user.ProfileImageUrl,
        IsActive = user.LockoutEnd is null || user.LockoutEnd <= DateTimeOffset.UtcNow,
        IsEmailVerified = user.IsEmailVerified,
        IsPhoneVerified = user.IsPhoneVerified,
        CreatedAt = user.CreatedAt,
        Roles = roles.ToList(),
        OrderCount = orderCount
    };

    private static AddressDto MapAddress(Address a) => new()
    {
        Id = a.Id,
        Label = a.Label,
        Street = a.Street,
        City = a.City,
        Province = a.Province,
        ZipCode = a.ZipCode,
        Country = a.Country,
        DeliveryInstructions = a.DeliveryInstructions,
        ContactNumber = a.ContactNumber,
        Latitude = a.Latitude,
        Longitude = a.Longitude,
        IsDefault = a.IsDefault
    };

    private static PaymentMethodDto MapPaymentMethod(UserPaymentMethod p) => new()
    {
        Id = p.Id,
        Name = p.Name,
        Detail = p.Detail,
        PaymentType = p.PaymentType,
        Icon = p.Icon,
        IsDefault = p.IsDefault,
        CreatedAt = p.CreatedAt
    };

    private static UserVoucherDto MapUserVoucher(UserVoucher uv) => new()
    {
        Id = uv.Id,
        UserId = uv.UserId,
        VoucherId = uv.VoucherId,
        VoucherCode = uv.Voucher?.Code ?? string.Empty,
        VoucherDescription = uv.Voucher?.Description,
        VoucherType = uv.Voucher?.Type.ToString() ?? string.Empty,
        VoucherValue = uv.Voucher?.Value ?? 0,
        ExpiryDate = uv.Voucher?.ExpiryDate ?? DateTime.MinValue,
        IsUsed = uv.IsUsed,
        UsedAt = uv.UsedAt,
        AssignedAt = uv.AssignedAt,
        AssignedBy = uv.AssignedBy
    };
}
