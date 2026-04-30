using GroceryApp.Application.DTOs.Reviews;

namespace GroceryApp.Application.Interfaces;

public interface IReviewService
{
    Task<ReviewDto> CreateAsync(Guid userId, CreateReviewRequest request);
    Task<IEnumerable<ReviewDto>> GetOrderReviewsAsync(Guid orderId);
    Task<IEnumerable<ReviewDto>> GetProductReviewsAsync(Guid productId);
    Task<IEnumerable<ReviewDto>> GetAllReviewsAsync(int page, int pageSize);
    Task<bool> DeleteAsync(Guid reviewId);
}
