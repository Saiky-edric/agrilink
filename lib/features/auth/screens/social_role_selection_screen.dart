import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user_model.dart';

class SocialRoleSelectionScreen extends StatefulWidget {
  const SocialRoleSelectionScreen({super.key});

  @override
  State<SocialRoleSelectionScreen> createState() => _SocialRoleSelectionScreenState();
}

class _SocialRoleSelectionScreenState extends State<SocialRoleSelectionScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleRoleSelection(UserRole role) async {
    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Complete the social user profile with selected role
      await _authService.completeSocialUserProfile(
        userId: currentUser.id,
        role: role,
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
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _isLoading ? null : () => context.pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  
                  SizedBox(height: screenHeight * 0.02),
                  
                  // Title
                  const Text(
                    'Join Agrilink',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your account type',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  SizedBox(height: screenHeight * 0.04),
                  
                  // Buyer Card
                  _CleanRoleCard(
                    title: 'Buyer',
                    description: 'Browse and purchase fresh products from local farmers',
                    icon: Icons.shopping_cart_outlined,
                    color: AppTheme.primaryGreen,
                    isLoading: _isLoading,
                    onTap: () => _handleRoleSelection(UserRole.buyer),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Farmer Card
                  _CleanRoleCard(
                    title: 'Farmer',
                    description: 'Sell your agricultural products to local buyers',
                    icon: Icons.agriculture_outlined,
                    color: const Color(0xFF2E7D32),
                    isLoading: _isLoading,
                    onTap: () => _handleRoleSelection(UserRole.farmer),
                  ),
                ],
              ),
            ),
            
            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CleanRoleCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _CleanRoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_CleanRoleCard> createState() => _CleanRoleCardState();
}

class _CleanRoleCardState extends State<_CleanRoleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) => setState(() => _isHovered = true),
      onTapUp: widget.isLoading ? null : (_) {
        setState(() => _isHovered = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovered ? widget.color.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? widget.color : Colors.grey[300]!,
            width: _isHovered ? 2 : 1.5,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.icon,
                color: widget.color,
                size: 28,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: widget.color,
            ),
          ],
        ),
      ),
    );
  }
}