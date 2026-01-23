import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ═══════════════════════════════════════════════════════════
  // 🌾 MODERN AGRICULTURE COLOR PALETTE - 2025
  // Fresh, trustworthy, and clean design system
  // ═══════════════════════════════════════════════════════════
  
  // PRIMARY - Fresh Green (Nature & Growth) - LIGHTER & FRESHER
  static const Color primaryGreen = Color(0xFF52B788);        // Fresh vibrant green - energetic
  static const Color primaryGreenLight = Color(0xFF74C69D);   // Light fresh green - bright
  static const Color primaryGreenDark = Color(0xFF40916C);    // Medium green - balanced
  
  // Backward compatibility
  static Color get primaryColor => primaryGreen;
  
  // SECONDARY - Earth & Sky (Agriculture Elements)
  static const Color secondaryBrown = Color(0xFF8B7355);      // Warm earth brown
  static const Color secondaryBlue = Color(0xFF4A90E2);       // Clear sky blue
  static const Color secondaryAmber = Color(0xFFD4A574);      // Harvest gold
  static const Color secondaryGreen = Color(0xFF8BC34A);      // Light lime green (compatibility)
  
  // ACCENT - Vibrant & Fresh - MORE COLORFUL
  static const Color accentGreen = Color(0xFF95D5B2);         // Bright light green
  static const Color accentOrange = Color(0xFFFF6B35);        // Vibrant coral orange
  static const Color accentTeal = Color(0xFF4ECDC4);          // Bright turquoise
  static const Color accentPurple = Color(0xFF9B59B6);        // Vibrant purple
  static const Color accentPink = Color(0xFFEC4899);          // Bright pink
  static const Color accentYellow = Color(0xFFFBBF24);        // Sunny yellow
  
  // SURFACE - Clean & Light - BRIGHTER
  static const Color surfaceLight = Color(0xFFFAFDFA);        // Very light cream - main bg
  static const Color surfaceGreen = Color(0xFFD8F3DC);        // Bright mint tint
  static const Color surfaceWarm = Color(0xFFFFF5E6);         // Warm peach cream
  static const Color surfaceBlue = Color(0xFFE3F2FD);         // Bright sky tint
  static const Color surfacePurple = Color(0xFFF3E5F5);       // Light purple tint
  static const Color surfacePink = Color(0xFFFCE7F3);         // Light pink tint
  
  // NEUTRALS - Modern & Clean
  static const Color cardWhite = Color(0xFFFFFFFF);           // Pure white cards
  static const Color backgroundWhite = Color(0xFFFFFFFE);     // Slightly warm white
  static const Color backgroundLight = Color(0xFFF5F7F4);     // Neutral light
  static const Color surfaceVariant = Color(0xFFF5F5F5);      // Surface variant (compatibility)
  static const Color lightGrey = Color(0xFFE5E7EB);           // Soft grey
  static const Color neutralGrey = Color(0xFF9CA3AF);         // Medium grey
  static const Color darkGrey = Color(0xFF4B5563);            // Dark grey
  
  // TEXT - High Contrast & Accessible
  static const Color textPrimary = Color(0xFF1F2937);         // Almost black
  static const Color textSecondary = Color(0xFF6B7280);       // Medium grey
  static const Color textTertiary = Color(0xFF9CA3AF);        // Light grey
  static const Color textHint = Color(0xFFD1D5DB);            // Very light grey
  static const Color textOnPrimary = Color(0xFFFFFFFF);       // White on colored bg
  static const Color textOnDark = Color(0xFFF9FAFB);          // Off-white
  
  // STATUS COLORS - Clear Communication - MORE VIBRANT
  static const Color successGreen = Color(0xFF22C55E);        // Brighter success
  static const Color warningOrange = Color(0xFFFB923C);       // Vibrant warning
  static const Color errorRed = Color(0xFFF43F5E);            // Vibrant error
  static const Color infoBlue = Color(0xFF3B82F6);            // Information blue
  static const Color pendingPurple = Color(0xFFA855F7);       // Bright pending
  
  // FEATURED/SPECIAL - Eye-catching
  static const Color featuredGold = Color(0xFFFBBF24);        // Gold badge
  static const Color premiumPurple = Color(0xFF7C3AED);       // Premium feature
  static const Color newBadgeBlue = Color(0xFF06B6D4);        // New item badge
  
  // ═══════════════════════════════════════════════════════════
  // GRADIENTS - Modern & Smooth
  // ═══════════════════════════════════════════════════════════
  
  // Primary gradient (green)
  static const Gradient primaryGradient = LinearGradient(
    colors: [primaryGreen, primaryGreenLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Fresh gradient (green to teal) - MORE VIBRANT
  static const Gradient freshGradient = LinearGradient(
    colors: [primaryGreen, accentTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Colorful gradient (multi-color)
  static const Gradient colorfulGradient = LinearGradient(
    colors: [accentTeal, primaryGreen, accentYellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Warm gradient (earth tones)
  static const Gradient warmGradient = LinearGradient(
    colors: [secondaryAmber, accentOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Sky gradient (blue tones)
  static const Gradient skyGradient = LinearGradient(
    colors: [secondaryBlue, Color(0xFF64B5F6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Featured gradient (gold to orange)
  static const Gradient featuredGradient = LinearGradient(
    colors: [featuredGold, accentOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Sunrise gradient (warm morning colors)
  static const Gradient sunriseGradient = LinearGradient(
    colors: [Color(0xFFFFA07A), accentOrange, featuredGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Background gradient (subtle)
  static const Gradient backgroundGradient = LinearGradient(
    colors: [surfaceLight, backgroundLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Premium gradient (purple)
  static const Gradient premiumGradient = LinearGradient(
    colors: [premiumPurple, Color(0xFF9333EA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ═══════════════════════════════════════════════════════════
  // GLASSMORPHISM & OVERLAYS
  // ═══════════════════════════════════════════════════════════
  
  static const Color glassOverlay = Color(0x1AFFFFFF);
  static const Color glassBackground = Color(0x80FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color darkOverlay = Color(0x80000000);
  static const Color lightOverlay = Color(0x40FFFFFF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
        primary: primaryGreen,
        onPrimary: textOnPrimary,
        secondary: accentGreen,
        onSecondary: textOnPrimary,
        tertiary: accentTeal,
        onTertiary: textOnPrimary,
        surface: cardWhite,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceLight,
        onSurfaceVariant: textSecondary,
        error: errorRed,
        onError: textOnPrimary,
        outline: neutralGrey,
        outlineVariant: lightGrey,
      ),
      scaffoldBackgroundColor: surfaceLight,

      // App Bar Theme - Clean & Modern
      appBarTheme: AppBarTheme(
        backgroundColor: cardWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 2,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: textPrimary, size: 24),
        shape: Border(bottom: BorderSide(color: lightGrey, width: 1)),
      ),

      // Card Theme - Elevated & Clean
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: lightGrey.withValues(alpha: 0.5), width: 1),
        ),
        shadowColor: textPrimary.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
      ),

      // Elevated Button Theme - Modern & Vibrant
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: textOnPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ).copyWith(
              shadowColor: WidgetStateProperty.all(
                primaryGreen.withValues(alpha: 0.4),
              ),
              elevation: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) return 0;
                if (states.contains(WidgetState.hovered)) return 4;
                return 2;
              }),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return textOnPrimary.withValues(alpha: 0.12);
                }
                return null;
              }),
            ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: BorderSide(color: primaryGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // Input Decoration Theme - Clean & Modern
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightGrey, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightGrey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: textTertiary),
        labelStyle: TextStyle(color: textSecondary),
      ),

      // Bottom Navigation Bar Theme - Modern & Clean
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardWhite,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: textOnPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chip Theme - Modern Pills
      chipTheme: ChipThemeData(
        backgroundColor: surfaceGreen,
        selectedColor: primaryGreen,
        labelStyle: const TextStyle(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(color: textOnPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: lightGrey.withValues(alpha: 0.5)),
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: lightGrey,
        thickness: 1,
        space: 1,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryGreen,
        linearTrackColor: surfaceGreen,
        circularTrackColor: surfaceGreen,
      ),

      // Badge Theme
      badgeTheme: BadgeThemeData(
        backgroundColor: errorRed,
        textColor: textOnPrimary,
        textStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: cardWhite,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: textOnDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.dark,
        primary: primaryGreenLight,
        onPrimary: Colors.black,
        secondary: accentGreen,
        surface: const Color(0xFF1E1E1E),
        onSurface: Colors.white,
      ),
    );
  }
}

// Custom text styles
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppTheme.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
  );

  static const TextStyle heading4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppTheme.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppTheme.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppTheme.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppTheme.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppTheme.textHint,
  );
}

// Custom spacing constants
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// Custom border radius
class AppBorderRadius {
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double xl = 24.0;
}

// Modern Shadow Utilities
class AppShadows {
  static final List<BoxShadow> subtle = [
    BoxShadow(
      color: AppTheme.textPrimary.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> medium = [
    BoxShadow(
      color: AppTheme.textPrimary.withValues(alpha: 0.1),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> prominent = [
    BoxShadow(
      color: AppTheme.textPrimary.withValues(alpha: 0.15),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> elevated = [
    BoxShadow(
      color: AppTheme.textPrimary.withValues(alpha: 0.2),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  static final List<BoxShadow> soft = [
    BoxShadow(
      color: AppTheme.primaryGreen.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
  ];
}

// Modern Border Utilities
class AppBorders {
  static final BorderSide subtle = BorderSide(
    color: AppTheme.lightGrey,
    width: 0.5,
  );

  static final BorderSide default_ = BorderSide(
    color: AppTheme.lightGrey,
    width: 1.0,
  );

  static final BorderSide prominent = BorderSide(
    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
    width: 1.5,
  );
}

// Modern Decoration Utilities
class AppDecorations {
  static BoxDecoration get modernCard {
    return BoxDecoration(
      color: AppTheme.cardWhite,
      borderRadius: BorderRadius.circular(AppBorderRadius.large),
      border: Border.all(color: AppTheme.lightGrey, width: 0.5),
      boxShadow: AppShadows.subtle,
    );
  }

  static BoxDecoration get modernCardElevated {
    return BoxDecoration(
      color: AppTheme.cardWhite,
      borderRadius: BorderRadius.circular(AppBorderRadius.large),
      border: Border.all(color: AppTheme.lightGrey, width: 0.5),
      boxShadow: AppShadows.medium,
    );
  }

  static BoxDecoration get modernButton {
    return BoxDecoration(
      gradient: AppTheme.primaryGradient,
      borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      boxShadow: AppShadows.soft,
    );
  }

  static BoxDecoration get modernButtonSecondary {
    return BoxDecoration(
      color: AppTheme.surfaceGreen,
      borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      border: Border.all(color: AppTheme.primaryGreen, width: 1),
    );
  }

  static BoxDecoration get modernChip {
    return BoxDecoration(
      color: AppTheme.lightGrey,
      borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      border: Border.all(color: AppTheme.lightGrey, width: 0.5),
    );
  }

  static BoxDecoration get modernChipActive {
    return BoxDecoration(
      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      border: Border.all(color: AppTheme.primaryGreen, width: 1),
    );
  }
}
