# Agrilink Digital Marketplace

A hyperlocal marketplace connecting verified farmers in Agusan del Sur with local buyers.

## 🌾 About Agrilink

Agrilink is a Flutter mobile application that enables:
- **Farmers** to sell fresh agricultural products directly to local buyers
- **Buyers** to discover and purchase fresh, local produce
- **Admins** to manage verifications and moderate the platform

## ✅ Implementation Progress

### Core Infrastructure ✅
- [x] Project setup with Flutter & Supabase
- [x] Material Design green theme
- [x] Go Router navigation with 38+ routes
- [x] Data models for all entities
- [x] Supabase service integration
- [x] Custom UI components (buttons, text fields)

### Authentication System ✅
- [x] Splash screen with app branding
- [x] Onboarding flow (4 screens)
- [x] Login screen
- [x] Role-based signup (buyer/farmer)
- [x] Address setup (Agusan del Sur municipalities)
- [x] Authentication service with role management

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.9.2+)
- Supabase account

### Installation

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Configure Supabase**
   - Update `lib/core/services/supabase_service.dart` with your Supabase URL and keys
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 📱 App Structure

```
lib/
├── core/                    # Core app functionality
│   ├── models/             # Data models
│   ├── router/             # Navigation setup
│   ├── services/           # API and business logic
│   └── theme/              # App theming
├── features/               # Feature modules
│   ├── auth/              # Authentication
│   ├── buyer/             # Buyer interface
│   ├── farmer/            # Farmer interface
│   ├── chat/              # Real-time chat
│   ├── feedback/          # Feedback & reports
│   └── admin/             # Admin panel
└── shared/                # Shared components
    └── widgets/           # Reusable UI components
```

## 🎨 Design Language

- **Primary Colors**: Material Design Green (#4CAF50)
- **Typography**: Clean, readable fonts
- **Components**: Rounded cards, soft shadows
- **Layout**: Mobile-first, intuitive navigation

## 🔧 Key Technologies

- **Frontend**: Flutter 3.9.2+
- **Backend**: Supabase (Auth, Database, Storage, Realtime)
- **State Management**: Provider
- **Routing**: Go Router
- **UI**: Material Design 3

---

**Status**: Foundation Complete ✅  
**Next Phase**: Continue implementation...
