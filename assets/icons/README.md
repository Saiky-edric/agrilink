# Agrilink Launcher Icons

## Tractor Icon Design

This folder contains the launcher icons for the Agrilink agricultural marketplace app.

### Icon Features:
- **Design**: Red tractor on green circular background
- **Style**: Matches the tractor animation in the splash screen
- **Colors**: 
  - Background: Agrilink Green (#2E7D32)
  - Tractor: Agricultural Red (#D32F2F)
  - Details: Realistic tractor components

### Icon Sizes Generated:
- **1024x1024**: App Store and high-resolution displays
- **512x512**: Play Store and web
- **192x192**: Android XXXHDPI
- **144x144**: Android XXHDPI  
- **96x96**: Android XHDPI
- **72x72**: Android HDPI
- **48x48**: Android MDPI

### Components Included:
- Circular green background with white border
- Red tractor body with darker red cab
- Light blue window (driver visibility)
- Black wheels with gray rims and spokes
- Gray engine grille at front
- Yellow headlight
- Small exhaust pipe

### Usage:
1. Generate icons using the script: `dart scripts/generate_launcher_icon.dart`
2. Install flutter_launcher_icons: `flutter pub get`
3. Generate launcher icons: `flutter pub run flutter_launcher_icons`
4. Build app with new icons

### Manual Generation:
If automatic generation fails, you can manually create a 1024x1024 PNG icon with:
- Green circular background (#2E7D32)
- White border (2% width)
- Centered red tractor (#D32F2F) facing right
- Realistic tractor details as shown in app animation

The icon should be saved as `app_icon.png` in this directory.