# Tech Stack & Build

## Platform
- iOS 17.0+ (iPhone and iPad)
- Swift 5 with SwiftUI
- Xcode project generated via XcodeGen (`project.yml`)

## Frameworks
- **SwiftUI** — all UI, navigation, forms, sheets
- **Observation** (`@Observable`) — state management (not Combine, not ObservableObject)
- **Charts** — Swift Charts for dashboard visualizations
- **PhotosUI** — `PhotosPicker` for client photo selection
- **Foundation** — `JSONEncoder`/`JSONDecoder` for local persistence, `FileManager` for storage

## Key Patterns
- `@Observable` classes for stores (`ClientStore`, `AppSessionStore`, `AppSettingsStore`)
- `@Bindable` for passing observable stores into views
- `@Environment` for injecting shared stores (e.g., `AppSettingsStore`)
- `@State` for local view state and draft copies of models
- No third-party dependencies — pure Apple SDK

## Build & Run
```bash
# Regenerate Xcode project from project.yml (requires xcodegen)
cd TalentDesk
xcodegen generate

# Open in Xcode
open ClientRegistrationApp.xcodeproj
```

There are no test targets, linting tools, or CI pipelines configured. The project has no Swift Package Manager dependencies.

## Bundle Info
- Bundle ID: `com.example.ClientRegistrationApp`
- Version: 1.0 (build 1)
