using GroceryApp.Application.DTOs.PaymentMethods;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace GroceryApp.Application.Services;

public class PaymentMethodService : IPaymentMethodService
{
    private readonly IRepository<UserPaymentMethod> _paymentMethodRepo;
    private readonly IUnitOfWork _unitOfWork;

    public PaymentMethodService(IRepository<UserPaymentMethod> paymentMethodRepo, IUnitOfWork unitOfWork)
    {
        _paymentMethodRepo = paymentMethodRepo;
        _unitOfWork = unitOfWork;
    }

    public async Task<IEnumerable<PaymentMethodDto>> GetUserPaymentMethodsAsync(Guid userId)
    {
        var methods = await _paymentMethodRepo.Query()
            .Where(pm => pm.UserId == userId)
            .OrderByDescending(pm => pm.IsDefault)
            .ThenByDescending(pm => pm.CreatedAt)
            .ToListAsync();

        return methods.Select(MapToDto);
    }

    public async Task<PaymentMethodDto?> GetByIdAsync(Guid userId, Guid id)
    {
        var method = await _paymentMethodRepo.FirstOrDefaultAsync(pm => pm.Id == id && pm.UserId == userId);
        return method is null ? null : MapToDto(method);
    }

    public async Task<PaymentMethodDto> CreateAsync(Guid userId, CreatePaymentMethodRequest request)
    {
        // If setting as default, clear other defaults
        if (request.IsDefault)
        {
            var existing = await _paymentMethodRepo.FindAsync(pm => pm.UserId == userId && pm.IsDefault);
            foreach (var pm in existing)
            {
                pm.IsDefault = false;
                _paymentMethodRepo.Update(pm);
            }
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

        return MapToDto(method);
    }

    public async Task<PaymentMethodDto?> UpdateAsync(Guid userId, Guid id, UpdatePaymentMethodRequest request)
    {
        var method = await _paymentMethodRepo.FirstOrDefaultAsync(pm => pm.Id == id && pm.UserId == userId);
        if (method is null) return null;

        if (request.Name is not null) method.Name = request.Name;
        if (request.Detail is not null) method.Detail = request.Detail;
        if (request.PaymentType is not null) method.PaymentType = request.PaymentType;
        if (request.Icon is not null) method.Icon = request.Icon;

        if (request.IsDefault == true)
        {
            var existing = await _paymentMethodRepo.FindAsync(pm => pm.UserId == userId && pm.IsDefault && pm.Id != id);
            foreach (var pm in existing)
            {
                pm.IsDefault = false;
                _paymentMethodRepo.Update(pm);
            }
            method.IsDefault = true;
        }
        else if (request.IsDefault == false)
        {
            method.IsDefault = false;
        }

        _paymentMethodRepo.Update(method);
        await _unitOfWork.SaveChangesAsync();

        return MapToDto(method);
    }

    public async Task<bool> DeleteAsync(Guid userId, Guid id)
    {
        var method = await _paymentMethodRepo.FirstOrDefaultAsync(pm => pm.Id == id && pm.UserId == userId);
        if (method is null) return false;

        _paymentMethodRepo.Remove(method);
        await _unitOfWork.SaveChangesAsync();
        return true;
    }

    private static PaymentMethodDto MapToDto(UserPaymentMethod method)
    {
        return new PaymentMethodDto
        {
            Id = method.Id,
            Name = method.Name,
            Detail = method.Detail,
            PaymentType = method.PaymentType,
            Icon = method.Icon,
            IsDefault = method.IsDefault,
            CreatedAt = method.CreatedAt
        };
    }
}
