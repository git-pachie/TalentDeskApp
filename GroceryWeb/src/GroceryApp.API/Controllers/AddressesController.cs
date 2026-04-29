using System.Security.Claims;
using GroceryApp.Application.DTOs.Addresses;
using GroceryApp.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.API.Controllers;

[ApiController]
[Route("api/addresses")]
[Authorize]
public class AddressesController : ControllerBase
{
    private readonly IAddressService _addressService;

    public AddressesController(IAddressService addressService)
    {
        _addressService = addressService;
    }

    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var addresses = await _addressService.GetUserAddressesAsync(UserId);
        return Ok(addresses);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateAddressRequest request)
    {
        var address = await _addressService.CreateAsync(UserId, request);
        return CreatedAtAction(nameof(GetAll), address);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateAddressRequest request)
    {
        var address = await _addressService.UpdateAsync(UserId, id, request);
        return address is null ? NotFound() : Ok(address);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var result = await _addressService.DeleteAsync(UserId, id);
        return result ? NoContent() : NotFound();
    }
}
