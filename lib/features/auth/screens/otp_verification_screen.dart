import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/router/route_names.dart';
import '../../../core/utils/keyboard_utils.dart';
import '../../../shared/widgets/custom_button.dart';

// Data class to pass signup information
class SignupData {
  final String email;
  final String fullName;
  final String phoneNumber;
  final UserRole role;
  
  SignupData({
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
  });
}

// Data class for login OTP
class LoginOTPData {
  final String email;
  
  LoginOTPData({required this.email});
}

class OTPVerificationScreen extends StatefulWidget {
  final SignupData? signupData;
  final LoginOTPData? loginData;
  
  const OTPVerificationScreen({
    super.key,
    this.signupData,
    this.loginData,
  }) : assert(signupData != null || loginData != null, 'Either signupData or loginData must be provided');

  bool get isSignup => signupData != null;
  bool get isLogin => loginData != null;
  
  String get email => signupData?.email ?? loginData!.email;

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  final AuthService _authService = AuthService();
  final DeviceService _deviceService = DeviceService();
  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_resendTimer > 0) {
          setState(() => _resendTimer--);
        } else {
          timer.cancel();
        }
      }
    });
  }

  Future<void> _handleVerifyOTP() async {
    final otp = _controllers.map((c) => c.text).join();
    
    if (otp.length != 6) {
      _showError('Please enter the complete 6-digit code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.isSignup) {
        // Signup flow
        final response = await _authService.verifySignupOTP(
          email: widget.signupData!.email,
          token: otp,
          fullName: widget.signupData!.fullName,
          phoneNumber: widget.signupData!.phoneNumber,
          role: widget.signupData!.role,
        );

        if (mounted && response.user != null) {
          // Trust this device for the new user
          await _deviceService.trustDevice(response.user!.id);
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified! Account created successfully.'),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Navigate to address setup
          context.go('/address-setup');
        }
      } else {
        // Login flow
        final response = await _authService.verifyLoginOTP(
          email: widget.loginData!.email,
          token: otp,
        );

        if (mounted && response.user != null) {
          // Trust this device for the user
          await _deviceService.trustDevice(response.user!.id);
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Device verified! Logged in successfully.'),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Get user profile and navigate
          final user = await _authService.getCurrentUserProfile();
          
          if (!mounted) return;
          
          if (user != null) {
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
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      // Clear the OTP fields on error
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
      
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _handleResendOTP() async {
    setState(() => _isResending = true);

    try {
      if (widget.isSignup) {
        await _authService.resendSignupOTP(widget.signupData!.email);
      } else {
        await _authService.resendLoginOTP(widget.loginData!.email);
      }
      
      if (mounted) {
        _showSuccess('New OTP code sent! Check your email.');
        _startResendTimer();
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Verify Email',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => KeyboardUtils.dismissKeyboard(context),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.md),
                
                // Icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.mark_email_read,
                    size: 36,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Title
                Text(
                  widget.isSignup ? 'Verify Your Email' : 'Verify New Device',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.xs),
                
                // Subtitle
                Text(
                  'We sent a 6-digit code to',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  widget.email,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // OTP Input Fields
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate box width based on available space
                    final availableWidth = constraints.maxWidth;
                    final spacing = 6.0;
                    final totalSpacing = spacing * 5; // 5 gaps between 6 boxes
                    final boxWidth = ((availableWidth - totalSpacing - 32) / 6).clamp(40.0, 50.0);
                    
                    return Wrap(
                      alignment: WrapAlignment.center,
                      spacing: spacing,
                      runSpacing: 12,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: boxWidth,
                          height: 55,
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: TextStyle(
                              fontSize: boxWidth * 0.5, // Responsive font size
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              height: 1.2,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: AppTheme.cardWhite,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 4,
                              ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.lightGrey,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.lightGrey,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryGreen,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.errorRed,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          }
                          if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                          
                          // Auto-verify when all 6 digits are entered
                          if (index == 5 && value.isNotEmpty) {
                            KeyboardUtils.dismissKeyboard(context);
                            _handleVerifyOTP();
                          }
                        },
                          ),
                        );
                      }),
                    );
                  },
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Verify Button
                CustomButton(
                  text: 'Verify Code',
                  onPressed: _handleVerifyOTP,
                  isLoading: _isLoading,
                  width: double.infinity,
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Resend OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (_resendTimer > 0)
                      Text(
                        'Resend in ${_resendTimer}s',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _isResending ? null : _handleResendOTP,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        child: _isResending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryGreen,
                                  ),
                                ),
                              )
                            : const Text(
                                'Resend Code',
                                style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Help text
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Check your spam folder if you don\'t see the email. The code expires in 5 minutes.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
