import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryGreen),
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('PRIVACY_POLICY.md'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryGreen,
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(context);
          }

          final content = snapshot.data ?? _getHardcodedPrivacy();
          return _buildContent(context, content);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, String content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.privacy_tip,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your privacy is important to us',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Content - Clean markdown formatting
          Text(
            _cleanMarkdown(content),
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppTheme.textPrimary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Data Protection Summary
          _buildDataProtectionSummary(),
          
          const SizedBox(height: 24),
          
          // Contact Section
          _buildContactSection(),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDataProtectionSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Your Data Protection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCheckItem('We encrypt your data'),
          _buildCheckItem('We don\'t sell your information'),
          _buildCheckItem('You can delete your data anytime'),
          _buildCheckItem('Compliant with Philippine Data Privacy Act'),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_support, color: AppTheme.primaryGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.email_outlined, size: 16, color: AppTheme.textSecondary),
              SizedBox(width: 8),
              Text(
                'privacy@agrilink.ph',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.support_agent, size: 16, color: AppTheme.textSecondary),
              SizedBox(width: 8),
              Text(
                'support@agrilink.ph',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to clean markdown formatting for plain text display
  String _cleanMarkdown(String markdown) {
    String cleaned = markdown;
    
    // Remove markdown headers (# ## ###)
    cleaned = cleaned.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    
    // Remove bold/italic markers (** __ * _)
    cleaned = cleaned.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'__(.+?)__'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'\*(.+?)\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'_(.+?)_'), r'$1');
    
    // Remove links but keep the text [text](url) -> text
    cleaned = cleaned.replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1');
    
    // Remove code blocks markers (```)
    cleaned = cleaned.replaceAll(RegExp(r'```[a-z]*\n?', multiLine: true), '');
    
    // Remove inline code markers (`)
    cleaned = cleaned.replaceAll(RegExp(r'`([^`]+)`'), r'$1');
    
    // Remove horizontal rules (---)
    cleaned = cleaned.replaceAll(RegExp(r'^---+$', multiLine: true), '');
    
    // Clean up excessive newlines (more than 2)
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    return cleaned.trim();
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorRed,
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to load Privacy Policy',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  String _getHardcodedPrivacy() {
    return '''
# Privacy Policy

Effective Date: February 2, 2026
Last Updated: February 2, 2026

## Introduction

Welcome to Agrilink. We are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, store, share, and protect your data when you use our mobile application.

Agrilink is a digital marketplace platform connecting farmers in Agusan del Sur, Philippines, with local buyers for the purchase and sale of fresh agricultural products.

By using Agrilink, you agree to the collection and use of information in accordance with this Privacy Policy.

## 1. Information We Collect

We collect various types of information to provide and improve our services.

Personal Information You Provide:
- Account Registration: Full Name, Email Address, Phone Number, Password (encrypted), User Role, Address Information, Profile Photo
- For Farmers: Government-Issued ID, Proof of Farming Activity, Verification Selfie, Farm Information, Store Customization
- Payment Information: GCash Mobile Number and Account Name, Bank Account Details, Payment Proof Screenshots
- Transaction Information: Product Listings, Order Details, Transaction History, Delivery Addresses
- Communication Data: Chat Messages, Support Chat Messages, Notifications, Reviews and Ratings, Reports

Information Collected Automatically:
- Device Information: Device type, model, operating system, unique identifiers, mobile network information, app version
- Usage Data: Pages and screens viewed, features used, search queries, product views, order history
- Location Data: GPS Coordinates (with permission for distance calculation, geocoding, map integration), IP Address
- Log Data: Access times, error logs, crash reports, performance metrics

Information from Third-Party Services:
- Social Media Authentication: Google Sign-In and Facebook Login (name, email, profile photo)
- Payment Services: GCash transaction confirmations and payment status
- Map Services: OpenStreetMap map tiles and geocoding data

## 2. How We Use Your Information

Platform Operation:
- Create, maintain, and authenticate user accounts
- Process orders, payments, and payouts
- Verify farmer identities to prevent fraud
- Enable chat between buyers and farmers
- Send order updates, payment confirmations, and important alerts

Service Improvement:
- Understand usage patterns and improve features
- Develop new features based on user needs
- Identify and resolve technical issues
- Improve app speed and reliability

Security and Fraud Prevention:
- Monitor transactions for suspicious activity
- Protect accounts from unauthorized access
- Investigate and resolve user disputes
- Review reports and remove inappropriate content

Marketing and Promotion:
- Inform farmers about subscription benefits
- Notify users of new features
- Send updates about platform improvements
- You can opt-out of marketing communications in app settings

Legal Compliance:
- Comply with Philippine laws and regulations
- Respond to valid legal requests
- Enforce our Terms of Service
- Maintain records as required by law

## 3. How We Share Your Information

We do not sell your personal information to third parties. We share your information only in specific circumstances:

With Other Users:
- Buyers can see: Store name, profile photo, verification badge, store description, farm information, product listings, reviews, general location (municipality level)
- Farmers can see: Buyer name, profile photo, delivery address (for accepted orders), phone number, order details
- Chat messages are visible to both parties in the conversation

With Service Providers:
- Supabase (backend services, database, authentication, storage)
- Map Services (location and geocoding)
- Payment Processors (GCash transaction verification)
- Cloud Storage (image and file hosting)
- Analytics Tools (usage analytics and crash reporting)

These providers are contractually obligated to protect your data and use it only for providing services to us.

For Legal Reasons:
- Comply with laws, regulations, or legal processes
- Respond to government or law enforcement requests
- Enforce our Terms of Service or Privacy Policy
- Protect rights, property, or safety of Agrilink, users, or the public
- Prevent fraud, illegal activity, or security threats

Business Transfers:
- If Agrilink is involved in a merger, acquisition, or sale of assets, your information may be transferred. You will be notified via email or in-app notice.

With Your Consent:
- We may share your information for other purposes with your explicit consent

## 4. Data Storage and Security

Where We Store Data:
- Primary Storage: Supabase cloud infrastructure (secure servers)
- Location: Data may be stored in servers outside the Philippines but protected by international data protection standards
- Backup: Regular backups maintained for data recovery

Security Measures:
- Encryption: Data encrypted in transit (HTTPS/TLS) and at rest
- Password Protection: Passwords hashed and salted (not stored in plain text)
- Access Controls: Role-based access to sensitive data
- Secure Authentication: Supabase Auth with best practices
- Row-Level Security: Database policies restrict data access
- Regular Audits: Security audits and vulnerability assessments
- Staff Training: Team trained on data protection practices
- Monitoring: Continuous monitoring for suspicious activity

Data Retention:
- Active Accounts: Data retained as long as your account is active
- Deleted Accounts: Most data deleted within 30 days. Some data retained for legal compliance (Transaction records: 7 years, Verification documents: 5 years, Dispute chat logs: 3 years)
- Backups: Backup data may persist for up to 90 days after deletion

Security Limitations:
- No system is 100% secure. While we use reasonable measures to protect your data, we cannot guarantee absolute security
- You are responsible for keeping your password secure, not sharing credentials, logging out on shared devices, and reporting suspicious activity

## 5. Your Rights and Choices

Access and Portability:
- View your profile, orders, and transaction history in the app
- Request a copy of your data (contact support@agrilink.ph)

Correction and Update:
- Update your name, email, phone, address, and profile photo
- Request correction of inaccurate information

Deletion:
- Delete your account and associated data through app settings
- Note: Some data may be retained for legal and compliance reasons

Withdrawal of Consent:
- Disable GPS access in device settings (may limit functionality)
- Disable push notifications in app settings
- Opt-out of promotional emails (unsubscribe link provided)

Complaint Rights:
- File a complaint with the National Privacy Commission of the Philippines at www.privacy.gov.ph or info@privacy.gov.ph

## 6. Children's Privacy

Agrilink is not intended for users under 18 years of age. We do not knowingly collect personal information from children under 18. If we discover that a child under 18 has provided information, we will delete it immediately. Contact us at support@agrilink.ph if you believe a child has provided information.

## 7. Philippine Data Privacy Act Compliance

Agrilink complies with the Data Privacy Act of 2012 (Republic Act No. 10173) and all implementing rules and regulations issued by the National Privacy Commission of the Philippines.

Your Rights: Right to be informed, access, object, erasure or blocking, damages, file a complaint, rectification, and data portability.

For more information: www.privacy.gov.ph

## 8. Contact Us

General Inquiries:
Email: support@agrilink.ph
In-App: AI Support Chat
Website: www.agrilink.ph

Data Protection Officer:
Email: privacy@agrilink.ph
Address: Agusan del Sur, Philippines

National Privacy Commission:
Website: www.privacy.gov.ph
Email: info@privacy.gov.ph
Phone: (+632) 8234-2228

## 9. Consent and Acknowledgment

By using Agrilink, you consent to the collection, use, and sharing of your information as described in this Privacy Policy, the transfer of your data to servers outside the Philippines, and the use of cookies and similar tracking technologies.

You can withdraw consent at any time by deleting your account, disabling specific permissions in device settings, or contacting us to request data deletion.

By creating an account and using Agrilink, you acknowledge that you have read, understood, and agree to this Privacy Policy.

Thank you for trusting Agrilink with your information. We are committed to protecting your privacy.

---

Last Updated: February 2, 2026
Version: 1.0
''';
  }
}
