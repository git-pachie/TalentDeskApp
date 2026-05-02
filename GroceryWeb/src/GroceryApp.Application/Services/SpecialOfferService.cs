using GroceryApp.Application.DTOs.SpecialOffers;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace GroceryApp.Application.Services;

public class SpecialOfferService : ISpecialOfferService
{
    private readonly IRepository<SpecialOffer> _specialOfferRepo;
    private readonly IUnitOfWork _unitOfWork;

    public SpecialOfferService(IRepository<SpecialOffer> specialOfferRepo, IUnitOfWork unitOfWork)
    {
        _specialOfferRepo = specialOfferRepo;
        _unitOfWork = unitOfWork;
    }

    public async Task<IEnumerable<SpecialOfferDto>> GetAllAsync(bool includeInactive = false)
    {
        var query = _specialOfferRepo.Query();
        if (!includeInactive)
            query = query.Where(o => o.IsActive);

        var offers = await query
            .OrderBy(o => o.SortOrder)
            .ThenBy(o => o.CreatedAt)
            .ToListAsync();

        return offers.Select(MapToDto);
    }

    public async Task<SpecialOfferDto?> GetByIdAsync(Guid id)
    {
        var offer = await _specialOfferRepo.GetByIdAsync(id);
        return offer is null ? null : MapToDto(offer);
    }

    public async Task<SpecialOfferDto> CreateAsync(CreateSpecialOfferRequest request)
    {
        var offer = new SpecialOffer
        {
            Title = request.Title,
            Subtitle = request.Subtitle,
            Emoji = request.Emoji,
            BackgroundColorHex = request.BackgroundColorHex,
            SortOrder = request.SortOrder,
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        await _specialOfferRepo.AddAsync(offer);
        await _unitOfWork.SaveChangesAsync();

        return MapToDto(offer);
    }

    public async Task<SpecialOfferDto?> UpdateAsync(Guid id, UpdateSpecialOfferRequest request)
    {
        var offer = await _specialOfferRepo.GetByIdAsync(id);
        if (offer is null) return null;

        if (request.Title is not null) offer.Title = request.Title;
        if (request.Subtitle is not null) offer.Subtitle = request.Subtitle;
        if (request.Emoji is not null) offer.Emoji = request.Emoji;
        if (request.BackgroundColorHex is not null) offer.BackgroundColorHex = request.BackgroundColorHex;
        if (request.SortOrder.HasValue) offer.SortOrder = request.SortOrder.Value;
        if (request.IsActive.HasValue) offer.IsActive = request.IsActive.Value;
        offer.UpdatedAt = DateTime.UtcNow;

        _specialOfferRepo.Update(offer);
        await _unitOfWork.SaveChangesAsync();

        return MapToDto(offer);
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var offer = await _specialOfferRepo.GetByIdAsync(id);
        if (offer is null) return false;

        _specialOfferRepo.Remove(offer);
        await _unitOfWork.SaveChangesAsync();
        return true;
    }

    private static SpecialOfferDto MapToDto(SpecialOffer offer) => new()
    {
        Id = offer.Id,
        Title = offer.Title,
        Subtitle = offer.Subtitle,
        Emoji = offer.Emoji,
        BackgroundColorHex = offer.BackgroundColorHex,
        SortOrder = offer.SortOrder,
        IsActive = offer.IsActive,
        CreatedAt = offer.CreatedAt,
        UpdatedAt = offer.UpdatedAt
    };
}
