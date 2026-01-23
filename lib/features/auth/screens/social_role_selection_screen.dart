import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user_model.dart';
import '../../../shared/widgets/custom_button.dart';

class SocialRoleSelectionScreen extends StatefulWidget {
  const SocialRoleSelectionScreen({super.key});

  @override
  State<SocialRoleSelectionScreen> createState() => _SocialRoleSelectionScreenState();
}

class _SocialRoleSelectionScreenState extends State<SocialRoleSelectionScreen> {
  final AuthService _authService = AuthService();
  UserRole? _selectedRole;
  bool _isLoading = false;

  Future<void> _handleRoleSelection() async {
    if (_selectedRole == null) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Complete the social user profile with selected role
      final updatedUser = await _authService.completeSocialUserProfile(
        userId: currentUser.id,
        role: _selectedRole!,
      );

      if (mounted) {
        // Navigate to address setup since social users need to complete their address
        context.go(RouteNames.addressSetup);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set up account: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Complete Setup',
          style: AppTextStyles.heading2,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              
              // Welcome message
              const Text(
                'Welcome to AgrLink!',
                style: AppTextStyles.heading1,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'To complete your account setup, please select your role:',
                style: AppTextStyles.bodyMedium,
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Buyer option
              _RoleCard(
                title: 'I want to buy fresh products',
                subtitle: 'Browse and purchase fresh agricultural products from verified local farmers',
                icon: Icons.shopping_basket_outlined,
                color: AppTheme.primaryGreen,
                isSelected: _selectedRole == UserRole.buyer,
                onTap: () {
                  setState(() {
                    _selectedRole = UserRole.buyer;
                  });
                },
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Farmer option
              _RoleCard(
                title: 'I want to sell my farm products',
                subtitle: 'List and sell your agricultural products directly to local buyers',
                icon: Icons.agriculture_outlined,
                color: AppTheme.accentGreen,
                isSelected: _selectedRole == UserRole.farmer,
                onTap: () {
                  setState(() {
                    _selectedRole = UserRole.farmer;
                  });
                },
              ),
              
              const Spacer(),
              
              // Continue button
              CustomButton(
                text: 'Continue',
                type: ButtonType.primary,
                isFullWidth: true,
                isLoading: _isLoading,
                onPressed: _selectedRole != null ? _handleRoleSelection : null,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Note about verification
              if (_selectedRole == UserRole.farmer)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.accentGreen,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'As a farmer, you\'ll need to complete verification before you can start selling.',
                          style: TextStyle(
                            color: AppTheme.accentGreen,
                            fontSize: 13,
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
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        side: BorderSide(
          color: isSelected ? color : color.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            color: isSelected ? color.withValues(alpha: 0.05) : Colors.transparent,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isSelected ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.heading3.copyWith(
                          color: color,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
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