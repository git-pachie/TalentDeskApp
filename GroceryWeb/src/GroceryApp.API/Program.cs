using GroceryApp.Application;
using GroceryApp.Application.Security;
using GroceryApp.Infrastructure;
using GroceryApp.Infrastructure.Data;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Add layers
builder.Services.AddApplicationServices();
builder.Services.AddInfrastructureServices(builder.Configuration);

// JWT Authentication
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = JwtSigningKey.Create(builder.Configuration)
    };
});

builder.Services.AddAuthorization();
builder.Services.AddControllers();

// Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "GroceryApp API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme.",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

var swaggerEnabled = app.Configuration.GetValue("Swagger:Enabled", true);

// Seed data
await SeedData.InitializeAsync(app.Services);

// Ensure upload directories exist
var uploadPath = app.Configuration["Storage:UploadPath"] ?? "wwwroot/uploads";
if (!Path.IsPathRooted(uploadPath))
    uploadPath = Path.Combine(app.Environment.ContentRootPath, uploadPath);
Directory.CreateDirectory(Path.Combine(uploadPath, "products"));
Directory.CreateDirectory(Path.Combine(uploadPath, "riders"));

if (swaggerEnabled)
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Only redirect to HTTPS in production — dev devices use plain HTTP
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}
app.UseStaticFiles(); // Serve wwwroot

// Serve uploaded files from configurable path
var storagePath = app.Configuration["Storage:UploadPath"] ?? "wwwroot/uploads";
if (!Path.IsPathRooted(storagePath))
    storagePath = Path.Combine(app.Environment.ContentRootPath, storagePath);
var urlPrefix = app.Configuration["Storage:UrlPrefix"] ?? "/uploads";

if (!storagePath.Contains("wwwroot"))
{
    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(storagePath),
        RequestPath = urlPrefix
    });
}

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();
