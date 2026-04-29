using GroceryApp.Application.DTOs.PaymentMethods;

namespace GroceryApp.Application.Interfaces;

public interface IPaymentMethodService
{
    Task<IEnumerable<PaymentMethodDto>> GetUserPaymentMethodsAsync(Guid userId);
    Task<PaymentMethodDto?> GetByIdAsync(Guid userId, Guid id);
    Task<PaymentMethodDto> CreateAsync(Guid userId, CreatePaymentMethodRequest request);
    Task<PaymentMethodDto?> UpdateAsync(Guid userId, Guid id, UpdatePaymentMethodRequest request);
    Task<bool> DeleteAsync(Guid userId, Guid id);
}
