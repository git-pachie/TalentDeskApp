namespace GroceryApp.Application.DTOs.SpecialOffers;

public class SpecialOfferDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Subtitle { get; set; } = string.Empty;
    public string Emoji { get; set; } = string.Empty;
    public string BackgroundColorHex { get; set; } = string.Empty;
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class CreateSpecialOfferRequest
{
    public string Title { get; set; } = string.Empty;
    public string Subtitle { get; set; } = string.Empty;
    public string Emoji { get; set; } = string.Empty;
    public string BackgroundColorHex { get; set; } = "#E8F3FF";
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
}

public class UpdateSpecialOfferRequest
{
    public string? Title { get; set; }
    public string? Subtitle { get; set; }
    public string? Emoji { get; set; }
    public string? BackgroundColorHex { get; set; }
    public int? SortOrder { get; set; }
    public bool? IsActive { get; set; }
}
