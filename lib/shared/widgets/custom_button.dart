import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/keyboard_utils.dart';

enum ButtonType { primary, secondary, outline, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isOutlined;
  final bool dismissKeyboard;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.width,
    this.height,
    this.padding,
    this.backgroundColor,
    this.textColor,
    this.isOutlined = false,
    this.dismissKeyboard = true, // Auto-dismiss keyboard by default
  });

  @override
  Widget build(BuildContext context) {
    Widget button = _buildButton(context);
    
    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    
    if (width != null) {
      return SizedBox(
        width: width,
        child: button,
      );
    }
    
    return button;
  }

  Widget _buildButton(BuildContext context) {
    switch (type) {
      case ButtonType.primary:
        return _buildPrimaryButton(context);
      case ButtonType.secondary:
        return _buildSecondaryButton(context);
      case ButtonType.outline:
        return _buildOutlineButton(context);
      case ButtonType.text:
        return _buildTextButton(context);
    }
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _getOnPressedWithKeyboardDismissal(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: padding ?? const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          minimumSize: height != null ? Size.fromHeight(height!) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          ),
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : _getOnPressedWithKeyboardDismissal(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.surfaceGreen,
        foregroundColor: AppTheme.primaryGreen,
        elevation: 0,
        padding: padding ?? const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        minimumSize: height != null ? Size.fromHeight(height!) : null,
        side: BorderSide(color: AppTheme.accentGreen.withOpacity(0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        ),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildOutlineButton(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : _getOnPressedWithKeyboardDismissal(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryGreen,
        padding: padding ?? const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        minimumSize: height != null ? Size.fromHeight(height!) : null,
        side: BorderSide(color: AppTheme.primaryGreen, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        ),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildTextButton(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : _getOnPressedWithKeyboardDismissal(context),
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.primaryGreen,
        padding: padding ?? const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        minimumSize: height != null ? Size.fromHeight(height!) : null,
      ),
      child: _buildButtonContent(),
    );
  }

  VoidCallback? _getOnPressedWithKeyboardDismissal(BuildContext context) {
    if (onPressed == null) return null;
    
    return () {
      if (dismissKeyboard) {
        KeyboardUtils.dismissKeyboard(context);
      }
      onPressed!();
    };
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
    }

    return Text(text, style: const TextStyle(fontWeight: FontWeight.w600));
  }
}