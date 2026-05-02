using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace GroceryApp.Admin.Filters;

/// <summary>
/// Ensures the user has a valid JWT token stored in session.
/// Redirects to login if not authenticated.
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class AdminAuthAttribute : Attribute, IAuthorizationFilter
{
    public string[] AllowedRoles { get; }

    public AdminAuthAttribute(params string[] allowedRoles)
    {
        AllowedRoles = allowedRoles;
    }

    public void OnAuthorization(AuthorizationFilterContext context)
    {
        var token = context.HttpContext.Session.GetString("JwtToken");
        if (string.IsNullOrEmpty(token))
        {
            context.Result = new RedirectToActionResult("Login", "Account", null);
            return;
        }

        if (AllowedRoles.Length > 0)
        {
            var sessionRoles = (context.HttpContext.Session.GetString("UserRoles") ?? string.Empty)
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

            if (!sessionRoles.Any(role => AllowedRoles.Contains(role, StringComparer.OrdinalIgnoreCase)))
            {
                context.Result = new RedirectToActionResult("Index", "Dashboard", null);
            }
        }
    }
}
