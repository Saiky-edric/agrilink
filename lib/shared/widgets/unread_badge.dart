import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class UnreadBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final Color? badgeColor;
  final Color? textColor;
  final double? size;
  final bool showZero;

  const UnreadBadge({
    super.key,
    required this.child,
    required this.count,
    this.badgeColor,
    this.textColor,
    this.size,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (count > 0 || showZero)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: BoxConstraints(
                minWidth: size ?? 16,
                minHeight: size ?? 16,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: (size ?? 16) * 0.6,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class CartBadge extends StatelessWidget {
  final Widget child;
  final int itemCount;

  const CartBadge({
    super.key,
    required this.child,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return UnreadBadge(
      count: itemCount,
      badgeColor: AppTheme.primaryGreen,
      size: 20,
      child: child,
    );
  }
}

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final int unreadCount;

  const NotificationBadge({
    super.key,
    required this.child,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return UnreadBadge(
      count: unreadCount,
      badgeColor: Colors.red,
      size: 18,
      child: child,
    );
  }
}

class MessageBadge extends StatelessWidget {
  final Widget child;
  final int unreadCount;

  const MessageBadge({
    super.key,
    required this.child,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return UnreadBadge(
      count: unreadCount,
      badgeColor: Colors.blue.shade600,
      size: 18,
      child: child,
    );
  }
}

class OrderBadge extends StatelessWidget {
  final Widget child;
  final int pendingCount;

  const OrderBadge({
    super.key,
    required this.child,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return UnreadBadge(
      count: pendingCount,
      badgeColor: Colors.orange.shade600,
      size: 18,
      child: child,
    );
  }
}