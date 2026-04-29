using System.Security.Claims;
using GroceryApp.Application.DTOs.UserSettings;
using GroceryApp.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.API.Controllers;

[ApiController]
[Route("api/user-settings")]
[Authorize]
public class UserSettingsController : ControllerBase
{
    private readonly IUserSettingService _userSettingService;

    public UserSettingsController(IUserSettingService userSettingService)
    {
        _userSettingService = userSettingService;
    }

    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var settings = await _userSettingService.GetUserSettingsAsync(UserId);
        return Ok(settings);
    }

    [HttpGet("{key}")]
    public async Task<IActionResult> GetByKey(string key)
    {
        var setting = await _userSettingService.GetSettingAsync(UserId, key);
        return setting is null ? NotFound() : Ok(setting);
    }

    [HttpPut]
    public async Task<IActionResult> Upsert([FromBody] UpdateUserSettingRequest request)
    {
        var setting = await _userSettingService.UpsertSettingAsync(UserId, request);
        return Ok(setting);
    }

    [HttpDelete("{key}")]
    public async Task<IActionResult> Delete(string key)
    {
        var result = await _userSettingService.DeleteSettingAsync(UserId, key);
        return result ? NoContent() : NotFound();
    }
}
