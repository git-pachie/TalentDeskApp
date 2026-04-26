# Project Structure

```
ClientRegistrationApp/
├── ClientRegistrationApp.swift      # @main app entry point, creates root stores
├── AppFlowView.swift                # Top-level router: switches on AppLaunchStage
│
│── App Onboarding
│   ├── AppRegistrationView.swift    # First-run user registration form
│   ├── AppSplashView.swift          # Post-registration welcome/splash screen
│   └── AppSession.swift             # AppUserProfile model + AppSessionStore (launch flow state)
│
│── Main App (post-onboarding)
│   ├── RootTabView.swift            # TabView with Home, Add Client, Clients tabs
│   ├── HomeDashboardView.swift      # Dashboard with charts and job listings
│   ├── RegistrationView.swift       # New client registration form
│   ├── ClientListView.swift         # Searchable list of all clients
│   ├── ClientDetailView.swift       # Read-only client detail with skills/address sections
│   └── ClientEditView.swift         # Edit form for existing client
│
│── Sheets (presented modally)
│   ├── ClientAddressSheet.swift     # Edit client address
│   ├── ClientSkillsSheet.swift      # Manage client skills list
│   └── ClientSkillEditorSheet.swift # Add/edit a single skill
│
│── Reusable Components
│   ├── ClientPhotoView.swift        # Displays client photo or placeholder
│   └── ClientPhotoPickerSection.swift # Photo picker form section
│
│── Theming
│   └── AppTheme.swift               # Colors, backgrounds, button styles, input styles
│
│── Data Models (in their respective files)
│   ├── ClientRegistration.swift     # ClientRegistration, ClientSkill models + ClientStore
│   └── AppSession.swift             # AppUserProfile model + AppSessionStore
│
├── Info.plist
├── Resources/
│   └── Assets.xcassets/             # App icon, accent color
└── Preview Content/
    └── Preview Assets.xcassets/
```

## Architecture Notes
- **Flat file structure** — all Swift files live directly in `ClientRegistrationApp/`, no subdirectories for source code
- **Two `@Observable` stores** created at the app root and passed down via parameters:
  - `AppSessionStore` — manages onboarding flow and app user profile
  - `ClientStore` — manages the list of registered clients
- **Navigation**: `AppFlowView` acts as a top-level router using a `switch` on `AppLaunchStage`. Inside the main app, `NavigationStack` is used per tab.
- **Sheet pattern**: Modal editors take a `clientStore` + `client` copy, mutate a `@State` draft, then call `clientStore.update()` on save
- **Previews**: Every view includes a `#Preview` block with sample data
