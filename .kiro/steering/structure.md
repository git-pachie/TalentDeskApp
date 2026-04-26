# Project Structure

All source code lives under `TalentDesk/ClientRegistrationApp/`. There are no subdirectories for source files — everything is flat in one folder.

```
TalentDesk/
├── project.yml                          # XcodeGen project definition
├── README.md
├── ClientRegistrationApp/
│   ├── ClientRegistrationApp.swift      # @main App entry point
│   ├── Info.plist
│   │
│   ├── # App Flow & Onboarding
│   ├── AppFlowView.swift                # Root view — switches on launch stage
│   ├── AppRegistrationView.swift        # First-run user registration
│   ├── AppSplashView.swift              # Post-registration splash screen
│   ├── AppSession.swift                 # AppSessionStore, AppUserProfile, AppLaunchStage
│   │
│   ├── # Main App
│   ├── RootTabView.swift                # Tab bar (Home, Add, Clients, Settings)
│   ├── HomeDashboardView.swift          # Dashboard with charts and job listings
│   ├── SettingsView.swift               # Appearance toggle and app info
│   │
│   ├── # Client CRUD
│   ├── ClientRegistration.swift         # ClientRegistration model, ClientSkill model, ClientStore
│   ├── RegistrationView.swift           # Add new client form
│   ├── ClientListView.swift             # Searchable client list with swipe-to-delete
│   ├── ClientDetailView.swift           # Read-only client detail with edit/skills/address actions
│   ├── ClientEditView.swift             # Edit client form (draft-and-save pattern)
│   │
│   ├── # Sheets
│   ├── ClientAddressSheet.swift         # Address editor (half-sheet)
│   ├── ClientSkillsSheet.swift          # Skills list with add/edit/delete
│   ├── ClientSkillEditorSheet.swift     # Single skill editor (half-sheet)
│   │
│   ├── # Reusable Components
│   ├── ClientPhotoView.swift            # Circular photo display
│   ├── ClientPhotoPickerSection.swift   # Photo picker form section
│   ├── AppTheme.swift                   # Colors, button styles, card modifiers, onboarding background
│   │
│   ├── Resources/Assets.xcassets/       # App icon, accent color
│   └── Preview Content/                 # Xcode preview assets
└── ClientRegistrationApp.xcodeproj/     # Generated Xcode project (do not edit manually)
```

## Conventions
- Models and their stores live in the same file (e.g., `ClientRegistration` + `ClientStore` in `ClientRegistration.swift`)
- Views are one-per-file, named after the screen or component they represent
- Sheets are suffixed with `Sheet` (e.g., `ClientAddressSheet`)
- App-level concerns are prefixed with `App` (e.g., `AppTheme`, `AppSession`, `AppFlowView`)
- All views include `#Preview` blocks at the bottom of the file
- Edit flows use a draft-copy pattern: `@State private var draftClient` initialized from the original, saved on explicit action
