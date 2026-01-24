import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/utils/keyboard_utils.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/social_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        // Check if user has completed address setup
        final hasCompletedAddress = await _authService
            .hasCompletedAddressSetup();

        if (!hasCompletedAddress) {
          if (mounted) context.go(RouteNames.addressSetup);
          return;
        }

        // Get user profile to determine role-based navigation
        final user = await _authService.getCurrentUserProfile();

        if (user != null && mounted) {
          switch (user.role) {
            case UserRole.buyer:
              context.go(RouteNames.buyerHome);
              break;
            case UserRole.farmer:
              context.go(RouteNames.farmerDashboard);
              break;
            case UserRole.admin:
              context.go(RouteNames.adminDashboard);
              break;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      final user = await _authService.signInWithGoogle();

      if (mounted) {
        if (user == null) {
          // New user needs role selection
          context.go(RouteNames.socialRoleSelection);
        } else {
          // Existing user with role
          _navigateBasedOnRole(user);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() => _isFacebookLoading = true);

    try {
      final user = await _authService.signInWithFacebook();

      if (mounted) {
        if (user == null) {
          // New user needs role selection
          context.go(RouteNames.socialRoleSelection);
        } else {
          // Existing user with role
          _navigateBasedOnRole(user);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Facebook sign-in failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFacebookLoading = false);
    }
  }

  void _navigateBasedOnRole(UserModel user) {
    // Check if user has completed address setup
    if (user.municipality == null || user.municipality!.isEmpty) {
      context.go(RouteNames.addressSetup);
      return;
    }

    // Navigate based on role
    switch (user.role) {
      case UserRole.buyer:
        context.go(RouteNames.buyerHome);
        break;
      case UserRole.farmer:
        context.go(RouteNames.farmerDashboard);
        break;
      case UserRole.admin:
        context.go(RouteNames.adminDashboard);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go(RouteNames.onboarding),
        ),
      ),
      body: GestureDetector(
        onTap: () => KeyboardUtils.dismissKeyboard(context),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                const SizedBox(height: AppSpacing.xl),

                // Welcome text
                const Text('Welcome Back!', style: AppTextStyles.heading1),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Sign in to continue to your account',
                  style: AppTextStyles.bodyMedium,
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Email field
                CustomTextField(
                  label: 'Email Address',
                  hintText: 'Enter your email address',
                  type: TextFieldType.email,
                  controller: _emailController,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Password field
                CustomTextField(
                  label: 'Password',
                  hintText: 'Enter your password',
                  type: TextFieldType.password,
                  controller: _passwordController,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.lock_outlined),
                ),

                const SizedBox(height: AppSpacing.md),

                // Forgot password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(RouteNames.forgotPassword),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppTheme.primaryGreen),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Login button
                CustomButton(
                  text: 'Sign In',
                  type: ButtonType.primary,
                  isFullWidth: true,
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
                ),

                const SizedBox(height: AppSpacing.lg),

                // OR divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        'OR',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Social Authentication Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google Icon
                    GestureDetector(
                      onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.grey.shade300, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isGoogleLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                                  ),
                                ),
                              )
                            : Center(
                                child: Image.asset(
                                  'assets/images/logos/google_logo.png',
                                  width: 32,
                                  height: 32,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback to custom painted logo if image fails
                                    return SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CustomPaint(
                                        painter: GoogleLogoPainter(),
                                        size: const Size(32, 32),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(width: 24),
                    
                    // Facebook Icon
                    GestureDetector(
                      onTap: _isFacebookLoading ? null : _handleFacebookSignIn,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1877F2),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isFacebookLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              )
                            : Center(
                                child: Image.asset(
                                  'assets/images/logos/facebook_logo.png',
                                  width: 32,
                                  height: 32,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback to custom painted logo if image fails
                                    return SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CustomPaint(
                                        painter: FacebookLogoPainter(),
                                        size: const Size(32, 32),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: AppTextStyles.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.push(RouteNames.signupRole),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
