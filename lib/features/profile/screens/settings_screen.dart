import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info moved to Buyer Profile: Delivery & Transactions
            // Container(
            /*
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.lightGrey),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Delivery & Fees', style: AppTextStyles.heading3),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Delivery fees are calculated by weight using J&T Express local rates. '
                    'Orders up to 8kg use flat tiers (₱70 ≤3kg, ₱120 ≤5kg, ₱160 ≤8kg). '
                    'Above 8kg, an increment per 2kg applies.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'You will see the exact delivery fee at checkout before placing your order. '
                    'Product prices are set by each farmer. Farmers keep 100% of product sales. Platform revenue comes from premium subscriptions.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),*/

            const SizedBox(height: AppSpacing.xl),

            const Text(
              'Notifications',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.lightGrey),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive order updates and promotions'),
                    value: _pushNotifications,
                    onChanged: (value) {
                      setState(() => _pushNotifications = value);
                    },
                    activeThumbColor: AppTheme.primaryGreen,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    title: const Text('Email Notifications'),
                    subtitle: const Text('Receive newsletters and updates'),
                    value: _emailNotifications,
                    onChanged: (value) {
                      setState(() => _emailNotifications = value);
                    },
                    activeThumbColor: AppTheme.primaryGreen,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            const Text(
              'Appearance',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.lightGrey),
              ),
              child: Consumer<ThemeService>(
                builder: (context, themeService, child) {
                  return SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: Text(themeService.isLoading 
                        ? 'Loading...' 
                        : 'Switch to ${themeService.isDarkMode ? 'light' : 'dark'} theme'
                    ),
                    value: themeService.isDarkMode,
                    onChanged: themeService.isLoading 
                        ? null 
                        : (value) async {
                            if (value) {
                              await themeService.setDarkTheme();
                            } else {
                              await themeService.setLightTheme();
                            }
                            
                            // Show feedback
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Switched to ${value ? 'dark' : 'light'} mode'
                                  ),
                                  backgroundColor: AppTheme.primaryGreen,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                    activeThumbColor: AppTheme.primaryGreen,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}