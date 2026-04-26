# Product: TalentDesk (ClientRegistrationApp)

A SwiftUI iOS app for freelancers and recruiters to register, manage, and track client profiles. Core capabilities:

- **User onboarding**: One-time app registration (name, email, mobile) with a splash transition
- **Client registration**: Add clients with name, age, mobile, email, photo, skills (with hourly rates), and address
- **Client management**: List, search, view details, edit, and delete clients
- **Dashboard**: Home screen with static hiring/opportunity charts and job listings (placeholder data)
- **Settings**: Light/Dark/System appearance toggle, app version info

Data is persisted locally as JSON files in the Application Support directory. There is no backend, network layer, or authentication service — everything is on-device.
