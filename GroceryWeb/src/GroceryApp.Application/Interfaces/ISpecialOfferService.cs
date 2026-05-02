using GroceryApp.Application.DTOs.SpecialOffers;

namespace GroceryApp.Application.Interfaces;

public interface ISpecialOfferService
{
    Task<IEnumerable<SpecialOfferDto>> GetAllAsync(bool includeInactive = false, Guid? ownerUserId = null);
    Task<SpecialOfferDto?> GetByIdAsync(Guid id, Guid? ownerUserId = null);
    Task<SpecialOfferDto> CreateAsync(CreateSpecialOfferRequest request, Guid? ownerUserId = null);
    Task<SpecialOfferDto?> UpdateAsync(Guid id, UpdateSpecialOfferRequest request, Guid? ownerUserId = null);
    Task<bool> DeleteAsync(Guid id, Guid? ownerUserId = null);
}
