import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../models/user_model.dart';
import '../../features/buyer/screens/buyer_profile_screen.dart';
import '../../features/farmer/screens/farmer_profile_screen.dart';
import '../../features/shared/screens/under_development_screen.dart';
import 'route_names.dart';

class ProfileRouterHelper {
  static final AuthService _authService = AuthService();
  static final ProfileService _profileService = ProfileService();

  /// Get the appropriate profile screen based on user role
  static Widget getProfileScreen() {
    return FutureBuilder<UserModel?>(
      future: _profileService.getCurrentUserProfile(forceRefresh: true), // Force fresh data
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: Text('Error loading profile. Please try again.'),
            ),
          );
        }

        final user = snapshot.data!;
        
        switch (user.role) {
          case UserRole.buyer:
            return const BuyerProfileScreen();
          case UserRole.farmer:
            return const FarmerProfileScreen();
          case UserRole.admin:
            return const UnderDevelopmentScreen(featureName: 'Admin Profile');
          default:
            return const BuyerProfileScreen(); // Default fallback
        }
      },
    );
  }

  /// Navigate to the correct profile screen based on user role
  static Future<void> navigateToProfile(BuildContext context) async {
    try {
      final user = await _profileService.getCurrentUserProfile(forceRefresh: true);
      
      if (user == null) {
        // User not found, redirect to login
        if (context.mounted) {
          context.go(RouteNames.login);
        }
        return;
      }

      if (!context.mounted) return;

      switch (user.role) {
        case UserRole.buyer:
          context.go(RouteNames.buyerProfile);
          break;
        case UserRole.farmer:
          context.go(RouteNames.farmerProfile);
          break;
        case UserRole.admin:
          // Admin profile not implemented yet
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin profile coming soon!'),
            ),
          );
          break;
        default:
          context.go(RouteNames.buyerProfile);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error navigating to profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Get the profile route name based on user role
  static Future<String> getProfileRouteName() async {
    try {
      final user = await _profileService.getCurrentUserProfile();
      
      if (user == null) {
        return RouteNames.login;
      }

      switch (user.role) {
        case UserRole.buyer:
          return RouteNames.buyerProfile;
        case UserRole.farmer:
          return RouteNames.farmerProfile;
        case UserRole.admin:
          return RouteNames.buyerProfile; // Fallback for now
        default:
          return RouteNames.buyerProfile;
      }
    } catch (e) {
      return RouteNames.buyerProfile; // Fallback
    }
  }

  /// Check if user is authenticated and get their role
  static Future<UserRole?> getUserRole() async {
    try {
      if (!_authService.isLoggedIn) {
        return null;
      }

      final user = await _profileService.getCurrentUserProfile();
      return user?.role;
    } catch (e) {
      return null;
    }
  }
}