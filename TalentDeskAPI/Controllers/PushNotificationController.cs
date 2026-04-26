using Microsoft.AspNetCore.Mvc;
using TalentDeskAPI.Models;
using TalentDeskAPI.Services;

namespace TalentDeskAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PushNotificationController : ControllerBase
{
    private readonly ApnsService _apnsService;

    public PushNotificationController(ApnsService apnsService)
    {
        _apnsService = apnsService;
    }

    /// <summary>
    /// Send a push notification to an iOS device via APNs.
    /// </summary>
    [HttpPost("send")]
    public async Task<IActionResult> Send([FromBody] PushNotificationRequest request)
    {
        var result = await _apnsService.SendAsync(request);

        return result.Success
            ? Ok(result)
            : StatusCode(result.StatusCode > 0 ? result.StatusCode : 502, result);
    }
}
