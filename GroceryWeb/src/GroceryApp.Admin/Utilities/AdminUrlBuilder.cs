namespace GroceryApp.Admin.Utilities;

public static class AdminUrlBuilder
{
    public static string NormalizeToApiBase(string? apiBaseUrl, string url)
    {
        if (string.IsNullOrWhiteSpace(url))
            return url;

        if (!Uri.TryCreate(url, UriKind.Absolute, out var sourceUri))
            return url;

        var host = sourceUri.Host.ToLowerInvariant();
        if (host != "localhost" && host != "127.0.0.1")
            return url;

        var baseUrl = (apiBaseUrl ?? string.Empty).Trim().TrimEnd('/');
        if (!Uri.TryCreate(baseUrl, UriKind.Absolute, out var targetBaseUri))
            return url;

        var builder = new UriBuilder(targetBaseUri)
        {
            Path = sourceUri.AbsolutePath,
            Query = sourceUri.Query.TrimStart('?')
        };
        return builder.Uri.ToString();
    }

    public static string BuildUploadsBase(string? apiBaseUrl, string folder)
    {
        var baseUrl = (apiBaseUrl ?? string.Empty).Trim().TrimEnd('/');
        if (string.IsNullOrEmpty(baseUrl))
            return string.Empty;

        return $"{baseUrl}/uploads/{folder.Trim('/')}";
    }
}
