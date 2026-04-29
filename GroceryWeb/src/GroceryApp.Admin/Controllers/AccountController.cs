using System.Text.Json;
using GroceryApp.Admin.Models;
using Microsoft.AspNetCore.Mvc;

namespace GroceryApp.Admin.Controllers;

public class AccountController : Controller
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;

    public AccountController(IHttpClientFactory httpClientFactory, IConfiguration configuration)
    {
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
    }

    [HttpGet]
    public IActionResult Login() => View();

    [HttpPost]
    public async Task<IActionResult> Login(LoginViewModel model)
    {
        if (!ModelState.IsValid) return View(model);

        var client = _httpClientFactory.CreateClient("GroceryApi");
        var payload = new { email = model.Email, password = model.Password };
        var json = JsonSerializer.Serialize(payload);
        var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

        var response = await client.PostAsync("/api/auth/login", content);

        if (!response.IsSuccessStatusCode)
        {
            ModelState.AddModelError("", "Invalid email or password.");
            return View(model);
        }

        var responseJson = await response.Content.ReadAsStringAsync();
        var authResponse = JsonSerializer.Deserialize<AuthResponseModel>(responseJson, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

        if (authResponse?.Token is null || authResponse.User?.Roles?.Contains("Admin") != true)
        {
            ModelState.AddModelError("", "Access denied. Admin role required.");
            return View(model);
        }

        HttpContext.Session.SetString("JwtToken", authResponse.Token);
        HttpContext.Session.SetString("UserName", $"{authResponse.User.FirstName} {authResponse.User.LastName}");

        return RedirectToAction("Index", "Dashboard");
    }

    public IActionResult Logout()
    {
        HttpContext.Session.Clear();
        return RedirectToAction("Login");
    }
}
