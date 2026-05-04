using GroceryApp.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.API.Controllers;

[ApiController]
[Route("api/riders")]
[Authorize(Roles = "Admin")]
public class RidersController : ControllerBase
{
    private readonly UserManager<User> _userManager;
    private readonly IConfiguration _configuration;

    public RidersController(UserManager<User> userManager, IConfiguration configuration)
    {
        _userManager = userManager;
        _configuration = configuration;
    }

    /// <summary>
    /// Upload a rider profile image. Saves to storage and updates User.ProfileImageUrl.
    /// </summary>
    [HttpPost("{id:guid}/image")]
    [RequestSizeLimit(10 * 1024 * 1024)] // 10 MB
    public async Task<IActionResult> UploadRiderImage(Guid id, [FromForm] IFormFile file)
    {
        if (file is null || file.Length == 0)
            return BadRequest(new { error = "No file provided." });

        var user = await _userManager.FindByIdAsync(id.ToString());
        if (user is null)
            return NotFound(new { error = "Rider not found." });

        var allowed = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".jpg", ".jpeg", ".png", ".webp", ".heic" };

        var ext = Path.GetExtension(file.FileName);
        if (string.IsNullOrWhiteSpace(ext) || !allowed.Contains(ext))
            return BadRequest(new { error = "Unsupported image format." });

        var basePath = _configuration["Storage:UploadPath"] ?? "wwwroot/uploads";
        if (!Path.IsPathRooted(basePath))
            basePath = Path.Combine(Directory.GetCurrentDirectory(), basePath);

        var urlPrefix = (_configuration["Storage:UrlPrefix"] ?? "/uploads").TrimEnd('/');
        var uploadDir = Path.Combine(basePath, "riders");
        Directory.CreateDirectory(uploadDir);

        var fileName = $"{Guid.NewGuid():N}{ext.ToLowerInvariant()}";
        var filePath = Path.Combine(uploadDir, fileName);

        await using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        user.ProfileImageUrl = $"{urlPrefix}/riders/{fileName}";
        user.UpdatedAt = DateTime.UtcNow;
        var result = await _userManager.UpdateAsync(user);
        if (!result.Succeeded)
            return StatusCode(500, new { error = "Failed to update rider profile image." });

        return Ok(new { url = user.ProfileImageUrl });
    }
}

