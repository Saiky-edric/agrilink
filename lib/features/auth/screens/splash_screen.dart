import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/models/user_model.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Extended splash duration per request
    await Future.delayed(const Duration(seconds: 8));

    if (!mounted) return;

    try {
      if (_authService.isLoggedIn) {
        // Check if user has completed address setup
        final hasCompletedAddress = await _authService
            .hasCompletedAddressSetup();

        if (!hasCompletedAddress) {
          if (mounted) context.go(RouteNames.addressSetup);
          return;
        }

        // Force fresh user profile load to prevent role-mixing bug
        final user = await _profileService.getCurrentUserProfile(forceRefresh: true);

        if (!mounted) return;

        if (user != null) {
          // Log the navigation for debugging role-mixing issues
          print('🔍 SPLASH: Navigating user ${user.fullName} with role ${user.role.name}');
          
          switch (user.role) {
            case UserRole.buyer:
              print('🏠 SPLASH: Routing to BUYER home');
              context.go(RouteNames.buyerHome);
              break;
            case UserRole.farmer:
              print('🚜 SPLASH: Routing to FARMER dashboard');
              context.go(RouteNames.farmerDashboard);
              break;
            case UserRole.admin:
              print('👨‍💼 SPLASH: Routing to ADMIN dashboard');
              context.go(RouteNames.adminDashboard);
              break;
          }
        } else {
          print('❌ SPLASH: No user found, routing to login');
          context.go(RouteNames.login);
        }
      } else {
        // Check if user has seen onboarding
        if (mounted) context.go(RouteNames.onboarding);
      }
    } catch (e) {
      // If there's an error, go to login
      if (mounted) context.go(RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.agriculture,
                        size: 60,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // App Name
                    const Text(
                      'Agrilink',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // App Tagline
                    const Text(
                      'Digital Marketplace',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    const Text(
                      'Connecting Farmers • Serving Communities',
                      style: TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),

            // Tractor loading animation (modern layout)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xxl),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final height = width * 0.8; // Original size
                      return ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: 0.70, // Crop 30% from bottom
                          child: Transform.translate(
                            offset: Offset(0, -height * 0.15), // Move up 15% to crop top
                            child: SizedBox(
                              width: width,
                              height: height,
                              child: Lottie.asset(
                                'assets/lottie/loader_tractor.json',
                                fit: BoxFit.contain,
                                repeat: true,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Loading your experience...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
