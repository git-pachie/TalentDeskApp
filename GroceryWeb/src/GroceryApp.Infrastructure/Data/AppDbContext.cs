using GroceryApp.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace GroceryApp.Infrastructure.Data;

public class AppDbContext : IdentityDbContext<User, IdentityRole<Guid>, Guid>
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Product> Products => Set<Product>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<ProductCategory> ProductCategories => Set<ProductCategory>();
    public DbSet<ProductImage> ProductImages => Set<ProductImage>();
    public DbSet<CartItem> CartItems => Set<CartItem>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<Address> Addresses => Set<Address>();
    public DbSet<Voucher> Vouchers => Set<Voucher>();
    public DbSet<Favorite> Favorites => Set<Favorite>();
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<ReviewPhoto> ReviewPhotos => Set<ReviewPhoto>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<UserPaymentMethod> UserPaymentMethods => Set<UserPaymentMethod>();
    public DbSet<OrderStatusHistory> OrderStatusHistory => Set<OrderStatusHistory>();
    public DbSet<UserSetting> UserSettings => Set<UserSetting>();
    public DbSet<UserVoucher> UserVouchers => Set<UserVoucher>();
    public DbSet<UserDevice> UserDevices => Set<UserDevice>();
    public DbSet<SpecialOffer> SpecialOffers => Set<SpecialOffer>();
    public DbSet<TodayDeal> TodayDeals => Set<TodayDeal>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // User
        builder.Entity<User>(e =>
        {
            e.Property(u => u.FirstName).HasMaxLength(100);
            e.Property(u => u.LastName).HasMaxLength(100);
        });

        // UserDevice
        builder.Entity<UserDevice>(e =>
        {
            e.HasIndex(d => d.DeviceGuid).IsUnique();
            e.HasIndex(d => d.Email);
            e.Property(d => d.Email).HasMaxLength(256);
            e.Property(d => d.DeviceGuid).HasMaxLength(100);
            e.Property(d => d.OSVersion).HasMaxLength(100);
            e.Property(d => d.HardwareVersion).HasMaxLength(100);
            e.HasOne(d => d.User).WithMany(u => u.Devices).HasForeignKey(d => d.UserId).OnDelete(DeleteBehavior.SetNull);
        });

        // Category
        builder.Entity<Category>(e =>
        {
            e.HasIndex(c => c.Name).IsUnique();
            e.Property(c => c.Name).HasMaxLength(200);
        });

        // Product
        builder.Entity<Product>(e =>
        {
            e.HasIndex(p => p.Name);
            e.HasIndex(p => p.CategoryId);
            e.HasIndex(p => p.OwnerUserId);
            e.Property(p => p.Price).HasPrecision(18, 2);
            e.Property(p => p.DiscountPrice).HasPrecision(18, 2);
            e.HasOne(p => p.Category).WithMany(c => c.Products).HasForeignKey(p => p.CategoryId);
            e.HasOne(p => p.OwnerUser).WithMany().HasForeignKey(p => p.OwnerUserId).OnDelete(DeleteBehavior.SetNull);
        });

        // ProductImage
        builder.Entity<ProductImage>(e =>
        {
            e.Property(pi => pi.DateCreated).HasDefaultValueSql("GETUTCDATE()");
            e.Property(pi => pi.DateModified).HasDefaultValueSql("GETUTCDATE()");
            e.HasOne(pi => pi.Product).WithMany(p => p.Images).HasForeignKey(pi => pi.ProductId).OnDelete(DeleteBehavior.Cascade);
        });

        // ProductCategory (many-to-many junction)
        builder.Entity<ProductCategory>(e =>
        {
            e.HasIndex(pc => new { pc.ProductId, pc.CategoryId }).IsUnique();
            e.HasOne(pc => pc.Product).WithMany(p => p.ProductCategories).HasForeignKey(pc => pc.ProductId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(pc => pc.Category).WithMany(c => c.ProductCategories).HasForeignKey(pc => pc.CategoryId).OnDelete(DeleteBehavior.NoAction);
        });

        // CartItem
        builder.Entity<CartItem>(e =>
        {
            e.HasIndex(c => new { c.UserId, c.ProductId }).IsUnique();
            e.HasOne(c => c.User).WithMany(u => u.CartItems).HasForeignKey(c => c.UserId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(c => c.Product).WithMany().HasForeignKey(c => c.ProductId);
        });

        // Order
        builder.Entity<Order>(e =>
        {
            e.HasIndex(o => o.OrderNumber).IsUnique();
            e.HasIndex(o => o.UserId);
            e.Property(o => o.SubTotal).HasPrecision(18, 2);
            e.Property(o => o.DiscountAmount).HasPrecision(18, 2);
            e.Property(o => o.DeliveryFee).HasPrecision(18, 2);
            e.Property(o => o.PlatformFee).HasPrecision(18, 2);
            e.Property(o => o.OtherCharges).HasPrecision(18, 2);
            e.Property(o => o.TotalAmount).HasPrecision(18, 2);
            e.HasOne(o => o.User).WithMany(u => u.Orders).HasForeignKey(o => o.UserId).OnDelete(DeleteBehavior.NoAction);
            e.HasOne(o => o.Address).WithMany().HasForeignKey(o => o.AddressId).OnDelete(DeleteBehavior.SetNull);
            e.HasOne(o => o.Voucher).WithMany().HasForeignKey(o => o.VoucherId).OnDelete(DeleteBehavior.SetNull);
        });

        // OrderItem
        builder.Entity<OrderItem>(e =>
        {
            e.Property(oi => oi.UnitPrice).HasPrecision(18, 2);
            e.Property(oi => oi.TotalPrice).HasPrecision(18, 2);
            e.HasOne(oi => oi.Order).WithMany(o => o.Items).HasForeignKey(oi => oi.OrderId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(oi => oi.Product).WithMany().HasForeignKey(oi => oi.ProductId);
        });

        // Payment
        builder.Entity<Payment>(e =>
        {
            e.HasIndex(p => p.OrderId).IsUnique();
            e.HasIndex(p => p.ExternalTransactionId);
            e.Property(p => p.Amount).HasPrecision(18, 2);
            e.HasOne(p => p.Order).WithOne(o => o.Payment).HasForeignKey<Payment>(p => p.OrderId);
            e.HasOne(p => p.User).WithMany().HasForeignKey(p => p.UserId).OnDelete(DeleteBehavior.NoAction);
        });

        // Address
        builder.Entity<Address>(e =>
        {
            e.HasIndex(a => a.UserId);
            e.HasOne(a => a.User).WithMany(u => u.Addresses).HasForeignKey(a => a.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        // Voucher
        builder.Entity<Voucher>(e =>
        {
            e.HasIndex(v => v.Code).IsUnique();
            e.Property(v => v.Value).HasPrecision(18, 2);
            e.Property(v => v.MaxDiscount).HasPrecision(18, 2);
            e.Property(v => v.MinimumSpend).HasPrecision(18, 2);
        });

        // Favorite
        builder.Entity<Favorite>(e =>
        {
            e.HasIndex(f => new { f.UserId, f.ProductId }).IsUnique();
            e.HasOne(f => f.User).WithMany(u => u.Favorites).HasForeignKey(f => f.UserId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(f => f.Product).WithMany(p => p.Favorites).HasForeignKey(f => f.ProductId).OnDelete(DeleteBehavior.Cascade);
        });

        // Review
        builder.Entity<Review>(e =>
        {
            e.HasIndex(r => new { r.UserId, r.ProductId, r.OrderId }).IsUnique();
            e.HasOne(r => r.User).WithMany(u => u.Reviews).HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(r => r.Product).WithMany(p => p.Reviews).HasForeignKey(r => r.ProductId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(r => r.Order).WithMany().HasForeignKey(r => r.OrderId).OnDelete(DeleteBehavior.NoAction);
        });

        // Notification
        builder.Entity<Notification>(e =>
        {
            e.HasIndex(n => new { n.UserId, n.CreatedAt });
            e.HasOne(n => n.User).WithMany(u => u.Notifications).HasForeignKey(n => n.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        // ReviewPhoto
        builder.Entity<ReviewPhoto>(e =>
        {
            e.HasIndex(rp => rp.ReviewId);
            e.HasOne(rp => rp.Review).WithMany(r => r.Photos).HasForeignKey(rp => rp.ReviewId).OnDelete(DeleteBehavior.Cascade);
        });

        // UserPaymentMethod
        builder.Entity<UserPaymentMethod>(e =>
        {
            e.HasIndex(pm => pm.UserId);
            e.HasOne(pm => pm.User).WithMany(u => u.PaymentMethods).HasForeignKey(pm => pm.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        // OrderStatusHistory
        builder.Entity<OrderStatusHistory>(e =>
        {
            e.HasIndex(h => h.OrderId);
            e.HasOne(h => h.Order).WithMany(o => o.StatusHistory).HasForeignKey(h => h.OrderId).OnDelete(DeleteBehavior.Cascade);
        });

        // UserSetting
        builder.Entity<UserSetting>(e =>
        {
            e.HasIndex(s => new { s.UserId, s.SettingKey }).IsUnique();
            e.HasOne(s => s.User).WithMany(u => u.Settings).HasForeignKey(s => s.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        // UserVoucher
        builder.Entity<UserVoucher>(e =>
        {
            e.HasIndex(uv => new { uv.UserId, uv.VoucherId }).IsUnique();
            e.HasOne(uv => uv.User).WithMany(u => u.UserVouchers).HasForeignKey(uv => uv.UserId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(uv => uv.Voucher).WithMany(v => v.UserVouchers).HasForeignKey(uv => uv.VoucherId).OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<SpecialOffer>(e =>
        {
            e.Property(o => o.Title).HasMaxLength(200);
            e.Property(o => o.Subtitle).HasMaxLength(500);
            e.Property(o => o.Emoji).HasMaxLength(50);
            e.Property(o => o.ImageUrl).HasMaxLength(500);
            e.Property(o => o.BackgroundColorHex).HasMaxLength(20);
            e.HasIndex(o => new { o.IsActive, o.SortOrder });
            e.HasIndex(o => o.OwnerUserId);
            e.HasOne(o => o.OwnerUser).WithMany().HasForeignKey(o => o.OwnerUserId).OnDelete(DeleteBehavior.SetNull);
            e.HasOne(o => o.Category).WithMany().HasForeignKey(o => o.CategoryId).OnDelete(DeleteBehavior.SetNull);
        });

        builder.Entity<TodayDeal>(e =>
        {
            e.HasIndex(d => new { d.IsActive, d.SortOrder });
            e.HasIndex(d => d.ProductId).IsUnique();
            e.HasIndex(d => d.OwnerUserId);
            e.HasOne(d => d.Product).WithMany().HasForeignKey(d => d.ProductId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(d => d.OwnerUser).WithMany().HasForeignKey(d => d.OwnerUserId).OnDelete(DeleteBehavior.SetNull);
        });
    }
}
