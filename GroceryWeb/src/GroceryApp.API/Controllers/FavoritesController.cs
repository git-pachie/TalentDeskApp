using System.Security.Claims;
using GroceryApp.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.API.Controllers;

[ApiController]
[Route("api/favorites")]
[Authorize]
public class FavoritesController : ControllerBase
{
    private readonly IFavoriteService _favoriteService;

    public FavoritesController(IFavoriteService favoriteService)
    {
        _favoriteService = favoriteService;
    }

    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpGet]
    public async Task<IActionResult> GetFavorites()
    {
        var favorites = await _favoriteService.GetUserFavoritesAsync(UserId);
        return Ok(favorites);
    }

    [HttpPost("{productId:guid}")]
    public async Task<IActionResult> AddFavorite(Guid productId)
    {
        try
        {
            var favorite = await _favoriteService.AddFavoriteAsync(UserId, productId);
            return Ok(favorite);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { error = ex.Message });
        }
    }

    [HttpDelete("{productId:guid}")]
    public async Task<IActionResult> RemoveFavorite(Guid productId)
    {
        var result = await _favoriteService.RemoveFavoriteAsync(UserId, productId);
        return result ? NoContent() : NotFound();
    }
}
