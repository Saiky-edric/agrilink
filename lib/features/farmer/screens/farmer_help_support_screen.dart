import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_button.dart';

class FarmerHelpSupportScreen extends StatelessWidget {
  const FarmerHelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 48,
                    color: Colors.white,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'We\'re Here to Help',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Get support for your farming business',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            _buildQuickActionCard(
              icon: Icons.chat,
              title: 'AI Support Assistant',
              subtitle: 'Get instant answers to your questions',
              color: AppTheme.primaryGreen,
              onTap: () => context.push('/farmer/support-chat'),
            ),

            const SizedBox(height: AppSpacing.sm),

            _buildQuickActionCard(
              icon: Icons.phone,
              title: 'Call Support',
              subtitle: '+63 (2) 8888-AGRI (2474)',
              color: AppTheme.infoBlue,
              onTap: () => _showCallDialog(context),
            ),

            const SizedBox(height: AppSpacing.sm),

            _buildQuickActionCard(
              icon: Icons.email,
              title: 'Email Support',
              subtitle: 'farmer-support@agrilink.ph',
              color: AppTheme.warningOrange,
              onTap: () => _showEmailDialog(context),
            ),

            const SizedBox(height: AppSpacing.xl),

            // FAQ Section
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            _buildFAQSection(),

            const SizedBox(height: AppSpacing.xl),

            // Guides Section
            const Text(
              'Helpful Guides',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            _buildGuidesSection(context),

            const SizedBox(height: AppSpacing.xl),

            // Contact Info
            _buildContactInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.lightGrey),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
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
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final faqs = [
      {
        'question': 'How do I add products to my store?',
        'answer': 'Go to Products > Add Product and fill in the required information including photos, description, and pricing.',
      },
      {
        'question': 'How long does verification take?',
        'answer': 'Farmer verification typically takes 2-3 business days. You\'ll receive an email notification once approved.',
      },
      {
        'question': 'How do I manage my orders?',
        'answer': 'Visit the Orders section to view, confirm, and update order statuses. You can also communicate with buyers directly.',
      },
      {
        'question': 'What payment methods are supported?',
        'answer': 'We support bank transfers, GCash, PayMaya, and cash on delivery for your convenience.',
      },
      {
        'question': 'How do I update my farm information?',
        'answer': 'Go to Profile > Farm Information to update your crops, farming methods, and other details.',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGrey),
      ),
      child: Column(
        children: faqs.map((faq) => _buildFAQItem(faq['question']!, faq['answer']!)).toList(),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuidesSection(BuildContext context) {
    final guides = [
      {
        'title': 'Getting Started Guide',
        'description': 'Learn the basics of using Agrilink',
        'icon': Icons.play_circle,
        'color': AppTheme.primaryGreen,
      },
      {
        'title': 'Product Photography Tips',
        'description': 'Take better photos of your products',
        'icon': Icons.camera_alt,
        'color': AppTheme.secondaryGreen,
      },
      {
        'title': 'Pricing Your Products',
        'description': 'Set competitive prices for your crops',
        'icon': Icons.attach_money,
        'color': AppTheme.warningOrange,
      },
      {
        'title': 'Order Management',
        'description': 'Handle orders efficiently',
        'icon': Icons.inventory_2,
        'color': AppTheme.infoBlue,
      },
    ];

    return Column(
      children: guides.map((guide) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: InkWell(
            onTap: () => _showGuideDialog(context, guide['title'] as String),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.lightGrey),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (guide['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      guide['icon'] as IconData,
                      color: guide['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guide['title'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          guide['description'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Still Need Help?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Our support team is available Monday to Friday, 8:00 AM to 6:00 PM (Philippine Time)',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomButton(
            text: 'Contact Support Team',
            onPressed: () => _showContactOptions(),
            width: double.infinity,
          ),
        ],
      ),
    );
  }


  void _showCallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Support'),
        content: const Text('Call us at +63 (2) 8888-AGRI (2474)\n\nAvailable Monday to Friday\n8:00 AM to 6:00 PM (Philippine Time)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement phone call
            },
            child: const Text('Call Now'),
          ),
        ],
      ),
    );
  }

  void _showEmailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Support'),
        content: const Text('Send us an email at:\nfarmer-support@agrilink.ph\n\nWe typically respond within 24 hours.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement email compose
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  void _showGuideDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('This guide will be available soon. Check back for detailed tutorials and tips.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showContactOptions() {
    // TODO: Implement contact options bottom sheet
  }
}