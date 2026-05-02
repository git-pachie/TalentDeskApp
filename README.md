# GroceryApp

A full-stack grocery shopping platform consisting of an iOS mobile app, a REST API, and an admin panel.

---

## Projects

| Project | Technology | Description |
|---------|-----------|-------------|
| `GroceryMobileApp` | iOS 17+, Swift 5, SwiftUI | Customer-facing mobile app |
| `GroceryWeb/src/GroceryApp.API` | ASP.NET Core 9 | REST API backend |
| `GroceryWeb/src/GroceryApp.Admin` | ASP.NET Core 9 MVC | Admin management panel |
| `GroceryWeb/src/GroceryApp.Application` | .NET 9 | Business logic layer |
| `GroceryWeb/src/GroceryApp.Domain` | .NET 9 | Domain entities |
| `GroceryWeb/src/GroceryApp.Infrastructure` | .NET 9 | Data access, migrations, external services |

---

## Mobile App (GroceryMobileApp)

### Requirements
- Xcode 15+
- iOS 17.0+ deployment target
- XcodeGen (`brew install xcodegen`)

### Setup
```bash
cd GroceryMobileApp
xcodegen generate
open GroceryApp.xcodeproj
```

### Configuration
Edit `GroceryApp/APIClient.swift` and set `APIConfig.baseURL` to your API server:
```swift
// Simulator (same machine)
static let baseURL = "https://127.0.0.1:5001"

// Physical device (use your Mac's LAN IP)
static let baseURL = "http://192.168.x.x:5010"
```

### Features
- User registration and login with JWT authentication
- Email verification via 4-digit OTP
- Product browsing by category, search, and deals
- Shopping cart with per-item remarks (server-synced)
- Checkout with multiple payment methods: Apple Pay, Credit Card, Debit Card, GCash, Cash on Delivery
- Voucher application with server-side validation
- Order tracking with status timeline
- Product reviews with star rating, text remarks, and photo uploads
- Favorites management
- Delivery address management with MapKit and reverse geocoding
- PDF export and share for order invoices
- Light / Dark mode with adaptive theme
- Profile page with email and phone verification status

---

## API (GroceryApp.API)

### Requirements
- .NET 9 SDK
- SQL Server (or SQL Server Express)

### Setup

**1. Configure user secrets** (never commit credentials):
```bash
cd GroceryWeb
dotnet user-secrets init --project src/GroceryApp.API

dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=...;Database=AI_GroceryDB;..." --project src/GroceryApp.API
dotnet user-secrets set "Jwt:Key" "your-32-char-minimum-secret-key" --project src/GroceryApp.API
dotnet user-secrets set "Smtp:UserName" "your@gmail.com" --project src/GroceryApp.API
dotnet user-secrets set "Smtp:Password" "your-app-password" --project src/GroceryApp.API
dotnet user-secrets set "Smtp:FromAddress" "your@gmail.com" --project src/GroceryApp.API
```

**2. Apply database migrations:**
```bash
cd GroceryWeb
dotnet ef database update --project src/GroceryApp.Infrastructure --startup-project src/GroceryApp.API
```

**3. Run:**
```bash
dotnet run --project src/GroceryApp.API
```

API listens on:
- HTTPS: `https://0.0.0.0:5001`
- HTTP: `http://0.0.0.0:5010`

Swagger UI available at `https://localhost:5001/swagger` (Development only).

### Key Endpoints

| Method | Route | Description |
|--------|-------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login (returns JWT) |
| POST | `/api/auth/verify-email` | Verify email with 4-digit code |
| POST | `/api/auth/send-email-code` | Send new verification code (authenticated) |
| GET | `/api/auth/me` | Get current user profile |
| GET | `/api/products` | List products (paginated) |
| GET | `/api/products/search` | Search products |
| GET | `/api/categories` | List categories |
| GET/POST/PUT/DELETE | `/api/cart` | Cart management |
| POST | `/api/orders` | Place order |
| GET | `/api/orders` | Get user orders |
| GET | `/api/orders/{id}` | Get order detail |
| POST | `/api/reviews` | Submit review |
| POST | `/api/reviews/upload` | Upload review photos |
| GET | `/api/vouchers/user` | Get vouchers assigned to current user |
| POST | `/api/vouchers/apply` | Validate and apply voucher |
| GET | `/api/addresses` | Get user addresses |
| GET | `/api/payment-methods` | Get user payment methods |
| POST | `/api/payments/checkout` | Process payment |

---

## Admin Panel (GroceryApp.Admin)

### Requirements
- .NET 9 SDK
- API must be running first

### Setup

**1. Configure `appsettings.json`:**
```json
{
  "ApiBaseUrl": "http://localhost:5010"
}
```

**2. Run:**
```bash
dotnet run --project src/GroceryApp.Admin
```

Admin panel listens on:
- HTTPS: `https://0.0.0.0:5002`
- HTTP: `http://0.0.0.0:5100`

