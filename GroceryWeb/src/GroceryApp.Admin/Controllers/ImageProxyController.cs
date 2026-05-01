using GroceryApp.Admin.Filters;
using GroceryApp.Admin.Utilities;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.Admin.Controllers;

/// <summary>
/// Proxies images from the API server through the Admin app so Safari
/// doesn't block mixed-content (HTTPS admin loading HTTP images).
/// Usage: /image-proxy?url=/uploads/reviews/abc.jpg
/// </summary>
[AdminAuth]
public class ImageProxyController : Controller
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _config;

    public ImageProxyController(IHttpClientFactory httpClientFactory, IConfiguration config)
    {
        _httpClientFactory = httpClientFactory;
        _config = config;
    }

    [HttpGet("/image-proxy")]
    [ResponseCache(Duration = 3600, Location = ResponseCacheLocation.Client)]
    public async Task<IActionResult> Proxy([FromQuery] string url)
    {
        if (string.IsNullOrWhiteSpace(url))
            return BadRequest();

        // Build full URL — if relative, prepend API base
        string fullUrl;
        if (url.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
            url.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            fullUrl = AdminUrlBuilder.NormalizeToApiBase(_config["ApiBaseUrl"], url);
        }
        else
        {
            var apiBase = (_config["ApiBaseUrl"] ?? string.Empty).TrimEnd('/');
            fullUrl = $"{apiBase}{(url.StartsWith('/') ? "" : "/")}{url}";
        }

        try
        {
            var client = _httpClientFactory.CreateClient("GroceryApi");
            var response = await client.GetAsync(fullUrl);

            if (!response.IsSuccessStatusCode)
                return NotFound();

            var contentType = response.Content.Headers.ContentType?.MediaType;
            if (string.IsNullOrWhiteSpace(contentType) || contentType == "application/octet-stream")
                contentType = GuessImageContentType(fullUrl);

            if (!contentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
                return BadRequest();

            var bytes = await response.Content.ReadAsByteArrayAsync();
            return File(bytes, contentType);
        }
        catch
        {
            return NotFound();
        }
    }

    private static string GuessImageContentType(string url)
    {
        var path = Uri.TryCreate(url, UriKind.Absolute, out var uri) ? uri.AbsolutePath : url;
        return Path.GetExtension(path).ToLowerInvariant() switch
        {
            ".png" => "image/png",
            ".gif" => "image/gif",
            ".webp" => "image/webp",
            ".svg" => "image/svg+xml",
            ".jpg" or ".jpeg" => "image/jpeg",
            _ => "application/octet-stream"
        };
    }
}
