import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../router/route_names.dart';
import '../theme/app_theme.dart';
import 'auth_service.dart';
import 'profile_service.dart';

/// Service for managing premium tier functionality
class PremiumService {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  /// Check if current logged-in user is premium
  Future<bool> isCurrentUserPremium() async {
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      if (userProfile == null) return false;
      
      return userProfile.isPremium;
    } catch (e) {
      print('Error checking current user premium status: $e');
      return false;
    }
  }

  /// Get premium expiry date for current user
  Future<DateTime?> getPremiumExpiryDate() async {
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      if (userProfile == null) return null;
      
      return userProfile.subscriptionExpiresAt;
    } catch (e) {
      print('Error getting premium expiry: $e');
      return null;
    }
  }

  /// Get days remaining in premium subscription for current user
  Future<int?> getPremiumDaysRemaining() async {
    try {
      final expiryDate = await getPremiumExpiryDate();
      if (expiryDate == null) return null;
      
      final now = DateTime.now();
      if (expiryDate.isBefore(now)) return 0;
      
      return expiryDate.difference(now).inDays;
    } catch (e) {
      print('Error calculating days remaining: $e');
      return null;
    }
  }

  /// Show upgrade to premium dialog
  void showUpgradeDialog(BuildContext context, {String? title, String? message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.star, color: AppTheme.primaryGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title ?? 'Premium Feature'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message ?? 'This feature is available for Premium farmers only.',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: AppTheme.primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Premium Benefits',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitRow('Unlimited product listings'),
                  _buildBenefitRow('5 photos per product'),
                  _buildBenefitRow('Priority in search results'),
                  _buildBenefitRow('Featured on homepage'),
                  _buildBenefitRow('Premium Farmer badge'),
                  const SizedBox(height: 12),
                  const Text(
                    'Only ₱149/month',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(RouteNames.subscription);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Upgrade to Premium'),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Get maximum images allowed for current user
  Future<int> getMaxImagesAllowed() async {
    try {
      final isPremium = await isCurrentUserPremium();
      return isPremium ? 5 : 4; // 5 for premium, 4 for free (1 cover + 3/4 additional)
    } catch (e) {
      print('Error getting max images: $e');
      return 4; // Default to free tier
    }
  }

  /// Get maximum additional images allowed for current user (excluding cover)
  Future<int> getMaxAdditionalImagesAllowed() async {
    try {
      final isPremium = await isCurrentUserPremium();
      return isPremium ? 4 : 3; // 4 additional for premium, 3 for free
    } catch (e) {
      print('Error getting max additional images: $e');
      return 3; // Default to free tier
    }
  }
}
