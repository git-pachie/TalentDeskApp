using GroceryApp.Application.DTOs.SpecialOffers;
using GroceryApp.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace GroceryApp.API.Controllers;

[ApiController]
[Route("api/special-offers")]
public class SpecialOffersController : ControllerBase
{
    private readonly ISpecialOfferService _specialOfferService;

    public SpecialOffersController(ISpecialOfferService specialOfferService)
    {
        _specialOfferService = specialOfferService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] bool includeInactive = false)
    {
        var offers = await _specialOfferService.GetAllAsync(includeInactive, User.IsInRole("StoreOwner") ? GetCurrentUserId() : null);
        return Ok(offers);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var offer = await _specialOfferService.GetByIdAsync(id, User.IsInRole("StoreOwner") ? GetCurrentUserId() : null);
        return offer is null ? NotFound() : Ok(offer);
    }

    [HttpPost]
    [Authorize(Roles = "Admin,StoreOwner")]
    public async Task<IActionResult> Create([FromBody] CreateSpecialOfferRequest request)
    {
        var offer = await _specialOfferService.CreateAsync(request, User.IsInRole("StoreOwner") ? GetCurrentUserId() : null);
        return CreatedAtAction(nameof(GetById), new { id = offer.Id }, offer);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = "Admin,StoreOwner")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateSpecialOfferRequest request)
    {
        var offer = await _specialOfferService.UpdateAsync(id, request, User.IsInRole("StoreOwner") ? GetCurrentUserId() : null);
        return offer is null ? NotFound() : Ok(offer);
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "Admin,StoreOwner")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var deleted = await _specialOfferService.DeleteAsync(id, User.IsInRole("StoreOwner") ? GetCurrentUserId() : null);
        return deleted ? NoContent() : NotFound();
    }

    [HttpPost("images/upload")]
    [Authorize(Roles = "Admin,StoreOwner")]
    [RequestSizeLimit(50 * 1024 * 1024)]
    public async Task<IActionResult> UploadImages([FromForm] List<IFormFile> files, [FromServices] IConfiguration configuration)
    {
        if (files is null || files.Count == 0)
            return BadRequest(new { error = "No files provided." });

        var allowedExtensions = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
        var basePath = configuration["Storage:UploadPath"] ?? "wwwroot/uploads";
        if (!Path.IsPathRooted(basePath))
            basePath = Path.Combine(Directory.GetCurrentDirectory(), basePath);

        var uploadDir = Path.Combine(basePath, "special-offers");
        Directory.CreateDirectory(uploadDir);

        var uploadedUrls = new List<string>();
        foreach (var file in files)
        {
            if (file.Length == 0) continue;
            var ext = Path.GetExtension(file.FileName);
            if (!allowedExtensions.Contains(ext)) continue;

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
