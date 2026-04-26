# TalentDesk

A SwiftUI iOS app for freelancers and recruiters to register, manage, and track client profiles — all on-device with no backend required.

## Features

- **Onboarding** — One-time user registration with a polished splash transition
- **Client Registration** — Add clients with name, age, mobile, email, photo, skills (with hourly rates), and address
- **Client Management** — Search, view details, edit, and swipe-to-delete
- **Dashboard** — Home screen with hiring activity charts, opportunity trends, and job listings
- **Settings** — Light / Dark / System appearance toggle and app info

## Screenshots

_Coming soon_

## Requirements

- iOS 17.0+
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for project generation)

## Getting Started

```bash
# Clone the repo
git clone https://github.com/git-pachie/TalentDeskApp.git
cd TalentDeskApp/TalentDesk

# Generate the Xcode project
xcodegen generate

# Open in Xcode
open ClientRegistrationApp.xcodeproj
```

Build and run on a simulator or device from Xcode.

## Tech Stack

- **SwiftUI** — UI, navigation, forms, sheets
- **Observation** (`@Observable`) — State management
- **Swift Charts** — Dashboard visualizations
- **PhotosUI** — Client photo picker
- **Foundation** — JSON persistence via `FileManager`

No third-party dependencies.

## Project Structure

All source files live flat under `TalentDesk/ClientRegistrationApp/`:

| Area | Key Files |
|---|---|
| App entry | `ClientRegistrationApp.swift`, `AppFlowView.swift` |
| Onboarding | `AppRegistrationView.swift`, `AppSplashView.swift`, `AppSession.swift` |
| Main tabs | `RootTabView.swift`, `HomeDashboardView.swift`, `SettingsView.swift` |
| Client CRUD | `ClientRegistration.swift`, `RegistrationView.swift`, `ClientListView.swift`, `ClientDetailView.swift`, `ClientEditView.swift` |
| Sheets | `ClientAddressSheet.swift`, `ClientSkillsSheet.swift`, `ClientSkillEditorSheet.swift` |
| Components | `ClientPhotoView.swift`, `ClientPhotoPickerSection.swift`, `AppTheme.swift` |

## License

This project is provided as-is for educational and personal use.
