using System.Security.Claims;
using GroceryApp.Application.DTOs.Cart;
using GroceryApp.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.API.Controllers;

[ApiController]
[Route("api/cart")]
[Authorize]
public class CartController : ControllerBase
{
    private readonly ICartService _cartService;

    public CartController(ICartService cartService)
    {
        _cartService = cartService;
    }

    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpGet]
    public async Task<IActionResult> GetCart()
    {
        var items = await _cartService.GetCartAsync(UserId);
        return Ok(items);
    }

    [HttpPost]
    public async Task<IActionResult> AddToCart([FromBody] AddToCartRequest request)
    {
        var item = await _cartService.AddToCartAsync(UserId, request);
        return Ok(item);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateCartItem(Guid id, [FromBody] UpdateCartItemRequest request)
    {
        var item = await _cartService.UpdateCartItemAsync(UserId, id, request);
        return item is null ? NotFound() : Ok(item);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> RemoveCartItem(Guid id)
    {
        var result = await _cartService.RemoveCartItemAsync(UserId, id);
        return result ? NoContent() : NotFound();
    }
}
