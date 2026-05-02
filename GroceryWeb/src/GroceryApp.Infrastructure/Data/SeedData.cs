using GroceryApp.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace GroceryApp.Infrastructure.Data;

public static class SeedData
{
    public static async Task InitializeAsync(IServiceProvider serviceProvider)
    {
        using var scope = serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole<Guid>>>();

        await context.Database.MigrateAsync();

        // Seed roles
        string[] roles = ["Admin", "Staff", "StoreOwner", "Rider", "Customer"];
        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new IdentityRole<Guid> { Name = role, NormalizedName = role.ToUpper() });
            }
        }

        // Seed admin user
        if (await userManager.FindByEmailAsync("admin@groceryapp.com") is null)
        {
            var admin = new User
            {
                FirstName = "System",
                LastName = "Admin",
                Email = "admin@groceryapp.com",
                UserName = "admin@groceryapp.com",
                EmailConfirmed = true
            };
            await userManager.CreateAsync(admin, "Admin@123!");
            await userManager.AddToRoleAsync(admin, "Admin");
        }

        // Seed categories
        if (!await context.Categories.AnyAsync())
        {
            var categories = new List<Category>
            {
                new() { Name = "Fruits & Vegetables", Description = "Fresh produce", ImageUrl = "/images/categories/fruits.png" },
                new() { Name = "Dairy & Eggs", Description = "Milk, cheese, eggs and more", ImageUrl = "/images/categories/dairy.png" },
                new() { Name = "Meat & Seafood", Description = "Fresh meat and seafood", ImageUrl = "/images/categories/meat.png" },
                new() { Name = "Bakery", Description = "Bread, pastries, and baked goods", ImageUrl = "/images/categories/bakery.png" },
                new() { Name = "Beverages", Description = "Drinks and refreshments", ImageUrl = "/images/categories/beverages.png" },
                new() { Name = "Snacks", Description = "Chips, crackers, and treats", ImageUrl = "/images/categories/snacks.png" },
                new() { Name = "Pantry Staples", Description = "Rice, pasta, canned goods", ImageUrl = "/images/categories/pantry.png" },
                new() { Name = "Frozen Foods", Description = "Frozen meals and ingredients", ImageUrl = "/images/categories/frozen.png" },
                new() { Name = "Personal Care", Description = "Health and beauty products", ImageUrl = "/images/categories/personal.png" },
                new() { Name = "Household", Description = "Cleaning and home supplies", ImageUrl = "/images/categories/household.png" }
            };

            context.Categories.AddRange(categories);
            await context.SaveChangesAsync();

            // Seed products
            var fruitsCategory = categories[0];
            var dairyCategory = categories[1];
            var meatCategory = categories[2];
            var beveragesCategory = categories[4];
            var pantryCategory = categories[6];

            var products = new List<Product>
            {
                new() { Name = "Banana (per kg)", Description = "Fresh Cavendish bananas", Price = 65, StockQuantity = 200, Unit = "kg", CategoryId = fruitsCategory.Id, Images = [new ProductImage { ImageUrl = "/images/products/banana.png", IsPrimary = true, SortOrder = 0 }] },
                new() { Name = "Apple Red (per kg)", Description = "Imported red apples", Price = 180, StockQuantity = 100, Unit = "kg", CategoryId = fruitsCategory.Id, Images = [new ProductImage { ImageUrl = "/images/products/apple.png", IsPrimary = true, SortOrder = 0 }] },
                new() { Name = "Fresh Milk 1L", Description = "Full cream fresh milk", Price = 95, StockQuantity = 150, Unit = "pcs", CategoryId = dairyCategory.Id, Images = [new ProductImage { ImageUrl = "/images/products/milk.png", IsPrimary = true, SortOrder = 0 }] },
                new() { Name = "Large Eggs (12pcs)", Description = "Farm fresh eggs", Price = 120, StockQuantity = 80, Unit = "dozen", CategoryId = dairyCategory.Id, Images = [new ProductImage { ImageUrl = "/images/products/eggs.png", IsPrimary = true, SortOrder = 0 }] },
                new() { Name = "Chicken Breast (per kg)", Description = "Boneless chicken breast", Price = 220, StockQuantity = 60, Unit = "kg", CategoryId = meatCategory.Id, Images = [new ProductImage { ImageUrl = "/images/products/chicken.png", IsPrimary = true, SortOrder = 0 }] },
                new() { Name = "Pork Belly (per kg)", Description = "Fresh pork belly liempo", Price = 320, StockQuantity = 40, Unit = "kg", CategoryId = meatCategory.Id, Images = [new ProductImage { ImageUrl = "/images/products/pork.png", IsPrimary = true, SortOrder = 0 }] },
                new() { Name = "Coca-Cola 1.5L", Description = "Coca-Cola regular", Price = 75, DiscountPrice = 65, StockQuantity = 300, Unit = "bottle", CategoryId = beveragesCategory.Id, Images = [new ProductImage { ImageUrl = "/images/products/coke.png", IsPrimary = true, SortOrder = 0 }] },
                new() { Name = "Jasmine Rice 5kg", Description = "Premium Thai jasmine rice", Price = 450, StockQuantity = 50, Unit = "bag", CategoryId = pantryCategory.Id, Images = [new ProductImage { ImageUrl = "/images/products/rice.png", IsPrimary = true, SortOrder = 0 }] },
                new() { Name = "Instant Noodles (5-pack)", Description = "Lucky Me pancit canton", Price = 55, StockQuantity = 500, Unit = "pack", CategoryId = pantryCategory.Id, Images = [new ProductImage { ImageUrl = "/images/products/noodles.png", IsPrimary = true, SortOrder = 0 }] },
                new() { Name = "Bottled Water 500ml (24-pack)", Description = "Purified drinking water", Price = 180, StockQuantity = 100, Unit = "case", CategoryId = beveragesCategory.Id, Images = [new ProductImage { ImageUrl = "/images/products/water.png", IsPrimary = true, SortOrder = 0 }] }
            };

            context.Products.AddRange(products);
            await context.SaveChangesAsync();
        }

        // Seed vouchers
        if (!await context.Vouchers.AnyAsync())
        {
            var vouchers = new List<Voucher>
            {
                new() { Code = "WELCOME10", Description = "10% off for new users", Type = VoucherType.Percentage, Value = 10, MaxDiscount = 200, MinimumSpend = 500, UsageLimit = 1000, StartDate = DateTime.UtcNow, ExpiryDate = DateTime.UtcNow.AddMonths(6) },
                new() { Code = "SAVE50", Description = "₱50 off on orders ₱1000+", Type = VoucherType.FixedAmount, Value = 50, MinimumSpend = 1000, UsageLimit = 500, StartDate = DateTime.UtcNow, ExpiryDate = DateTime.UtcNow.AddMonths(3) },
                new() { Code = "FREEDELIVERY", Description = "Free delivery on any order", Type = VoucherType.FixedAmount, Value = 50, MinimumSpend = 0, UsageLimit = 200, StartDate = DateTime.UtcNow, ExpiryDate = DateTime.UtcNow.AddMonths(1) }
            };

            context.Vouchers.AddRange(vouchers);
            await context.SaveChangesAsync();
        }
    }
}
