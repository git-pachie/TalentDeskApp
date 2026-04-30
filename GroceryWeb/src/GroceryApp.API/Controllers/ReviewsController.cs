using System.Security.Claims;
using GroceryApp.Application.DTOs.Reviews;
using GroceryApp.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.API.Controllers;

[ApiController]
[Route("api")]
public class ReviewsController : ControllerBase
{
    private readonly IReviewService _reviewService;
    private readonly IConfiguration _configuration;

    public ReviewsController(IReviewService reviewService, IConfiguration configuration)
    {
        _reviewService = reviewService;
        _configuration = configuration;
    }

    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // ── Create review (per product) ────────────────────────────────────────────

    [HttpPost("reviews")]
    [Authorize]
    public async Task<IActionResult> Create([FromBody] CreateReviewRequest request)
    {
        try
        {
            var review = await _reviewService.CreateAsync(UserId, request);
            return CreatedAtAction(nameof(GetProductReviews), new { productId = review.ProductId }, review);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    // ── Get reviews by order ───────────────────────────────────────────────────

    [HttpGet("orders/{orderId:guid}/reviews")]
    [Authorize]
    public async Task<IActionResult> GetOrderReviews(Guid orderId)
    {
        var reviews = await _reviewService.GetOrderReviewsAsync(orderId);
        return Ok(reviews);
    }

    // ── Get reviews by product ─────────────────────────────────────────────────

    [HttpGet("products/{productId:guid}/reviews")]
    public async Task<IActionResult> GetProductReviews(Guid productId)
    {
        var reviews = await _reviewService.GetProductReviewsAsync(productId);
        return Ok(reviews);
    }

    // ── Get all reviews (admin) ────────────────────────────────────────────────

    [HttpGet("reviews")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAll([FromQuery] int page = 1, [FromQuery] int pageSize = 50)
    {
        var reviews = await _reviewService.GetAllReviewsAsync(page, pageSize);
        return Ok(reviews);
    }

    // ── Delete review (admin) ──────────────────────────────────────────────────

    [HttpDelete("reviews/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var result = await _reviewService.DeleteAsync(id);
        return result ? NoContent() : NotFound();
    }

    // ── Upload review photos ───────────────────────────────────────────────────

    [HttpPost("reviews/upload")]
    [Authorize]
    [RequestSizeLimit(30 * 1024 * 1024)] // 30 MB
    public async Task<IActionResult> UploadPhotos([FromForm] List<IFormFile> files)
    {
        if (files is null || files.Count == 0)
            return BadRequest(new { error = "No files provided." });

        var allowed = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".jpg", ".jpeg", ".png", ".webp", ".heic" };

        var basePath = _configuration["Storage:UploadPath"] ?? "wwwroot/uploads";
        if (!Path.IsPathRooted(basePath))
            basePath = Path.Combine(Directory.GetCurrentDirectory(), basePath);

        var urlPrefix = (_configuration["Storage:UrlPrefix"] ?? "/uploads").TrimEnd('/');
        var uploadDir = Path.Combine(basePath, "reviews");
        Directory.CreateDirectory(uploadDir);

        var urls = new List<string>();

        foreach (var file in files)
        {
            var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!allowed.Contains(ext)) continue;
            if (file.Length > 10 * 1024 * 1024) continue; // 10 MB per file

            var fileName = $"{Guid.NewGuid():N}{ext}";
            var filePath = Path.Combine(uploadDir, fileName);

            await using var stream = new FileStream(filePath, FileMode.Create);
            await file.CopyToAsync(stream);

            // Return full URL
            var baseUrl = (_configuration["App:BaseUrl"] ?? "").TrimEnd('/');
            urls.Add($"{baseUrl}{urlPrefix}/reviews/{fileName}");
        }

        return Ok(new { urls });
    }
}
