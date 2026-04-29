using GroceryApp.Application.DTOs.Reviews;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace GroceryApp.Application.Services;

public class ReviewService : IReviewService
{
    private readonly IRepository<Review> _reviewRepo;
    private readonly IRepository<Order> _orderRepo;
    private readonly IUnitOfWork _unitOfWork;

    public ReviewService(
        IRepository<Review> reviewRepo,
        IRepository<Order> orderRepo,
        IUnitOfWork unitOfWork)
    {
        _reviewRepo = reviewRepo;
        _orderRepo = orderRepo;
        _unitOfWork = unitOfWork;
    }

    public async Task<ReviewDto> CreateAsync(Guid userId, CreateReviewRequest request)
    {
        // Validate order is delivered and belongs to user
        var order = await _orderRepo.FirstOrDefaultAsync(
            o => o.Id == request.OrderId && o.UserId == userId && o.Status == OrderStatus.Delivered);

        if (order is null)
            throw new InvalidOperationException("You can only review products from delivered orders.");

        // Check for duplicate review
        var existing = await _reviewRepo.FirstOrDefaultAsync(
            r => r.UserId == userId && r.ProductId == request.ProductId && r.OrderId == request.OrderId);

        if (existing is not null)
            throw new InvalidOperationException("You have already reviewed this product for this order.");

        var review = new Review
        {
            UserId = userId,
            ProductId = request.ProductId,
            OrderId = request.OrderId,
            Rating = Math.Clamp(request.Rating, 1, 5),
            Comment = request.Comment
        };

        // Add photos if provided
        if (request.PhotoUrls is { Count: > 0 })
        {
            for (int i = 0; i < request.PhotoUrls.Count; i++)
            {
                review.Photos.Add(new ReviewPhoto
                {
                    PhotoUrl = request.PhotoUrls[i],
                    SortOrder = i
                });
            }
        }

        await _reviewRepo.AddAsync(review);
        await _unitOfWork.SaveChangesAsync();

        return MapToDto(review);
    }

    public async Task<IEnumerable<ReviewDto>> GetProductReviewsAsync(Guid productId)
    {
        var reviews = await _reviewRepo.Query()
            .Include(r => r.User)
            .Include(r => r.Photos)
            .Where(r => r.ProductId == productId)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

        return reviews.Select(MapToDto);
    }

    public async Task<IEnumerable<ReviewDto>> GetAllReviewsAsync(int page, int pageSize)
    {
        var reviews = await _reviewRepo.Query()
            .Include(r => r.User)
            .Include(r => r.Product)
            .Include(r => r.Photos)
            .OrderByDescending(r => r.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return reviews.Select(MapToDto);
    }

    public async Task<bool> DeleteAsync(Guid reviewId)
    {
        var review = await _reviewRepo.GetByIdAsync(reviewId);
        if (review is null) return false;

        _reviewRepo.Remove(review);
        await _unitOfWork.SaveChangesAsync();
        return true;
    }

    private static ReviewDto MapToDto(Review review)
    {
        return new ReviewDto
        {
            Id = review.Id,
            UserId = review.UserId,
            UserName = review.User is not null ? $"{review.User.FirstName} {review.User.LastName}" : "Anonymous",
            ProductId = review.ProductId,
            Rating = review.Rating,
            Comment = review.Comment,
            CreatedAt = review.CreatedAt,
            Photos = review.Photos.OrderBy(p => p.SortOrder).Select(p => new ReviewPhotoDto
            {
                Id = p.Id,
                PhotoUrl = p.PhotoUrl,
                SortOrder = p.SortOrder
            }).ToList()
        };
    }
}
