using GroceryApp.Application.DTOs.SpecialOffers;
using GroceryApp.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

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
        var offers = await _specialOfferService.GetAllAsync(includeInactive);
        return Ok(offers);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var offer = await _specialOfferService.GetByIdAsync(id);
        return offer is null ? NotFound() : Ok(offer);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] CreateSpecialOfferRequest request)
    {
        var offer = await _specialOfferService.CreateAsync(request);
        return CreatedAtAction(nameof(GetById), new { id = offer.Id }, offer);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateSpecialOfferRequest request)
    {
        var offer = await _specialOfferService.UpdateAsync(id, request);
        return offer is null ? NotFound() : Ok(offer);
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var deleted = await _specialOfferService.DeleteAsync(id);
        return deleted ? NoContent() : NotFound();
    }
}
