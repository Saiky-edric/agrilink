import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/route_names.dart';
import '../../core/router/profile_router_helper.dart';
import '../../core/models/user_model.dart';
import '../../core/services/badge_service.dart';

class ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool showBadge;
  final int badgeCount;

  const ModernBottomNav({
    super.key,
    required this.currentIndex,
    this.showBadge = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0,
                route: RouteNames.buyerHome,
              ),
              _buildNavItem(
                context,
                icon: Icons.category_outlined,
                activeIcon: Icons.category,
                label: 'Categories',
                index: 1,
                route: RouteNames.categories,
              ),
              Consumer<BadgeService>(
                builder: (context, badgeService, child) {
                  return _buildNavItem(
                    context,
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long,
                    label: 'Orders',
                    index: 2,
                    route: RouteNames.buyerOrders,
                    showBadge: badgeService.pendingOrders > 0,
                    badgeCount: badgeService.pendingOrders,
                  );
                },
              ),
              Consumer<BadgeService>(
                builder: (context, badgeService, child) {
                  return _buildNavItem(
                    context,
                    icon: Icons.chat_bubble_outline,
                    activeIcon: Icons.chat_bubble,
                    label: 'Messages',
                    index: 3,
                    route: RouteNames.chatInbox,
                    showBadge: badgeService.unreadMessages > 0,
                    badgeCount: badgeService.unreadMessages,
                  );
                },
              ),
              _buildNavItem(
                context,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                index: 4,
                route: RouteNames.buyerProfile, // Direct to buyer profile
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required String route,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    final isActive = currentIndex == index;
    
    return GestureDetector(
      onTap: () async {
        if (currentIndex != index) {
          // Special handling for profile route - determine user role
          if (route == RouteNames.buyerProfile) {
            final userRole = await ProfileRouterHelper.getUserRole();
            if (userRole == UserRole.farmer) {
              context.go(RouteNames.farmerProfile);
            } else {
              context.go(RouteNames.buyerProfile);
            }
          } else {
            if (route == RouteNames.chatInbox) {
              context.go(route, extra: {'origin': 'buyer'});
            } else {
              context.go(route);
            }
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: isActive 
                        ? AppTheme.primaryGreen 
                        : AppTheme.textSecondary,
                    size: 24,
                  ),
                ),
                if (showBadge && badgeCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.errorRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: AppTheme.textOnPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive 
                    ? AppTheme.primaryGreen 
                    : AppTheme.textSecondary,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}