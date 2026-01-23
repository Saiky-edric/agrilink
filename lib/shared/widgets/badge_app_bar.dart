import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/badge_service.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_theme.dart';
import 'unread_badge.dart';

class BadgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showCartIcon;
  final bool showNotificationIcon;
  final List<Widget>? additionalActions;
  final Color? backgroundColor;

  const BadgeAppBar({
    super.key,
    required this.title,
    this.showCartIcon = true,
    this.showNotificationIcon = true,
    this.additionalActions,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: AppTheme.textPrimary,
      elevation: 1,
      shadowColor: Colors.black12,
      actions: [
        if (showCartIcon)
          Consumer<BadgeService>(
            builder: (context, badgeService, child) {
              return CartBadge(
                itemCount: badgeService.cartItemCount,
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () => context.push(RouteNames.cart),
                ),
              );
            },
          ),
        if (showNotificationIcon)
          Consumer<BadgeService>(
            builder: (context, badgeService, child) {
              return NotificationBadge(
                unreadCount: badgeService.unreadNotifications,
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push(RouteNames.notifications),
                ),
              );
            },
          ),
        if (additionalActions != null) ...additionalActions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Farmer-specific app bar
class FarmerBadgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showNotificationIcon;
  final List<Widget>? additionalActions;
  final Color? backgroundColor;

  const FarmerBadgeAppBar({
    super.key,
    required this.title,
    this.showNotificationIcon = true,
    this.additionalActions,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: AppTheme.textPrimary,
      elevation: 1,
      shadowColor: Colors.black12,
      actions: [
        if (showNotificationIcon)
          Consumer<BadgeService>(
            builder: (context, badgeService, child) {
              return NotificationBadge(
                unreadCount: badgeService.unreadNotifications,
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push(RouteNames.notifications),
                ),
              );
            },
          ),
        if (additionalActions != null) ...additionalActions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}