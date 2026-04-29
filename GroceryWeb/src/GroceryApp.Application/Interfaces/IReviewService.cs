using GroceryApp.Application.DTOs.Reviews;

namespace GroceryApp.Application.Interfaces;

public interface IReviewService
{
    Task<ReviewDto> CreateAsync(Guid userId, CreateReviewRequest request);
    Task<IEnumerable<ReviewDto>> GetProductReviewsAsync(Guid productId);
}
