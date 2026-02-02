import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/router/route_names.dart';
import 'farmer_profile_edit_screen.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_widgets.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/widgets/profile_avatar_editor.dart';
import '../../buyer/screens/my_reports_screen.dart';
import '../../../shared/widgets/premium_badge.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  
  UserModel? _user;
  Map<String, dynamic>? _userStats;
  Map<String, dynamic>? _verificationStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await _profileService.getCurrentUserProfile();
      if (user != null && mounted) {
        final stats = await _profileService.getUserStats(user.id, user.role);
        final verification = await _profileService.getFarmerVerificationStatus(user.id);
        setState(() {
          _user = user;
          _userStats = stats;
          _verificationStatus = verification;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  String _getVerificationStatusText() {
    if (_verificationStatus == null) return 'Farmer';
    return _verificationStatus!['message'] ?? 'Farmer';
  }

  IconData _getVerificationIcon() {
    if (_verificationStatus == null) return Icons.person;
    
    final status = _verificationStatus!['status'];
    switch (status) {
      case 'approved':
        return Icons.verified;
      case 'pending':
        return Icons.hourglass_empty;
      case 'rejected':
        return Icons.error;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LoadingWidgets.fullScreenLoader(message: 'Loading profile...');
    }
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Avatar with edit
                                    ProfileAvatarEditor(
                    userId: _user!.id,
                    currentImageUrl: _user?.avatarUrl,
                    onUpdated: _loadUserProfile,
                    radius: 40,
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Farmer Name
                  Text(
                    _user?.fullName ?? 'User',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xs),
                  
                  // Premium Badge
                  if (_user?.isPremium ?? false) ...[
                    PremiumBadge(
                      isPremium: true,
                      size: 16,
                      showLabel: true,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  
                  // Farmer Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getVerificationIcon(),
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _getVerificationStatusText(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Contact Info
                  Text(
                    _user?.email.isNotEmpty == true ? _user!.email : 'No email set',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xs),
                  
                  Text(
                    (() {
                      final primary = _user?.phoneNumber ?? '';
                      final alt = _user?.phone ?? '';
                      final value = primary.isNotEmpty ? primary : alt;
                      return value.isNotEmpty ? value : 'No phone number set';
                    })(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Profile Options
            _buildProfileSection('Account Settings', [
              _buildProfileOption(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                onTap: () async {
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const FarmerProfileEditScreen()),
                  );
                  if (updated == true) {
                    _profileService.clearCache();
                    await _loadUserProfile();
                  }
                },
              ),
              _buildProfileOption(
                icon: Icons.agriculture,
                title: 'Farm Information',
                subtitle: 'Manage your farm details',
                onTap: () {
                  context.push('/farmer/farm-info');
                },
              ),
              _buildProfileOption(
                icon: Icons.verified_user,
                title: 'Verification Status',
                subtitle: 'View your verification documents',
                onTap: () {
                  context.push('/farmer/verification-status');
                },
              ),
            ]),
            
            const SizedBox(height: AppSpacing.lg),
            
            _buildProfileSection('Business', [
              _buildProfileOption(
                icon: Icons.store,
                title: 'Store Customization',
                subtitle: 'Customize your store appearance',
                onTap: () {
                  context.push(RouteNames.storeCustomization);
                },
              ),
              _buildProfileOption(
                icon: Icons.settings_applications,
                title: 'Store Settings',
                subtitle: 'Configure store preferences',
                onTap: () {
                  context.push(RouteNames.storeSettings);
                },
              ),
              _buildProfileOption(
                icon: Icons.location_on,
                title: 'Pickup Settings',
                subtitle: 'Manage pickup locations',
                onTap: () {
                  context.push(RouteNames.pickupSettings);
                },
              ),
              _buildProfileOption(
                icon: Icons.account_balance_wallet,
                title: 'Farmer Wallet',
                subtitle: 'View balance and earnings',
                onTap: () {
                  context.push('/farmer/wallet');
                },
              ),
              _buildProfileOption(
                icon: Icons.payment,
                title: 'Payment Settings',
                subtitle: 'Set up GCash or Bank account',
                onTap: () {
                  context.push('/farmer/payment-settings');
                },
              ),
              _buildProfileOption(
                icon: Icons.money,
                title: 'Request Payout',
                subtitle: 'Withdraw your earnings',
                onTap: () {
                  context.push('/farmer/request-payout');
                },
              ),
              _buildProfileOption(
                icon: Icons.inventory,
                title: 'My Products',
                subtitle: 'Manage your product listings',
                onTap: () {
                  context.push('/farmer/products');
                },
              ),
              _buildProfileOption(
                icon: Icons.analytics,
                title: 'Sales Analytics',
                subtitle: 'View your sales performance',
                onTap: () {
                  context.push('/farmer/analytics');
                },
              ),
              _buildProfileOption(
                icon: Icons.receipt_long,
                title: 'Order History',
                subtitle: 'View all your orders',
                onTap: () {
                  context.push('/farmer/orders');
                },
              ),
              _buildProfileOption(
                icon: Icons.flag_outlined,
                title: 'My Reports',
                subtitle: 'View your submitted reports',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyReportsScreen(),
                  ),
                ),
              ),
            ]),
            
            const SizedBox(height: AppSpacing.lg),
            
            _buildProfileSection('Support & Legal', [
              _buildProfileOption(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help with your account',
                onTap: () {
                  context.push('/farmer/help');
                },
              ),
              _buildProfileOption(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy terms',
                onTap: () {
                  // TODO: Navigate to privacy policy
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy Policy - Coming Soon')),
                  );
                },
              ),
              _buildProfileOption(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                subtitle: 'Read our terms and conditions',
                onTap: () {
                  // TODO: Navigate to terms
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Terms of Service - Coming Soon')),
                  );
                },
              ),
            ]),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Sign Out Button
            CustomButton(
              text: 'Sign Out',
              onPressed: _signOut,
              width: double.infinity,
              backgroundColor: AppTheme.errorRed,
            ),
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md, bottom: AppSpacing.md),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.lightGrey),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    // Get dynamic colors based on icon type
    final colors = _getIconColors(icon);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.lightGrey, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: colors['gradient'] as LinearGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (colors['color'] as Color).withOpacity(0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: colors['color'] as Color,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // Get dynamic colors for icons - SUBTLE & MODERN
  Map<String, dynamic> _getIconColors(IconData icon) {
    // Wallet - Soft Gold/Yellow
    if (icon == Icons.account_balance_wallet) {
      return {
        'color': const Color(0xFFCDA34E),  // Muted gold
        'gradient': LinearGradient(
          colors: [
            const Color(0xFFCDA34E).withOpacity(0.08),
            const Color(0xFFD9B56F).withOpacity(0.08)
          ],
        ),
      };
    }
    // Payment Settings - Soft Blue
    if (icon == Icons.payment) {
      return {
        'color': const Color(0xFF6B8FB3),  // Muted blue
        'gradient': LinearGradient(
          colors: [
            const Color(0xFF6B8FB3).withOpacity(0.08),
            const Color(0xFF7FA3C2).withOpacity(0.08)
          ],
        ),
      };
    }
    // Money/Payout - Soft Green
    if (icon == Icons.money) {
      return {
        'color': const Color(0xFF6B9B7C),  // Muted green
        'gradient': LinearGradient(
          colors: [
            const Color(0xFF6B9B7C).withOpacity(0.08),
            const Color(0xFF7DAC8D).withOpacity(0.08)
          ],
        ),
      };
    }
    // Account icons - Soft Purple
    if (icon == Icons.person_outline) {
      return {
        'color': const Color(0xFF7C7A9C),  // Muted purple
        'gradient': LinearGradient(
          colors: [
            const Color(0xFF7C7A9C).withOpacity(0.08),
            const Color(0xFF9E9EB8).withOpacity(0.08)
          ],
        ),
      };
    }
    // Farm & Agriculture - Soft Green
    if (icon == Icons.agriculture) {
      return {
        'color': const Color(0xFF6B9B7C),  // Muted green
        'gradient': LinearGradient(
          colors: [
            const Color(0xFF6B9B7C).withOpacity(0.08),
            const Color(0xFF7DAC8D).withOpacity(0.08)
          ],
        ),
      };
    }
    // Verification - Subtle Teal
    if (icon == Icons.verified_user) {
      return {
        'color': const Color(0xFF5C9A9A),  // Muted teal
        'gradient': LinearGradient(
          colors: [
            const Color(0xFF5C9A9A).withOpacity(0.08),
            const Color(0xFF6FA8A8).withOpacity(0.08)
          ],
        ),
      };
    }
    // Products/Inventory - Soft Orange
    if (icon == Icons.inventory) {
      return {
        'color': const Color(0xFFCD8866),  // Muted orange
        'gradient': LinearGradient(
          colors: [
            const Color(0xFFCD8866).withOpacity(0.08),
            const Color(0xFFD9A882).withOpacity(0.08)
          ],
        ),
      };
    }
    // Analytics - Soft Purple
    if (icon == Icons.analytics) {
      return {
        'color': const Color(0xFF8C7A9C),  // Muted purple
        'gradient': LinearGradient(
          colors: [
            const Color(0xFF8C7A9C).withOpacity(0.08),
            const Color(0xFF9E8BAC).withOpacity(0.08)
          ],
        ),
      };
    }
    // Orders/Receipts - Soft Blue
    if (icon == Icons.receipt_long) {
      return {
        'color': const Color(0xFF6B8FB3),  // Muted blue
        'gradient': LinearGradient(
          colors: [
            const Color(0xFF6B8FB3).withOpacity(0.08),
            const Color(0xFF7FA3C2).withOpacity(0.08)
          ],
        ),
      };
    }
    // Help & Support - Soft Blue
    if (icon == Icons.help_outline) {
      return {
        'color': const Color(0xFF6B8FB3),  // Muted blue
        'gradient': LinearGradient(
          colors: [
            const Color(0xFF6B8FB3).withOpacity(0.08),
            const Color(0xFF7FA3C2).withOpacity(0.08)
          ],
        ),
      };
    }
    // Legal - Soft Grey
    if (icon == Icons.privacy_tip_outlined || icon == Icons.description_outlined) {
      return {
        'color': const Color(0xFF7A7A7A),  // Muted grey
        'gradient': LinearGradient(
          colors: [
            const Color(0xFF7A7A7A).withOpacity(0.08),
            const Color(0xFF919191).withOpacity(0.08)
          ],
        ),
      };
    }
    // Reports - Soft Red/Orange
    if (icon == Icons.flag_outlined) {
      return {
        'color': const Color(0xFFCD7A6B),  // Muted red-orange
        'gradient': LinearGradient(
          colors: [
            const Color(0xFFCD7A6B).withOpacity(0.08),
            const Color(0xFFD99082).withOpacity(0.08)
          ],
        ),
      };
    }
    // Default - Soft Green
    return {
      'color': const Color(0xFF6B9B7C),
      'gradient': LinearGradient(
        colors: [
          const Color(0xFF6B9B7C).withOpacity(0.08),
          const Color(0xFF7DAC8D).withOpacity(0.08)
        ],
      ),
    };
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }
}