import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'badge_service.dart';

class BadgeHelper {
  static Future<void> updateCartBadge(BuildContext context) async {
    try {
      final badgeService = Provider.of<BadgeService>(context, listen: false);
      await badgeService._loadCartCount();
    } catch (e) {
      print('Error updating cart badge: $e');
    }
  }

  static Future<void> updateMessageBadge(BuildContext context) async {
    try {
      final badgeService = Provider.of<BadgeService>(context, listen: false);
      await badgeService._loadMessageCount();
    } catch (e) {
      print('Error updating message badge: $e');
    }
  }

  static Future<void> updateOrderBadge(BuildContext context) async {
    try {
      final badgeService = Provider.of<BadgeService>(context, listen: false);
      await badgeService._loadOrderCount();
    } catch (e) {
      print('Error updating order badge: $e');
    }
  }

  static Future<void> updateNotificationBadge(BuildContext context) async {
    try {
      final badgeService = Provider.of<BadgeService>(context, listen: false);
      await badgeService._loadNotificationCount();
    } catch (e) {
      print('Error updating notification badge: $e');
    }
  }

  static Future<void> refreshAllBadges(BuildContext context) async {
    try {
      final badgeService = Provider.of<BadgeService>(context, listen: false);
      await badgeService.initializeBadges();
    } catch (e) {
      print('Error refreshing all badges: $e');
    }
  }
}