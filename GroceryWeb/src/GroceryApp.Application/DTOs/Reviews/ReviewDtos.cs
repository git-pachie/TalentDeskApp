namespace GroceryApp.Application.DTOs.Reviews;

public class ReviewDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public Guid ProductId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<ReviewPhotoDto> Photos { get; set; } = [];
}

public class ReviewPhotoDto
{
    public Guid Id { get; set; }
    public string PhotoUrl { get; set; } = string.Empty;
    public int SortOrder { get; set; }
}

public class CreateReviewRequest
{
    public Guid ProductId { get; set; }
    public Guid OrderId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public List<string>? PhotoUrls { get; set; }
}

/// <summary>Submits a single rating + comment for an entire order (not per-product).</summary>
public class CreateOrderReviewRequest
{
    public Guid OrderId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public List<string>? PhotoUrls { get; set; }
}
