using GroceryApp.Application.Interfaces;
using GroceryApp.Application.Services;
using Microsoft.Extensions.DependencyInjection;

namespace GroceryApp.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IProductService, ProductService>();
        services.AddScoped<ICategoryService, CategoryService>();
        services.AddScoped<ICartService, CartService>();
        services.AddScoped<IOrderService, OrderService>();
        services.AddScoped<IPaymentService, PaymentService>();
        services.AddScoped<IAddressService, AddressService>();
        services.AddScoped<IVoucherService, VoucherService>();
        services.AddScoped<IReviewService, ReviewService>();
        services.AddScoped<IFavoriteService, FavoriteService>();
        services.AddScoped<INotificationService, NotificationService>();

        return services;
    }
}
