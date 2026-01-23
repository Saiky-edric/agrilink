import 'package:flutter/material.dart';

/// Utility class for managing keyboard interactions
class KeyboardUtils {
  /// Dismiss the keyboard if it's currently visible
  static void dismissKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  /// Dismiss keyboard and then execute a callback
  /// Useful for button presses that should hide keyboard before performing action
  static void dismissKeyboardAndExecute(BuildContext context, VoidCallback callback) {
    dismissKeyboard(context);
    // Small delay to ensure keyboard dismissal completes before callback
    Future.delayed(const Duration(milliseconds: 50), callback);
  }

  /// Dismiss keyboard and then execute an async callback
  static Future<void> dismissKeyboardAndExecuteAsync(
    BuildContext context,
    Future<void> Function() callback,
  ) async {
    dismissKeyboard(context);
    // Small delay to ensure keyboard dismissal completes before callback
    await Future.delayed(const Duration(milliseconds: 50));
    await callback();
  }
}
