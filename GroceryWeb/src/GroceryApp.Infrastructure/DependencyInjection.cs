using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using GroceryApp.Infrastructure.Data;
using GroceryApp.Infrastructure.Payments;
using GroceryApp.Infrastructure.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace GroceryApp.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructureServices(this IServiceCollection services, IConfiguration configuration)
    {
        // Database
        services.AddDbContext<AppDbContext>(options =>
            options.UseSqlServer(
                configuration.GetConnectionString("DefaultConnection"),
                b => b.MigrationsAssembly(typeof(AppDbContext).Assembly.FullName)));

        // Identity
        services.AddIdentity<User, IdentityRole<Guid>>(options =>
        {
            options.Password.RequireDigit = true;
            options.Password.RequireLowercase = true;
            options.Password.RequireUppercase = true;
            options.Password.RequireNonAlphanumeric = true;
            options.Password.RequiredLength = 8;
            options.User.RequireUniqueEmail = true;
        })
        .AddEntityFrameworkStores<AppDbContext>()
        .AddDefaultTokenProviders();

        // Repository & UoW
        services.AddScoped(typeof(IRepository<>), typeof(Repository<>));
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        // Payment providers (Strategy pattern)
        services.AddScoped<IPaymentProvider, StripePaymentProvider>();
        services.AddScoped<IPaymentProvider, CODPaymentProvider>();
        services.AddHttpClient<IPaymentProvider, GCashPaymentProvider>();
        services.AddHttpClient<IPaymentProvider, PayMayaPaymentProvider>();

        // External services
        services.AddHttpClient<IGeocodingService, GoogleGeocodingService>();
        services.AddScoped<IEmailService, EmailService>();
        services.AddScoped<ISmsService, FileSmsService>();
        services.AddScoped<IUserDeviceService, UserDeviceService>();

        return services;
    }
}
