# Tech Stack

## Language & Frameworks
- **Swift 5** with **SwiftUI** (declarative UI)
- **iOS 17.0** minimum deployment target
- **Observation** framework (`@Observable` macro) for state management — not Combine's `ObservableObject`
- **Swift Charts** for dashboard visualizations
- **PhotosUI** (`PhotosPicker`) for image selection

## Build System
- **XcodeGen** generates the Xcode project from `project.yml`
- **Xcode** for building and running (no SPM dependencies, no CocoaPods, no third-party libraries)
- Bundle ID: `com.example.ClientRegistrationApp`
- Targets: iPhone and iPad (`TARGETED_DEVICE_FAMILY: 1,2`)

## Common Commands
```bash
# Regenerate Xcode project from project.yml
xcodegen generate

# Build from command line
xcodebuild -project ClientRegistrationApp.xcodeproj -scheme ClientRegistrationApp -sdk iphonesimulator build

# Open in Xcode
open ClientRegistrationApp.xcodeproj
```

## Key Conventions
- No third-party dependencies — use only Apple frameworks
- State management uses `@Observable` classes (Swift Observation), not `ObservableObject`/`@Published`
- Views accept stores via `@Bindable var` parameters, not `@EnvironmentObject`
- Local JSON file persistence via `FileManager` + `Codable` — no Core Data, no SwiftData
- All model types conform to `Codable`, `Identifiable`, and `Equatable`
- Custom `Codable` implementations handle legacy data migration (see `ClientRegistration.init(from:)`)
