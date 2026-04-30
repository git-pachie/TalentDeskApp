namespace GroceryApp.Application.DTOs.Addresses;

public class AddressDto
{
    public Guid Id { get; set; }
    public string Label { get; set; } = string.Empty;
    public string Street { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string Province { get; set; } = string.Empty;
    public string ZipCode { get; set; } = string.Empty;
    public string? Country { get; set; }
    public string? DeliveryInstructions { get; set; }
    public string? ContactNumber { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public bool IsDefault { get; set; }
}

public class CreateAddressRequest
{
    public string Label { get; set; } = string.Empty;
    public string Street { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string Province { get; set; } = string.Empty;
    public string ZipCode { get; set; } = string.Empty;
    public string? Country { get; set; }
    public string? DeliveryInstructions { get; set; }
    public string? ContactNumber { get; set; }
    public bool IsDefault { get; set; }
}

public class UpdateAddressRequest
{
    public string? Label { get; set; }
    public string? Street { get; set; }
    public string? City { get; set; }
    public string? Province { get; set; }
    public string? ZipCode { get; set; }
    public string? Country { get; set; }
    public string? DeliveryInstructions { get; set; }
    public string? ContactNumber { get; set; }
    public bool? IsDefault { get; set; }
}