### Features
- **Dashboard** — Revenue, order counts, recent orders
- **Products** — CRUD with image uploads, categories, pricing
- **Categories** — Manage product categories
- **Orders** — List with search, date range filter, pagination (60/page default); detail with PDF export, print, email invoice
- **Users** — List with search; profile with tabbed modules:
  - Addresses (add/edit/delete, map link)
  - Orders (view history, link to detail)
  - Payment Methods (add/edit/delete)
  - Vouchers (assign/revoke)
  - Email and phone verification status (mark verified/unverified)
- **Vouchers** — Create, edit, delete; assign to specific users
- **Special Offers** — Promotional banners
- **Today Deals** — Daily featured products

---

## Database

SQL Server with 22 tables managed via EF Core migrations.

### Key Tables
| Table | Description |
|-------|-------------|
| `AspNetUsers` | Users with email/phone verification fields |
| `Products` | Products with price, discount, stock |
| `Categories` | Product categories |
| `ProductImages` | Product images with primary flag |
| `Orders` | Orders with fee breakdown (subtotal, delivery, platform, other) |
| `OrderItems` | Line items with per-item remarks |
| `CartItems` | Shopping cart with remarks |
| `Reviews` | Product reviews with rating and comment |
| `ReviewPhotos` | Review photo uploads |
| `Vouchers` | Discount vouchers (percentage or fixed) |
| `UserVouchers` | Admin-assigned vouchers per user |
| `UserDevices` | Device tracking (GUID, OS, hardware) |
| `Payments` | Payment records with external transaction IDs |
| `Addresses` | Delivery addresses with lat/lng |

### Run Migrations
```bash
cd GroceryWeb
dotnet ef database update --project src/GroceryApp.Infrastructure --startup-project src/GroceryApp.API
```

### Create New Migration
```bash
dotnet ef migrations add MigrationName --project src/GroceryApp.Infrastructure --startup-project src/GroceryApp.API
```

---

## Build & Publish

### Build all
```bash
cd GroceryWeb
dotnet build GroceryApp.sln
```

### Publish for Windows (IIS)
```bash
cd GroceryWeb
DATE=$(date +%Y-%m-%d)
dotnet publish src/GroceryApp.API -c Release -r win-x64 --self-contained false -o publish/api
dotnet publish src/GroceryApp.Admin -c Release -r win-x64 --self-contained false -o publish/admin
cd publish
zip -r "GroceryApp.API-windows-${DATE}.zip" api/ -x "*.pdb"
zip -r "GroceryApp.Admin-windows-${DATE}.zip" admin/ -x "*.pdb"
```

### IIS Deployment
1. Install **.NET 9 Hosting Bundle** on the Windows server
2. Extract zip to deployment folder (e.g. `C:\inetpub\GroceryApp.API`)
3. Create IIS site pointing to the folder
4. Set Application Pool → **No Managed Code**
5. Update `appsettings.json` with production credentials

---

## Email Verification Flow

1. User registers or logs in without verified email
2. API generates a 4-digit code, stores it in DB with a 10-minute expiry, sends it via SMTP
3. User enters the code in the mobile app OTP screen
4. API validates the code, marks `IsEmailVerified = true`, clears the code, sends a confirmation email
5. JWT token issued — user is logged in

**SMTP Configuration** (via user secrets):
```bash
dotnet user-secrets set "Smtp:Host" "smtp.gmail.com" --project src/GroceryApp.API
dotnet user-secrets set "Smtp:Port" "587" --project src/GroceryApp.API
dotnet user-secrets set "Smtp:EnableSsl" "true" --project src/GroceryApp.API
dotnet user-secrets set "Smtp:UserName" "your@gmail.com" --project src/GroceryApp.API
dotnet user-secrets set "Smtp:Password" "your-app-password" --project src/GroceryApp.API
```

For Gmail, use an **App Password** (Google Account → Security → 2-Step Verification → App passwords).

If SMTP is not configured, the verification code is logged to the API console for development testing.

---

## Architecture

```
GroceryMobileApp (iOS)
        │
        │ HTTP/HTTPS (JWT)
        ▼
GroceryApp.API (ASP.NET Core 9)
        │
        ├── GroceryApp.Application (Services, DTOs, Interfaces)
        │           │
        │           └── GroceryApp.Domain (Entities, Enums)
        │
        └── GroceryApp.Infrastructure (EF Core, Repositories, Email, SMS, Payments)
                    │
                    └── SQL Server

GroceryApp.Admin (ASP.NET Core MVC)
        │
        │ HTTP (ApiClient → JWT)
        ▼
GroceryApp.API
```

---

## Secrets Management

All sensitive values are stored in **.NET User Secrets** (Development) and should be stored in environment variables or a secrets manager (Azure Key Vault, AWS Secrets Manager) in Production.

The `appsettings.json` files contain only `REPLACE_VIA_USER_SECRETS` placeholders for sensitive fields.

---

## License

Private — All rights reserved.
