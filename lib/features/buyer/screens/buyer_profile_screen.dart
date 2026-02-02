import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/profile_service.dart';

import '../../../shared/widgets/profile_avatar_editor.dart';
import '../../../core/services/address_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/address_model.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_widgets.dart';
import '../../../shared/widgets/modern_bottom_nav.dart';
import 'my_reports_screen.dart';
import '../../auth/screens/privacy_policy_screen.dart';
import '../../auth/screens/terms_of_service_screen.dart';
class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({super.key});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> {
  
  

  final ProfileService _profileService = ProfileService();
  // Services will be initialized properly
  // final ReviewService _reviewService = ReviewService();
  // final FarmerProfileService _farmerService = FarmerProfileService();
  final AuthService _authService = AuthService();
  
  // Temporary removal of undefined types
  // List<PendingReview> _pendingReviews = [];
  // List<FollowedStore> _followedStores = [];
  final bool _loadingExtras = false;
  final AddressService _addressService = AddressService();
  
  UserModel? _user;
  Map<String, dynamic>? _userStats;
  AddressModel? _defaultAddress;
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
        final defaultAddress = await _addressService.getDefaultAddress(user.id);
        
        setState(() {
          _user = user;
          _userStats = stats;
          _defaultAddress = defaultAddress;
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

  String _getAddressSubtitle() {
    if (_defaultAddress != null) {
      return 'Default: ${_defaultAddress!.name} • ${_defaultAddress!.municipality}';
    }
    return 'Add and manage your delivery locations';
  }

  String _getUserStatusText() {
    if (_userStats == null) return 'Customer';
    
    final totalOrders = _userStats!['total_orders'] ?? 0;
    final totalSpent = _userStats!['total_spent'] ?? 0.0;
    
    if (totalOrders >= 10 && totalSpent >= 5000) {
      return 'VIP Customer';
    } else if (totalOrders >= 5 && totalSpent >= 2000) {
      return 'Valued Customer';
    } else if (totalOrders > 0) {
      return 'Active Customer';
    } else {
      return 'New Customer';
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
                  
                  // Buyer Name
                  Text(
                    _user?.fullName ?? 'User',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xs),
                  
                  // Buyer Status
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
                          Icons.shopping_bag,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _getUserStatusText(),
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
                  
                  // Contact Info - Real Data
                  Text(
                    _user?.email ?? 'No email',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xs),
                  
                  Text(
                    _user?.phoneNumber ?? 'No phone number',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  
                  if (_defaultAddress != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _defaultAddress!.fullAddress,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Profile Options
            _buildProfileSection('Account', [
              _buildProfileOption(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                onTap: () => _showEditProfileDialog(),
              ),
              _buildProfileOption(
                icon: Icons.location_on_outlined,
                title: 'Delivery Addresses',
                subtitle: _getAddressSubtitle(),
                onTap: () => context.push(RouteNames.addresses),
              ),
              _buildProfileOption(
                icon: Icons.payment_outlined,
                title: 'Payment Methods',
                subtitle: 'Manage your payment options',
                onTap: () => _showPaymentMethodsDialog(),
              ),
            ]),
            
            const SizedBox(height: AppSpacing.lg),
            
            _buildProfileSection('Shopping', [
              _buildProfileOption(
                icon: Icons.storefront_outlined,
                title: 'Followed Farmer Stores',
                subtitle: 'See the farmers you follow',
                onTap: () => context.push(RouteNames.followedStores),
              ),
              _buildProfileOption(
                icon: Icons.shopping_bag_outlined,
                title: 'Order History',
                subtitle: 'View your past orders',
                onTap: () => context.push(RouteNames.buyerOrders),
              ),
              _buildProfileOption(
                icon: Icons.payment_outlined,
                title: 'Payment History',
                subtitle: 'Track your spending and payments',
                onTap: () => context.push(RouteNames.paymentHistory),
              ),
              _buildProfileOption(
                icon: Icons.receipt_long_outlined,
                title: 'Transaction History',
                subtitle: 'View all payment transactions & refunds',
                onTap: () => context.push(RouteNames.transactionHistory),
              ),
              _buildProfileOption(
                icon: Icons.favorite_outline,
                title: 'Wishlist',
                subtitle: 'Your favorite products',
                onTap: () => context.push(RouteNames.wishlist),
              ),
              _buildProfileOption(
                icon: Icons.star_outline,
                title: 'Reviews',
                subtitle: 'Your product reviews',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reviews - Coming Soon')),
                  );
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
            
            _buildProfileSection('Support', [
             _buildProfileOption(
               icon: Icons.info_outline,
               title: 'Delivery & Fees Info',
               subtitle: 'How delivery fees and transactions work',
               onTap: () => _showDeliveryFeesInfoDialog(),
             ),
              _buildProfileOption(
                icon: Icons.settings_outlined,
                title: 'App Settings',
                subtitle: 'Notifications, privacy, and more',
                onTap: () => context.push(RouteNames.settings),
              ),
              _buildProfileOption(
                icon: Icons.help_outline,
                title: 'Help Center',
                subtitle: 'Get help with your orders',
                onTap: () => _showHelpDialog(),
              ),
              _buildProfileOption(
                icon: Icons.chat_outlined,
                title: 'Contact Support',
                subtitle: 'Talk to our support team',
                onTap: () => _showContactSupportDialog(),
              ),
              _buildProfileOption(
                icon: Icons.feedback_outlined,
                title: 'Send Feedback',
                subtitle: 'Share your thoughts with us',
                onTap: () => _showFeedbackDialog(),
              ),
            ]),
            
            const SizedBox(height: AppSpacing.lg),
            
            _buildProfileSection('Legal', [
              _buildProfileOption(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy terms',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
              ),
              _buildProfileOption(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                subtitle: 'Read our terms and conditions',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsOfServiceScreen(),
                    ),
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
      bottomNavigationBar: const ModernBottomNav(currentIndex: 4),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    // Account icons - Soft Purple
    if (icon == Icons.person_outline || icon == Icons.location_on_outlined) {
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
    // Payment - Subtle Teal
    if (icon == Icons.payment_outlined) {
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
    // Shopping - Soft Orange
    if (icon == Icons.storefront_outlined || icon == Icons.shopping_bag_outlined) {
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
    // Favorites - Soft Rose
    if (icon == Icons.favorite_outline) {
      return {
        'color': const Color(0xFFB8818C),  // Muted rose
        'gradient': LinearGradient(
          colors: [
            const Color(0xFFB8818C).withOpacity(0.08),
            const Color(0xFFC99AA3).withOpacity(0.08)
          ],
        ),
      };
    }
    // Reviews - Soft Gold
    if (icon == Icons.star_outline) {
      return {
        'color': const Color(0xFFCBA868),  // Muted gold
        'gradient': LinearGradient(
          colors: [
            const Color(0xFFCBA868).withOpacity(0.08),
            const Color(0xFFD4B981).withOpacity(0.08)
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
    // Info/Support - Soft Blue
    if (icon == Icons.info_outline || icon == Icons.settings_outlined || 
        icon == Icons.help_outline || icon == Icons.chat_outlined) {
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
    // Feedback - Soft Green
    if (icon == Icons.feedback_outlined) {
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

  // Edit Profile Dialog
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _user?.fullName ?? '');
    final phoneController = TextEditingController(text: _user?.phoneNumber ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        contentPadding: const EdgeInsets.all(24),
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: () async {
              try {
                final updatedUser = _user!.copyWith(
                  fullName: nameController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                );
                
                final success = await _profileService.updateProfile(updatedUser);
                
                if (success && mounted) {
                  setState(() {
                    _user = updatedUser;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                } else {
                  throw Exception('Update failed');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating profile: $e'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Payment Methods Dialog
  void _showPaymentMethodsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Methods'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.credit_card, size: 64, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text(
              'Payment methods feature coming soon!\n\nYou will be able to add and manage your credit cards, debit cards, and other payment options.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Favorites Dialog
  void _showFavoritesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Favorites'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, size: 64, color: AppTheme.primaryGreen),
            SizedBox(height: 16),
            Text(
              'Your favorite products will appear here!\nTap the heart on any product to add/remove it.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(RouteNames.buyerHome);
            },
            child: const Text('Browse Products'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Delivery & Fees Info Dialog
  void _showDeliveryFeesInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delivery & Fees'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How delivery fees are calculated', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text(
                'Delivery fees are calculated by weight.\n'
                'Up to 8 kg: \n  • ₱70 (≤3 kg) \n  • ₱120 (≤5 kg) \n  • ₱160 (≤8 kg)\n'
                'Above 8 kg: an additional fee is applied for every 2 kg.',
              ),
              SizedBox(height: 16),
              Text('When do I see the fee?', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('You will see the exact delivery fee at checkout before placing your order.'),
              SizedBox(height: 16),
              Text('Who sets the product price?', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('Product prices are set by each farmer. Farmers keep 100% of product sales. Platform revenue comes from premium subscriptions.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Help Dialog
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help Center'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Frequently Asked Questions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('• How do I place an order?'),
              const Text('• How do I track my delivery?'),
              const Text('• How do I contact a farmer?'),
              const Text('• What payment methods are accepted?'),
              const Text('• How do I return a product?'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(RouteNames.chatInbox);
                },
                icon: const Icon(Icons.chat),
                label: const Text('Contact Support'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Contact Support Dialog
  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent, size: 64, color: AppTheme.primaryGreen),
            SizedBox(height: 16),
            Text(
              'Need help? Our support team is here for you!\n\nEmail: support@agrilink.ph\nPhone: +63 917 123 4567\n\nOr use our chat feature to get instant help.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(RouteNames.chatInbox);
            },
            child: const Text('Open Chat'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Feedback Dialog
  void _showFeedbackDialog() {
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        contentPadding: const EdgeInsets.all(24),
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('We value your feedback! Help us improve AgriLink.'),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Tell us what you think...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: () {
                    if (feedbackController.text.trim().isNotEmpty) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thank you for your feedback!'),
                          backgroundColor: AppTheme.successGreen,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Send',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Privacy Policy Dialog
  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'AgriLink Privacy Policy\n\n'
            '1. Information Collection\n'
            'We collect information to provide better services to all our users.\n\n'
            '2. Information Usage\n'
            'We use the information we collect to maintain and improve our services.\n\n'
            '3. Data Protection\n'
            'We implement appropriate security measures to protect your personal information.\n\n'
            '4. Contact Information\n'
            'If you have questions about this Privacy Policy, please contact us at privacy@agrilink.ph',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Terms of Service Dialog
  void _showTermsOfServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'AgriLink Terms of Service\n\n'
            '1. Acceptance of Terms\n'
            'By using AgriLink, you agree to these terms.\n\n'
            '2. Service Description\n'
            'AgriLink connects local farmers with buyers for fresh produce.\n\n'
            '3. User Responsibilities\n'
            'Users must provide accurate information and use the service responsibly.\n\n'
            '4. Payment Terms\n'
            'All transactions are subject to our payment processing terms.\n\n'
            '5. Contact\n'
            'For questions, contact us at legal@agrilink.ph',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}