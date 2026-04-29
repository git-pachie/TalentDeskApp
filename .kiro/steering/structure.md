# Project Structure

```
.
├── .kiro/steering/              # Steering rules for AI assistant
├── .gitignore
│
├── TalentDesk/                  # iOS client registration app
│   ├── project.yml              # XcodeGen config
│   ├── README.md
│   └── ClientRegistrationApp/
│       ├── ClientRegistrationApp.swift    # @main entry point
│       ├── AppDelegate.swift              # Push notifications + global appearance
│       ├── PushNotificationManager.swift  # APNs token management
│       ├── AppFlowView.swift              # Root: registration → splash → main
│       ├── AppSession.swift               # Session store + user profile
│       ├── AppTheme.swift                 # Adaptive colors, buttons, cards, headers
│       ├── RootTabView.swift              # Tab bar (Home, Add, Clients, Settings)
│       ├── HomeDashboardView.swift        # Charts + jobs dashboard
│       ├── RegistrationView.swift         # Add client form
│       ├── ClientListView.swift           # Searchable client list
│       ├── ClientDetailView.swift         # Client detail with edit/delete
│       ├── ClientEditView.swift           # Full-page edit
│       ├── ClientEditSheet.swift          # Sheet-based edit
│       ├── ClientAddressSheet.swift       # Address editor sheet
│       ├── ClientSkillsSheet.swift        # Skills list sheet
│       ├── ClientSkillEditorSheet.swift   # Single skill editor
│       ├── ClientPhotoView.swift          # Circular photo display
│       ├── ClientPhotoPickerSection.swift # Photo picker component
│       ├── ClientRegistration.swift       # Models + ClientStore
│       ├── SettingsView.swift             # Appearance + push + about
│       ├── AppRegistrationView.swift      # Onboarding registration
│       └── AppSplashView.swift            # Post-registration splash
│
├── TalentDeskAPI/               # .NET 9 Web API for APNs
│   ├── Program.cs               # DI + pipeline setup
│   ├── TalentDeskAPI.csproj
│   ├── appsettings.json         # APNs config (KeyId, TeamId, BundleId)
│   ├── Configuration/
│   │   └── ApnsSettings.cs      # APNs settings model
│   ├── Controllers/
│   │   └── PushNotificationController.cs
│   ├── Models/
│   │   └── ApnsModels.cs        # Request/response DTOs
│   └── Services/
│       ├── ApnsService.cs       # HTTP/2 push sender
│       └── ApnsTokenService.cs  # JWT token generator + cache
│
├── GroceryMobileApp/            # iOS grocery shopping app
│   ├── project.yml              # XcodeGen config
│   ├── Database/
│   │   ├── GroceryApp_Schema.sql    # SQL Server schema (16 tables)
│   │   └── GroceryApp_DFD.md        # Data flow diagrams (Mermaid)
│   └── GroceryApp/
│       ├── GroceryApp.swift         # @main + theme root
│       ├── GroceryTheme.swift       # Adaptive colors (light/dark)
│       ├── GroceryModels.swift      # Product, Category, SampleData
│       ├── GrocerySettingsStore.swift # Appearance settings
│       ├── CartStore.swift          # Cart state management
│       ├── FavoritesStore.swift     # Favorites state management
│       ├── CachedAsyncImage.swift   # URLCache-backed image loader
│       ├── PreviewHelpers.swift     # .groceryPreviewEnvironment()
│       ├── GroceryIconView.swift    # App icon component
│       ├── RootTabView.swift        # Tabs: Home, Cart, Favorites, Profile
│       ├── HomeView.swift           # Delivery header, banners, categories, deals
│       ├── SearchView.swift         # Search with results + suggestions
│       ├── FreshProductsView.swift  # Product grid + ProductCard component
│       ├── ItemDetailView.swift     # Product detail with gallery
│       ├── CartView.swift           # Cart with remarks + checkout
│       ├── CheckoutView.swift       # Full checkout flow + success animation
│       ├── ApplePayService.swift    # Apple Pay request builder
│       ├── ApplePayButton.swift     # PKPaymentButton + coordinator
│       ├── GCashPaymentView.swift   # GCash payment sheet
│       ├── CardPaymentView.swift    # Credit/Debit card payment
│       ├── OrdersView.swift         # Current + history tabs
│       ├── OrderDetailView.swift    # Order detail + review + PDF export
│       ├── FavoritesView.swift      # Favorited products grid
│       ├── ProfileView.swift        # Account + appearance settings
│       ├── AddressListView.swift    # Addresses with map + edit
│       ├── PaymentMethodsView.swift # Payment methods CRUD
│       ├── VouchersView.swift       # Voucher list
│       ├── VoucherDetailView.swift  # Voucher detail + terms
│       └── ShareSheet.swift         # UIActivityViewController wrapper
│
├── GroceryWeb/                  # ASP.NET Core 9 web solution
│   ├── GroceryApp.sln
│   └── src/
│       ├── GroceryApp.API/          # REST API
│       ├── GroceryApp.Admin/        # MVC admin panel
│       ├── GroceryApp.Application/  # Business logic
│       ├── GroceryApp.Domain/       # Domain entities
│       └── GroceryApp.Infrastructure/ # Data access
│
└── TestMobileApp/               # Test/scratch project
```

## Conventions
- Models and stores live in the same file (e.g., CartStore.swift has CartItem + CartStore)
- Views are one-per-file, named after the screen
- Sheets suffixed with `Sheet` or `View` (e.g., ClientEditSheet, GCashPaymentView)
- All views include `#Preview` blocks using `.groceryPreviewEnvironment()`
- Edit flows use draft-copy pattern: `@State private var draft` initialized from original
- `.buttonStyle(.plain)` on buttons inside List rows to prevent multi-fire
- Adaptive colors use `UIColor { traits in ... }` dynamic providers
