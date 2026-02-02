import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/utils/keyboard_utils.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import 'otp_verification_screen.dart';

class SignupFarmerScreen extends StatefulWidget {
  const SignupFarmerScreen({super.key});

  @override
  State<SignupFarmerScreen> createState() => _SignupFarmerScreenState();
}

class _SignupFarmerScreenState extends State<SignupFarmerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms of Service and Privacy Policy'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Send OTP to email for verification
      await _authService.sendSignupOTP(_emailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent! Check your email.'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Navigate to OTP verification with signup data
        context.push(
          RouteNames.otpVerification,
          extra: SignupData(
            email: _emailController.text.trim(),
            fullName: _fullNameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            role: UserRole.farmer,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send verification code: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
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
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Farmer Signup',
          style: TextStyle(color: AppTheme.textPrimary),
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
                const SizedBox(height: AppSpacing.md),
                
                // Welcome text
                const Text(
                  'Create Farmer Account',
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Start selling your fresh products to local buyers',
                  style: AppTextStyles.bodyMedium,
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Verification notice
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                    border: Border.all(
                      color: AppTheme.accentGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_user,
                        color: AppTheme.accentGreen,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          'All farmers must complete verification before selling products. You\'ll be guided through the process after signup.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Full Name field
                CustomTextField(
                  label: 'Full Name',
                  hintText: 'Enter your full name',
                  controller: _fullNameController,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.person_outlined),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
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
                
                // Phone field
                CustomTextField(
                  label: 'Phone Number',
                  hintText: 'Enter your phone number',
                  type: TextFieldType.phone,
                  controller: _phoneController,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Password field
                CustomTextField(
                  label: 'Password',
                  hintText: 'Create a password',
                  type: TextFieldType.password,
                  controller: _passwordController,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.lock_outlined),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Confirm Password field
                CustomTextField(
                  label: 'Confirm Password',
                  hintText: 'Confirm your password',
                  type: TextFieldType.password,
                  controller: _confirmPasswordController,
                  isRequired: true,
                  validator: _validateConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outlined),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Terms and conditions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                      activeColor: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: AppTextStyles.bodySmall,
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const TermsOfServiceScreen(),
                                    ),
                                  );
                                },
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PrivacyPolicyScreen(),
                                    ),
                                  );
                                },
                            ),
                            const TextSpan(text: ' '),
                            const TextSpan(
                              text: '',
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Signup button
                CustomButton(
                  text: 'Create Account',
                  type: ButtonType.primary,
                  isFullWidth: true,
                  isLoading: _isLoading,
                  onPressed: _handleSignup,
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Sign in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: AppTextStyles.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go(RouteNames.login),
                      child: const Text(
                        'Sign In',
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