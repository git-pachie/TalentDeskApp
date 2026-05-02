using GroceryApp.Application.DTOs.Products;
using GroceryApp.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace GroceryApp.API.Controllers;

[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    private readonly IProductService _productService;
    private readonly IConfiguration _configuration;

    public ProductsController(IProductService productService, IConfiguration configuration)
    {
        _productService = productService;
        _configuration = configuration;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] ProductQueryParams queryParams)
    {
        if (User.IsInRole("StoreOwner"))
        {
            queryParams.OwnerUserId = GetCurrentUserId();
        }
        var result = await _productService.GetAllAsync(queryParams);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var product = await _productService.GetByIdAsync(id, User.IsInRole("StoreOwner") ? GetCurrentUserId() : null);
        return product is null ? NotFound() : Ok(product);
    }

    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] string q, [FromQuery] Guid? categoryId = null, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var queryParams = new ProductQueryParams
        {
            Search = q,
            CategoryId = categoryId,
            Page = page,
            PageSize = pageSize,
            IncludeInactive = true
        };
        var result = await _productService.GetAllAsync(queryParams);
        return Ok(result);
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Staff,StoreOwner")]
    public async Task<IActionResult> Create([FromBody] CreateProductRequest request)
    {
        var product = await _productService.CreateAsync(request, User.IsInRole("StoreOwner") ? GetCurrentUserId() : null);
        return CreatedAtAction(nameof(GetById), new { id = product.Id }, product);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = "Admin,Staff,StoreOwner")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateProductRequest request)
    {
        var product = await _productService.UpdateAsync(id, request, User.IsInRole("StoreOwner") ? GetCurrentUserId() : null);
        return product is null ? NotFound() : Ok(product);
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "Admin,Staff,StoreOwner")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var result = await _productService.DeleteAsync(id, User.IsInRole("StoreOwner") ? GetCurrentUserId() : null);
        return result ? NoContent() : NotFound();
    }

    /// <summary>
    /// Upload multiple product images. Returns the generated URLs.
    /// </summary>
    [HttpPost("images/upload")]
    [Authorize(Roles = "Admin,Staff,StoreOwner")]
    [RequestSizeLimit(50 * 1024 * 1024)] // 50 MB
    public async Task<IActionResult> UploadImages([FromForm] List<IFormFile> files)
    {
        if (files is null || files.Count == 0)
            return BadRequest(new { error = "No files provided." });

        var allowedExtensions = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".jpg", ".jpeg", ".png", ".gif", ".webp" };

        var basePath = _configuration["Storage:UploadPath"] ?? "wwwroot/uploads";
        if (!Path.IsPathRooted(basePath))
            basePath = Path.Combine(Directory.GetCurrentDirectory(), basePath);

        var urlPrefix = _configuration["Storage:UrlPrefix"] ?? "/uploads";

        var uploadDir = Path.Combine(basePath, "products");
        Directory.CreateDirectory(uploadDir);

        var uploadedUrls = new List<string>();

        foreach (var file in files)
        {
            if (file.Length == 0) continue;

            var ext = Path.GetExtension(file.FileName);
            if (!allowedExtensions.Contains(ext))
                continue;

            var newFileName = $"{Guid.NewGuid():N}{ext}";
            var filePath = Path.Combine(uploadDir, newFileName);

            await using var stream = new FileStream(filePath, FileMode.Create);
            await file.CopyToAsync(stream);

            uploadedUrls.Add(newFileName);
        }

        return Ok(new { urls = uploadedUrls });
    }

    private Guid? GetCurrentUserId()
    {
        var claim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(claim, out var userId) ? userId : null;
    }
}
