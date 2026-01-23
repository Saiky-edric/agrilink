# Social Media Logo Files

## Instructions for Adding Logo Files

### Required Files:
1. **google_logo.png** - Google logo (preferably 64x64px or higher)
2. **facebook_logo.png** - Facebook logo (preferably 64x64px or higher)

### Where to Download Official Logos:

#### Google Logo:
- **Official Source**: Google Brand Resource Center
- **URL**: https://about.google/brand-resource-center/
- **Recommended**: Download the "Google G" icon in PNG format
- **Size**: 64x64px, 128x128px, or 256x256px for best quality
- **Format**: PNG with transparent background (preferred)

#### Facebook Logo:
- **Official Source**: Facebook Brand Resource Center  
- **URL**: https://about.meta.com/brand/resources/facebookapp/
- **Recommended**: Download the Facebook "f" logo in PNG format
- **Size**: 64x64px, 128x128px, or 256x256px for best quality
- **Format**: PNG with transparent background (preferred)

### File Naming:
- Google logo: `google_logo.png`
- Facebook logo: `facebook_logo.png`

### After Adding Files:
1. Place the PNG files in this directory: `assets/images/logos/`
2. Run `flutter pub get` to refresh assets
3. The app will automatically use the image files instead of custom-painted logos

### Backup:
If the image files are not found or fail to load, the app will automatically fallback to the custom-painted logos that are already implemented.

### File Requirements:
- **Format**: PNG (recommended) or JPG
- **Size**: 64x64px minimum, 256x256px maximum
- **Background**: Transparent (for PNG) or white (for JPG)
- **Quality**: High resolution for crisp appearance on all devices