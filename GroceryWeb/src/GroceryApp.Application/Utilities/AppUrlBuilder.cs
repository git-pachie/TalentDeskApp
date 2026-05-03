namespace GroceryApp.Application.Utilities;

public static class AppUrlBuilder
{
    public static string NormalizeAbsoluteUrl(string? appBaseUrl, string? url)
    {
        if (string.IsNullOrWhiteSpace(url))
            return url ?? string.Empty;

        if (!Uri.TryCreate(url, UriKind.Absolute, out var sourceUri))
            return url;

        var host = sourceUri.Host.ToLowerInvariant();
        if (host != "localhost" && host != "127.0.0.1")
            return url;

        var baseUrl = (appBaseUrl ?? string.Empty).Trim().TrimEnd('/');
        if (!Uri.TryCreate(baseUrl, UriKind.Absolute, out var targetBaseUri))
            return url;

        var builder = new UriBuilder(targetBaseUri)
        {
            Path = sourceUri.AbsolutePath,
            Query = sourceUri.Query.TrimStart('?')
        };
        return builder.Uri.ToString();
    }

    public static string GetUploadsBase(string? appBaseUrl, string folder)
    {
        var baseUrl = (appBaseUrl ?? string.Empty).Trim().TrimEnd('/');
        if (string.IsNullOrEmpty(baseUrl))
            return string.Empty;

        return $"{baseUrl}/uploads/{folder.Trim('/')}";
    }

    public static string? BuildUploadUrl(string? appBaseUrl, string folder, string? imageUrl)
    {
        if (string.IsNullOrWhiteSpace(imageUrl))
            return imageUrl;

        if (imageUrl.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
            imageUrl.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            return NormalizeAbsoluteUrl(appBaseUrl, imageUrl);

        var fileName = imageUrl.Contains('/') ? imageUrl.Split('/').Last() : imageUrl;
        var uploadsBase = GetUploadsBase(appBaseUrl, folder);
        if (string.IsNullOrEmpty(uploadsBase))
            return $"/uploads/{folder.Trim('/')}/{fileName}";

        return $"{uploadsBase}/{fileName}";
    }
}
