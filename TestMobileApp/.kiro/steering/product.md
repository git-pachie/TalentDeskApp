# Product Overview

ClientRegistrationApp (branded "Talent Desk") is an iOS app for freelance/contractor talent management.

## Core Functionality
- **App onboarding**: One-time user registration (name, email, mobile) with a splash/welcome screen before entering the main app
- **Client registration**: Add clients with name, last name, age, mobile, email, optional photo
- **Client management**: List, search, view details, edit, and delete clients
- **Skills tracking**: Each client can have multiple skills with optional hourly rates
- **Address management**: Optional address per client
- **Home dashboard**: Static overview with hiring trends (bar chart), opportunity trends (line chart), job listings, and summary stats

## Data Persistence
- All data is stored locally as JSON files in the app's Application Support directory
- No backend, no network calls, no authentication beyond the initial app registration
- Two storage files: `app-user.json` (app user profile) and `clients.json` (client records)
