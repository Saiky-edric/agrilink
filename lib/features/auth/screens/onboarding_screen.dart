import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/widgets/custom_button.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      title: 'Fresh Farm Products',
      description: 'Discover fresh, locally-grown agricultural products directly from verified farmers in Agusan del Sur.',
      lottieAsset: 'assets/lottie/onboarding_fresh_products.json',
    ),
    OnboardingData(
      title: 'Verified Farmers',
      description: 'Shop with confidence knowing all farmers are verified through our strict verification process.',
      lottieAsset: 'assets/lottie/onboarding_verified_farmers.json',
    ),
    OnboardingData(
      title: 'Real-time Chat',
      description: 'Connect directly with farmers, ask questions, and get fresh product updates through our chat feature.',
      lottieAsset: 'assets/lottie/onboarding_chat.json',
    ),
    OnboardingData(
      title: 'Safe & Convenient',
      description: 'Enjoy secure Cash on Delivery payments and track your orders from farm to your doorstep.',
      lottieAsset: 'assets/lottie/onboarding_secure_checkout.json',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextButton(
                  onPressed: () => context.go(RouteNames.login),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_onboardingData[index]);
                },
              ),
            ),
            
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _onboardingData.asMap().entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == entry.key
                        ? AppTheme.primaryGreen
                        : AppTheme.lightGrey,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: CustomButton(
                        text: 'Previous',
                        type: ButtonType.outline,
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  
                  if (_currentPage > 0) const SizedBox(width: AppSpacing.md),
                  
                  Expanded(
                    child: CustomButton(
                      text: _currentPage == _onboardingData.length - 1
                          ? 'Get Started'
                          : 'Next',
                      type: ButtonType.primary,
                      onPressed: () {
                        if (_currentPage == _onboardingData.length - 1) {
                          context.go(RouteNames.login);
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingData data) {
    // Check if this is the verified farmers screen
    final isVerifiedFarmersScreen = data.lottieAsset.contains('onboarding_verified_farmers');
    
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: Transform.scale(
                scale: isVerifiedFarmersScreen ? 1.5 : 1.0, // Make verified farmers 50% bigger
                child: SizedBox(
                  width: double.infinity,
                  child: Lottie.asset(
                    data.lottieAsset,
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
              ),
            ),
          ),
          
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                
                Text(
                  data.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String lottieAsset;

  OnboardingData({
    required this.title,
    required this.description,
    required this.lottieAsset,
  });
}