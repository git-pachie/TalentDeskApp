using GroceryApp.Application.DTOs.Addresses;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;

namespace GroceryApp.Application.Services;

public class AddressService : IAddressService
{
    private readonly IRepository<Address> _addressRepo;
    private readonly IGeocodingService _geocodingService;
    private readonly IUnitOfWork _unitOfWork;

    public AddressService(
        IRepository<Address> addressRepo,
        IGeocodingService geocodingService,
        IUnitOfWork unitOfWork)
    {
        _addressRepo = addressRepo;
        _geocodingService = geocodingService;
        _unitOfWork = unitOfWork;
    }

    public async Task<IEnumerable<AddressDto>> GetUserAddressesAsync(Guid userId)
    {
        var addresses = await _addressRepo.FindAsync(a => a.UserId == userId);
        return addresses.Select(MapToDto);
    }

    public async Task<AddressDto?> GetByIdAsync(Guid userId, Guid addressId)
    {
        var address = await _addressRepo.FirstOrDefaultAsync(a => a.Id == addressId && a.UserId == userId);
        return address is null ? null : MapToDto(address);
    }

    public async Task<AddressDto> CreateAsync(Guid userId, CreateAddressRequest request)
    {
        if (request.IsDefault)
        {
            await ClearDefaultAsync(userId);
        }

        var address = new Address
        {
            UserId = userId,
            Label = request.Label,
            Street = request.Street,
            City = request.City,
            Province = request.Province,
            ZipCode = request.ZipCode,
            Country = request.Country ?? "Philippines",
            IsDefault = request.IsDefault
        };

        // Geocode
        var fullAddress = $"{request.Street}, {request.City}, {request.Province}, {request.ZipCode}";
        var coords = await _geocodingService.GeocodeAddressAsync(fullAddress);
        if (coords.HasValue)
        {
            address.Latitude = coords.Value.Latitude;
            address.Longitude = coords.Value.Longitude;
        }

        await _addressRepo.AddAsync(address);
        await _unitOfWork.SaveChangesAsync();

        return MapToDto(address);
    }

    public async Task<AddressDto?> UpdateAsync(Guid userId, Guid addressId, UpdateAddressRequest request)
    {
        var address = await _addressRepo.FirstOrDefaultAsync(a => a.Id == addressId && a.UserId == userId);
        if (address is null) return null;

        if (request.Label is not null) address.Label = request.Label;
        if (request.Street is not null) address.Street = request.Street;
        if (request.City is not null) address.City = request.City;
        if (request.Province is not null) address.Province = request.Province;
        if (request.ZipCode is not null) address.ZipCode = request.ZipCode;
        if (request.Country is not null) address.Country = request.Country;

        if (request.IsDefault == true)
        {
            await ClearDefaultAsync(userId);
            address.IsDefault = true;
        }

        // Re-geocode if address changed
        if (request.Street is not null || request.City is not null || request.Province is not null)
        {
            var fullAddress = $"{address.Street}, {address.City}, {address.Province}, {address.ZipCode}";
            var coords = await _geocodingService.GeocodeAddressAsync(fullAddress);
            if (coords.HasValue)
            {
                address.Latitude = coords.Value.Latitude;
                address.Longitude = coords.Value.Longitude;
            }
        }

        _addressRepo.Update(address);
        await _unitOfWork.SaveChangesAsync();

        return MapToDto(address);
    }

    public async Task<bool> DeleteAsync(Guid userId, Guid addressId)
    {
        var address = await _addressRepo.FirstOrDefaultAsync(a => a.Id == addressId && a.UserId == userId);
        if (address is null) return false;

        _addressRepo.Remove(address);
        await _unitOfWork.SaveChangesAsync();
        return true;
    }

    private async Task ClearDefaultAsync(Guid userId)
    {
        var defaults = await _addressRepo.FindAsync(a => a.UserId == userId && a.IsDefault);
        foreach (var addr in defaults)
        {
            addr.IsDefault = false;
            _addressRepo.Update(addr);
        }
    }

    private static AddressDto MapToDto(Address address)
    {
        return new AddressDto
        {
            Id = address.Id,
            Label = address.Label,
            Street = address.Street,
            City = address.City,
            Province = address.Province,
            ZipCode = address.ZipCode,
            Country = address.Country,
            Latitude = address.Latitude,
            Longitude = address.Longitude,
            IsDefault = address.IsDefault
        };
    }
}
