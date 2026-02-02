import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
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
        future: rootBundle.loadString('TERMS_OF_SERVICE.md'),
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

          final content = snapshot.data ?? _getHardcodedTerms();
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
                    Icons.description,
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
                        'Terms of Service',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Effective Date: February 2, 2026',
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
          
          // Contact Section
          _buildContactSection(),
          
          const SizedBox(height: 24),
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
              Icon(Icons.help_outline, color: AppTheme.primaryGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Questions?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'If you have questions about these Terms, please contact us:',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.email_outlined, size: 16, color: AppTheme.textSecondary),
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
            'Unable to load Terms of Service',
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

  String _getHardcodedTerms() {
    return '''
# Terms of Service

Effective Date: February 2, 2026
Last Updated: February 2, 2026

## 1. Agreement to Terms

By accessing or using the Agrilink mobile application, you agree to be bound by these Terms of Service. If you do not agree to these Terms, please do not use the App.

Agrilink is a digital marketplace platform connecting farmers in Agusan del Sur, Philippines, with local buyers for the purchase and sale of fresh agricultural products.

## 2. Definitions

- "We," "Us," "Our" refers to Agrilink and its operators
- "User," "You," "Your" refers to any person using the App
- "Farmer" refers to verified sellers offering agricultural products
- "Buyer" refers to users purchasing agricultural products
- "Product" refers to agricultural items listed for sale
- "Order" refers to a purchase transaction between Buyer and Farmer

## 3. Eligibility

You must be at least 18 years old to use Agrilink. By using the App, you represent and warrant that you are of legal age to form a binding contract.

You agree to provide accurate, current, and complete information during registration and to update such information to keep it accurate and current.

You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.

## 4. User Roles and Responsibilities

Farmers:

Verification Requirement:
- All Farmers must complete identity verification by submitting valid government-issued ID, proof of farming activity, and verification selfie
- Unverified Farmers cannot accept orders or request payouts

Product Listing Obligations:
- List only genuine agricultural products you legally own or have the right to sell
- Provide accurate product descriptions, prices, quantities, and photos
- Maintain accurate inventory and promptly update stock availability
- Set realistic shelf-life information for perishable goods
- Honor all accepted orders unless circumstances beyond your control prevent fulfillment

Order Fulfillment:
- Accept or reject orders within a reasonable timeframe
- Prepare products according to quality standards described in listings
- Fulfill delivery or pickup arrangements as agreed
- Update order status promptly throughout the fulfillment process

Product Limits:
- Free Tier: Maximum 3 active products with 4 photos each
- Premium Tier: Unlimited products with 5 photos each

Buyers:

Purchasing Obligations:
- Place orders only for products you intend to purchase
- Provide accurate delivery information
- Be available to receive orders or collect pickups as scheduled
- Pay for orders according to the selected payment method
- Do not request refunds fraudulently or abuse the cancellation policy

Review Responsibilities:
- Leave honest, factual reviews based on your actual experience
- Do not post defamatory, offensive, or irrelevant content
- Upload appropriate photos related to the product quality

## 5. Transactions and Payments

Payment Methods:
- Cash on Delivery (COD): Payment collected by Farmer upon delivery
- Cash on Pickup (COP): Payment collected by Farmer during pickup
- GCash Prepaid: Online payment verified by admin before order fulfillment

Pricing and Fees:
- Farmers set their own product prices
- Zero Commission: Agrilink charges 0% commission on sales. Farmers keep 100% of their earnings
- Buyers pay delivery fees based on distance (if applicable)
- Premium subscription fees apply for Farmers opting for enhanced features

Payment Processing:
- GCash prepaid payments are verified by admin before release to Farmers
- Earnings are added to Farmer wallets upon order completion
- Farmers can request payouts to GCash or bank accounts once the available balance reaches 100 pesos

Refund and Cancellation Policy:

Buyer Cancellations BEFORE Farmer starts preparing:
- Free cancellation allowed
- Full refund for prepaid orders

Buyer Cancellations AFTER Farmer starts preparing:
- Cancellation NOT allowed (inventory committed, perishable goods affected)
- Contact Farmer or admin for exceptional circumstances

Automatic Refunds (Farmer Fault):
- Delivery deadline exceeded (5 days after acceptance)
- Product never delivered or wrong items delivered
- System automatically detects fault and processes refund

Refund Processing Time:
- COD and COP orders: No refund needed (not yet paid)
- GCash prepaid: Refunds processed within 3-5 business days

## 6. Premium Subscription

Premium Features:
- Unlimited product listings
- 5 photos per product (vs. 4 for free tier)
- Featured placement in premium carousel on homepage
- Priority in search results
- Gold premium badge on profile

Pricing:
- Monthly Plan: 299 pesos per month (auto-renewal)
- Annual Plan: 2,999 pesos per year (save 589 pesos)

Billing and Renewal:
- Subscriptions auto-renew unless cancelled before the renewal date
- Cancellation takes effect at the end of the current billing period
- No pro-rated refunds for partial months or years

## 7. Prohibited Activities

You agree NOT to:
- Sell illegal, stolen, counterfeit, or prohibited products
- Engage in fraudulent transactions or money laundering
- Violate any local, provincial, or national laws
- Create multiple accounts to circumvent restrictions
- Use bots, scripts, or automated tools to manipulate the platform
- Attempt to hack, reverse-engineer, or disrupt the App
- Provide false information during verification or in product listings
- Post misleading product photos or descriptions
- Impersonate another user or entity
- Harass, threaten, or intimidate other users
- Post defamatory, offensive, or inappropriate content
- Spam users with unsolicited messages

Violation Consequences:
- Warning, account suspension, or permanent ban
- Forfeiture of pending earnings
- Legal action if necessary

## 8. Content and Intellectual Property

User Content:
- You retain ownership of content you upload (photos, descriptions, reviews)
- By uploading content, you grant Agrilink a non-exclusive, worldwide, royalty-free license to use, display, and distribute your content for platform operation and marketing purposes

Prohibited Content:
- Copyrighted material without permission
- Obscene, pornographic, or violent content
- Content promoting illegal activities or hate speech

Agrilink Intellectual Property:
- The Agrilink name, logo, design, and software are owned by Agrilink
- You may not use our intellectual property without written permission

## 9. Verification Process

Farmer Verification:
- Required for accepting orders and requesting payouts
- Submission of valid ID, proof of farming, and verification selfie
- Admin review within 2-3 business days

Rejection and Resubmission:
- Rejected applications include reason for rejection
- Farmers can resubmit corrected documents immediately
- No limit on resubmission attempts

## 10. Delivery and Logistics

Delivery Options:
- Home Delivery: Farmer arranges transport; Buyer pays delivery fee
- Pickup: Buyer collects from Farmer's designated location; no delivery fee

Delivery Responsibility:
- Farmers: Pack products securely, arrange delivery or prepare for pickup, update order status accurately
- Buyers: Provide accurate delivery address, be available to receive orders, collect pickups on time

Delivery Timeline:
- Farmers should deliver within 5 days of accepting the order
- Exceeding this deadline may trigger automatic refund (for prepaid orders)

## 11. Reviews and Ratings

Review System:
- Buyers can rate Farmers and products (1-5 stars)
- Reviews include written comments and optional photos
- Reviews are public and displayed on Farmer profiles and product pages

Review Guidelines:
- Reviews must be honest and based on actual experience
- No defamatory, offensive, or irrelevant content
- No reviews in exchange for compensation

## 12. Data and Privacy

We collect personal information as described in our Privacy Policy, including name, email, phone number, address, verification documents (for Farmers), transaction history, chat messages, and location data.

Your data is used to facilitate transactions, verify identities, prevent fraud, improve platform features, and send notifications about orders and account activity.

We implement industry-standard security measures to protect your data. However, no system is 100% secure, and we cannot guarantee absolute security.

See our full Privacy Policy for details.

## 13. Disclaimer of Warranties

Agrilink is provided on an "AS IS" and "AS AVAILABLE" basis without warranties of any kind, either express or implied.

We do not guarantee that the App will be uninterrupted, error-free, or free of viruses or harmful components.

Agrilink is a marketplace platform and does not directly sell products. We do not guarantee the quality, safety, legality, or accuracy of products listed by Farmers.

We are not responsible for disputes, injuries, or losses arising from interactions between users. Transactions are between Buyers and Farmers.

## 14. Limitation of Liability

To the fullest extent permitted by law, Agrilink shall not be liable for indirect, incidental, consequential, or punitive damages, loss of profits, data, or business opportunities, or personal injury or property damage arising from use of the App.

Our total liability for any claim arising from your use of Agrilink shall not exceed the amount you paid to us (if any) in the 12 months preceding the claim, or 1,000 pesos, whichever is greater.

You assume all risks associated with transactions on the platform, including product quality, payment disputes, and delivery issues.

## 15. Dispute Resolution

If you have a dispute with another user or with Agrilink, please contact us first to attempt informal resolution.

These Terms are governed by the laws of the Republic of the Philippines.

Any legal action arising from these Terms shall be filed in the courts of Agusan del Sur, Philippines.

## 16. Termination

You may delete your account at any time through the App settings. Note that pending orders must be completed or cancelled, outstanding payouts may be forfeited, and account data may be retained as required by law.

We may suspend or terminate your account immediately if you violate these Terms, we suspect fraudulent or illegal activity, or if required by law or regulatory authorities.

Upon termination, access to the App is revoked, pending transactions may be cancelled, and you remain liable for obligations incurred before termination.

## 17. Changes to Terms

We reserve the right to modify these Terms at any time. Changes will be effective upon posting to the App with an updated "Last Updated" date.

We will notify users of material changes via in-app notification, email to registered address, or prominent notice on the App.

Your continued use of the App after changes constitute acceptance of the modified Terms.

## 18. Contact Information

Agrilink Support
Email: support@agrilink.ph
In-App: AI Support Chat
Website: www.agrilink.ph
Address: Agusan del Sur, Philippines

For urgent matters (fraud, safety concerns):
Email: admin@agrilink.ph

## 19. Acknowledgment

By using Agrilink, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.

Thank you for being part of the Agrilink community.

---

Last Updated: February 2, 2026
Version: 1.0
''';
  }
}
