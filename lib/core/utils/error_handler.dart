import 'package:flutter/material.dart';
import '../config/environment.dart';

/// Centralized error handling utility for the Agrilink application
class ErrorHandler {
  /// Handle and format authentication errors
  static String handleAuthError(dynamic error) {
    final errorMessage = error.toString().toLowerCase();
    
    if (errorMessage.contains('email')) {
      if (errorMessage.contains('already')) {
        return 'This email is already registered. Please use a different email or try signing in.';
      } else if (errorMessage.contains('invalid')) {
        return 'Please enter a valid email address.';
      }
    }
    
    if (errorMessage.contains('password')) {
      if (errorMessage.contains('weak') || errorMessage.contains('short')) {
        return 'Password must be at least 8 characters long.';
      } else if (errorMessage.contains('incorrect') || errorMessage.contains('invalid')) {
        return 'Incorrect email or password. Please try again.';
      }
    }
    
    if (errorMessage.contains('network')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    
    if (errorMessage.contains('timeout')) {
      return 'Connection timeout. Please try again.';
    }
    
    return 'Authentication failed. Please try again or contact support.';
  }

  /// Handle and format database errors
  static String handleDatabaseError(dynamic error) {
    final errorMessage = error.toString().toLowerCase();
    
    if (errorMessage.contains('permission') || errorMessage.contains('denied')) {
      return 'You do not have permission to perform this action.';
    }
    
    if (errorMessage.contains('unique')) {
      return 'This record already exists. Please use different information.';
    }
    
    if (errorMessage.contains('foreign key') || errorMessage.contains('constraint')) {
      return 'Invalid data provided. Please check your information.';
    }
    
    if (errorMessage.contains('network') || errorMessage.contains('connection')) {
      return 'Database connection error. Please try again later.';
    }
    
    return 'Database error occurred. Please try again or contact support.';
  }

  /// Handle and format file upload errors
  static String handleStorageError(dynamic error) {
    final errorMessage = error.toString().toLowerCase();
    
    if (errorMessage.contains('size') || errorMessage.contains('large')) {
      return 'File is too large. Please choose a smaller file.';
    }
    
    if (errorMessage.contains('format') || errorMessage.contains('type')) {
      return 'Invalid file format. Please use JPG, PNG, or PDF files only.';
    }
    
    if (errorMessage.contains('network')) {
      return 'Upload failed due to network error. Please try again.';
    }
    
    return 'File upload failed. Please try again.';
  }

  /// Handle general application errors
  static String handleGeneralError(dynamic error) {
    final errorMessage = error.toString().toLowerCase();
    
    if (errorMessage.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    }
    
    if (errorMessage.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    if (errorMessage.contains('server')) {
      return 'Server error. Please try again later.';
    }
    
    return 'An unexpected error occurred. Please try again.';
  }

  /// Log error with proper formatting
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    EnvironmentConfig.logError('[$context] Error occurred', error, stackTrace);
  }

  /// Show error snackbar to user
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar to user
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error dialog for critical errors
  static void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}