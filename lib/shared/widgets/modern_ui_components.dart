// Modern UI Components - Reference Code
// Use these patterns throughout the app for consistent modern design

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Modern Card Example
class ModernCardExample extends StatelessWidget {
  const ModernCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.modernCard,
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Card Title', style: AppTextStyles.heading4),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Card description with subtle text',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Modern Button Example
class ModernButtonExample extends StatelessWidget {
  const ModernButtonExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary Button
        Container(
          decoration: AppDecorations.modernButton,
          child: ElevatedButton(
            onPressed: () {},
            child: Text('Primary Action'),
          ),
        ),
        SizedBox(height: AppSpacing.md),

        // Secondary Button
        Container(
          decoration: AppDecorations.modernButtonSecondary,
          child: TextButton(onPressed: () {}, child: Text('Secondary Action')),
        ),
      ],
    );
  }
}

/// Modern List Item Example
class ModernListItemExample extends StatelessWidget {
  const ModernListItemExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.modernCard,
      margin: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Icon/Image
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            child: Icon(Icons.inventory, color: AppTheme.primaryGreen),
          ),
          SizedBox(width: AppSpacing.md),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Item Title', style: AppTextStyles.heading4),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Item subtitle or description',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),

          // Action
          Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}

/// Modern Chip Example
class ModernChipExample extends StatefulWidget {
  const ModernChipExample({super.key});

  @override
  State<ModernChipExample> createState() => _ModernChipExampleState();
}

class _ModernChipExampleState extends State<ModernChipExample> {
  List<bool> selectedChips = [true, false, false, false];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: List.generate(4, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedChips[index] = !selectedChips[index];
            });
          },
          child: Container(
            decoration: selectedChips[index]
                ? AppDecorations.modernChipActive
                : AppDecorations.modernChip,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              'Chip ${index + 1}',
              style: TextStyle(
                color: selectedChips[index]
                    ? AppTheme.primaryGreen
                    : AppTheme.textPrimary,
                fontWeight: selectedChips[index]
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Modern Status Badge Example
class ModernStatusBadge extends StatelessWidget {
  final String label;
  final StatusType status;

  const ModernStatusBadge({
    super.key,
    required this.label,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor, textColor;

    switch (status) {
      case StatusType.success:
        backgroundColor = AppTheme.successGreen.withValues(alpha: 0.1);
        textColor = AppTheme.successGreen;
        break;
      case StatusType.warning:
        backgroundColor = AppTheme.warningOrange.withValues(alpha: 0.1);
        textColor = AppTheme.warningOrange;
        break;
      case StatusType.error:
        backgroundColor = AppTheme.errorRed.withValues(alpha: 0.1);
        textColor = AppTheme.errorRed;
        break;
      case StatusType.info:
        backgroundColor = AppTheme.infoBlue.withValues(alpha: 0.1);
        textColor = AppTheme.infoBlue;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum StatusType { success, warning, error, info }

/// Modern Loading State Example
class ModernLoadingState extends StatelessWidget {
  const ModernLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            ),
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text('Loading...', style: AppTextStyles.bodyLarge),
          SizedBox(height: AppSpacing.sm),
          Text('Please wait', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

/// Modern Empty State Example
class ModernEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const ModernEmptyState({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: AppTheme.primaryGreen),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: AppTextStyles.heading3,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.sm),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              description,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            SizedBox(height: AppSpacing.lg),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
