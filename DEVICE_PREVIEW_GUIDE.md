# 📱 Device Preview Setup Guide - Agrilink Digital Marketplace

## ✅ **Device Preview Successfully Added**

Device Preview allows you to test your Flutter app on different device sizes, orientations, and configurations without needing multiple physical devices.

## 🎯 **What's Been Configured**

### **1. Dependencies Added**
```yaml
dev_dependencies:
  device_preview: ^1.1.0  # Added to pubspec.yaml
```

### **2. Main App Updated**
- **`lib/main.dart`** - Development version with Device Preview enabled
- **`lib/main_production.dart`** - Production version without Device Preview

### **3. DevicePreview Integration**
```dart
// Development version (main.dart)
runApp(
  DevicePreview(
    enabled: true, // Set to false for production builds
    builder: (context) => AgrilinkApp(themeService: themeService),
  ),
);

// MaterialApp configuration
MaterialApp.router(
  // ... your existing config
  useInheritedMediaQuery: true,
  locale: DevicePreview.locale(context),
  builder: DevicePreview.appBuilder,
);
```

## 🚀 **How to Use Device Preview**

### **Development Mode (with Device Preview):**
```bash
# Install the new dependency
flutter pub get

# Run with Device Preview enabled
flutter run --dart-define-from-file=.env
```

### **Production Mode (without Device Preview):**
```bash
# Use the production version for release builds
flutter build apk --dart-define-from-file=.env -t lib/main_production.dart
```

## 📱 **Device Preview Features**

When you run the app, you'll see:

### **🎛️ Control Panel:**
- **Device Selection** - iPhone, Samsung Galaxy, iPad, etc.
- **Orientation** - Portrait/Landscape toggle
- **Zoom Controls** - Scale the preview
- **Screenshot Tool** - Capture app screenshots
- **Frame Toggle** - Show/hide device frame

### **📐 Available Devices:**
- **iPhone Models**: iPhone 13, iPhone SE, iPhone 13 Pro Max
- **Android Phones**: Samsung Galaxy S21, Pixel 5, OnePlus 9
- **Tablets**: iPad Pro, Samsung Galaxy Tab
- **Custom Sizes** - Define your own dimensions

### **🔧 Testing Features:**
- **Text Scaling** - Test accessibility with different text sizes
- **Dark/Light Mode** - Toggle theme modes
- **RTL Support** - Test right-to-left languages
- **Accessibility** - Test screen reader compatibility

## 📊 **Best Practices for Testing**

### **1. Test Key Agrilink Screens:**
```
✅ Splash Screen & Onboarding
✅ Login/Registration Forms  
✅ Product List/Grid Views
✅ Product Details Screen
✅ Farmer Verification Upload
✅ Chat/Messaging Interface
✅ Admin Dashboard
✅ Settings/Profile Screens
```

### **2. Test Different Orientations:**
- **Portrait** - Primary use case
- **Landscape** - Image viewing, forms
- **Rotation** - Ensure layouts adapt

### **3. Test Various Screen Sizes:**
- **Small phones** (iPhone SE) - Check text readability
- **Large phones** (iPhone 13 Pro Max) - Ensure layout efficiency
- **Tablets** (iPad Pro) - Test responsive design

### **4. Test Edge Cases:**
- **Long product names** - Text overflow handling
- **No internet connection** - Error states
- **Empty states** - No products, no messages
- **Loading states** - Network requests

## 🎨 **Screenshot & Documentation**

### **Take Screenshots:**
1. **Select target device** in Device Preview
2. **Navigate to screen** you want to capture
3. **Click screenshot button** in Device Preview toolbar
4. **Screenshots saved** to your downloads folder

### **Create App Store Assets:**
```bash
# Use Device Preview to create consistent screenshots for:
- Google Play Store listings
- Apple App Store listings  
- Documentation and marketing materials
- Bug reports and issue tracking
```

## ⚠️ **Important Notes**

### **Performance Considerations:**
- Device Preview adds some **performance overhead**
- **Disable for production builds** using `main_production.dart`
- **Hot reload works normally** with Device Preview

### **Build Configurations:**

#### **Development (with Device Preview):**
```bash
flutter run --dart-define-from-file=.env
# Uses lib/main.dart (default)
```

#### **Testing/Staging:**
```bash
flutter run --profile --dart-define-from-file=.env
# Uses lib/main.dart but with profile optimizations
```

#### **Production:**
```bash
flutter build apk --dart-define-from-file=.env -t lib/main_production.dart
# Uses lib/main_production.dart (no Device Preview)
```

## 🔧 **Advanced Configuration**

### **Conditional Device Preview:**
```dart
// Enable only in debug mode
runApp(
  DevicePreview(
    enabled: !kReleaseMode, // Automatically disabled in release builds
    builder: (context) => AgrilinkApp(themeService: themeService),
  ),
);
```

### **Custom Device Configurations:**
```dart
// Add custom device sizes for specific testing
DevicePreview(
  enabled: true,
  devices: [
    ...Devices.all,
    const Device(
      name: 'Agrilink Custom',
      size: Size(390, 844),  // Custom size for your target users
      devicePixelRatio: 3.0,
      type: DeviceType.phone,
    ),
  ],
  builder: (context) => AgrilinkApp(themeService: themeService),
);
```

## 🎯 **Testing Checklist for Agrilink**

### **Core Functionality:**
- [ ] **User Registration** - Forms work on all devices
- [ ] **Login Flow** - Social auth buttons properly sized
- [ ] **Product Browsing** - Grid/list views adapt to screen
- [ ] **Image Upload** - Camera/gallery selection works
- [ ] **Chat Interface** - Messages display correctly
- [ ] **Navigation** - Bottom nav bar and drawer work

### **Agricultural Specific Testing:**
- [ ] **Farmer Verification** - Document upload on small screens
- [ ] **Product Images** - Photos display well on various sizes
- [ ] **Location Selection** - Municipality dropdown usable
- [ ] **Order Management** - Tables/lists readable on phones

### **Responsive Design:**
- [ ] **Text Readability** - All sizes, especially on small screens
- [ ] **Button Accessibility** - Touch targets ≥44dp
- [ ] **Form Usability** - Inputs don't overflow on landscape
- [ ] **Image Scaling** - Product photos look good everywhere

## 🚀 **Ready to Test!**

Your Agrilink app now has Device Preview integrated! Run `flutter pub get` and then `flutter run --dart-define-from-file=.env` to start testing on multiple device configurations.

**Pro Tip**: Keep Device Preview open while developing to instantly see how your changes look on different devices! 📱✨