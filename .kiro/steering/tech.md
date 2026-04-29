# Tech Stack & Build

## TalentDesk (iOS)
- iOS 17.0+, Swift 5, SwiftUI
- XcodeGen (`project.yml`) for project generation
- `@Observable` for state management (not Combine)
- Swift Charts, PhotosUI, UserNotifications
- Bundle ID: `com.sanshare.talentdesk`
- APNs push notifications with AppDelegate

```bash
cd TalentDesk && xcodegen generate && open ClientRegistrationApp.xcodeproj
```

## TalentDeskAPI (.NET 9)
- .NET 9 Web API with controllers
- System.IdentityModel.Tokens.Jwt for APNs JWT auth
- HTTP/2 for APNs communication
- Runs on http://localhost:5270 or https://localhost:7150

```bash
cd TalentDeskAPI && dotnet run
```

## GroceryMobileApp (iOS)
- iOS 17.0+, Swift 5, SwiftUI
- XcodeGen (`project.yml`) for project generation
- `@Observable` stores: CartStore, FavoritesStore, GrocerySettingsStore
- MapKit for address pinning with reverse geocoding
- PassKit for Apple Pay integration
- AsyncImage + custom CachedAsyncImage for product photos
- PhotosUI for review photo uploads
- UIGraphicsPDFRenderer for order PDF export
- Bundle ID: `com.sanshare.GroceryApp`

```bash
cd GroceryMobileApp && xcodegen generate && open GroceryApp.xcodeproj
```

## GroceryWeb (ASP.NET Core 9)
- Layered architecture: API, Admin (MVC), Application, Domain, Infrastructure
- Solution file: `GroceryWeb/GroceryApp.sln`

```bash
cd GroceryWeb && dotnet build GroceryApp.sln
```

## Database
- SQL Server schema at `GroceryMobileApp/Database/GroceryApp_Schema.sql`
- DFD diagrams at `GroceryMobileApp/Database/GroceryApp_DFD.md` (Mermaid)
- 16 tables with UUIDs, DateCreated/CreatedBy audit fields, check constraints, indexes

## Common Patterns
- `@Observable` classes for stores, `@Bindable` for view bindings, `@Environment` for injection
- `@State` for local view state and draft copies
- `.buttonStyle(.plain)` required for buttons inside List rows
- All views include `#Preview` blocks with `.groceryPreviewEnvironment()` helper
- No third-party dependencies — pure Apple SDK + .NET SDK
