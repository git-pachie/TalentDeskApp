using GroceryApp.Application.DTOs.SpecialOffers;

namespace GroceryApp.Application.Interfaces;

public interface ISpecialOfferService
{
    Task<IEnumerable<SpecialOfferDto>> GetAllAsync(bool includeInactive = false);
    Task<SpecialOfferDto?> GetByIdAsync(Guid id);
    Task<SpecialOfferDto> CreateAsync(CreateSpecialOfferRequest request);
    Task<SpecialOfferDto?> UpdateAsync(Guid id, UpdateSpecialOfferRequest request);
    Task<bool> DeleteAsync(Guid id);
}
