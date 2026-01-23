import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/badge_service.dart';
import 'unread_badge.dart';

class FarmerBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FarmerBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 11,
          ),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Consumer<BadgeService>(
                builder: (context, badgeService, child) {
                  return OrderBadge(
                    pendingCount: badgeService.pendingOrders,
                    child: Icon(Icons.shopping_bag_outlined),
                  );
                },
              ),
              activeIcon: Consumer<BadgeService>(
                builder: (context, badgeService, child) {
                  return OrderBadge(
                    pendingCount: badgeService.pendingOrders,
                    child: Icon(Icons.shopping_bag),
                  );
                },
              ),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Consumer<BadgeService>(
                builder: (context, badgeService, child) {
                  return MessageBadge(
                    unreadCount: badgeService.unreadMessages,
                    child: Icon(Icons.chat_bubble_outline),
                  );
                },
              ),
              activeIcon: Consumer<BadgeService>(
                builder: (context, badgeService, child) {
                  return MessageBadge(
                    unreadCount: badgeService.unreadMessages,
                    child: Icon(Icons.chat_bubble),
                  );
                },
              ),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}