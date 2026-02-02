/// AI-like support service for handling buyer FAQs and queries
/// This service provides intelligent responses to common buyer questions
class AiSupportService {
  // Keywords and their associated response categories
  static const Map<String, List<String>> _keywords = {
    'order': ['order', 'purchase', 'buy', 'bought', 'ordered'],
    'payment': ['payment', 'pay', 'gcash', 'cod', 'cash', 'money', 'price'],
    'delivery': ['delivery', 'deliver', 'shipping', 'ship', 'receive', 'address'],
    'pickup': ['pickup', 'pick up', 'collect', 'fetch'],
    'cancel': ['cancel', 'cancellation', 'refund', 'return'],
    'track': ['track', 'tracking', 'status', 'where is my'],
    'product': ['product', 'item', 'fresh', 'quality', 'expired', 'shelf life'],
    'account': ['account', 'profile', 'password', 'login', 'sign in'],
    'farmer': ['farmer', 'seller', 'store', 'vendor'],
    'review': ['review', 'rating', 'feedback', 'comment'],
    'cart': ['cart', 'add to cart', 'shopping cart'],
    'search': ['search', 'find', 'looking for', 'where can i'],
    'help': ['help', 'how to', 'how do i', 'can i', 'unable to'],
  };

  // FAQ responses organized by category
  static const Map<String, List<Map<String, String>>> _faqs = {
    'order': [
      {
        'question': 'How do I place an order?',
        'answer': 'To place an order:\n1. Browse products on the home screen\n2. Tap on a product to view details\n3. Click "Add to Cart"\n4. Go to Cart and click "Proceed to Checkout"\n5. Select delivery method and payment option\n6. Confirm your order'
      },
      {
        'question': 'Can I cancel my order?',
        'answer': 'Yes! You can cancel orders that are still "Pending" or "Accepted". Once the order is "Preparing" or later, cancellation requires contacting the farmer directly. Go to My Orders → Select order → Cancel Order button.'
      },
      {
        'question': 'What order statuses exist?',
        'answer': 'Order statuses:\n• Pending - Waiting for farmer acceptance\n• Accepted - Farmer confirmed your order\n• Preparing - Being prepared for delivery\n• On The Way - Out for delivery\n• Delivered - Order completed\n• Ready for Pickup - Available for collection\n• Picked Up - Pickup completed\n• Cancelled - Order was cancelled\n• Rejected - Farmer couldn\'t fulfill'
      },
    ],
    'payment': [
      {
        'question': 'What payment methods are available?',
        'answer': 'Agrilink accepts:\n\n1. Cash on Delivery (COD) - Pay when you receive\n2. GCash Prepaid - Pay online before delivery\n\nFor COD, payment is made upon delivery. For GCash, you\'ll need to upload payment proof after checkout.'
      },
      {
        'question': 'How does GCash payment work?',
        'answer': 'GCash Payment Process:\n1. Complete checkout and select GCash\n2. Send payment to the farmer\'s GCash number\n3. Upload payment proof (screenshot/receipt)\n4. Admin will verify your payment\n5. Once verified, farmer prepares your order\n\nNote: Upload clear screenshots showing transaction details.'
      },
      {
        'question': 'Is my payment secure?',
        'answer': 'Yes! Agrilink uses secure systems:\n• GCash payments go directly to verified farmers\n• COD payments are handled face-to-face\n• All transactions are tracked in your Payment History\n• Admin verification ensures payment authenticity'
      },
    ],
    'delivery': [
      {
        'question': 'How does delivery work?',
        'answer': 'Delivery Process:\n1. Farmer prepares your order\n2. Farmer arranges delivery to your address\n3. You receive real-time status updates\n4. Track your order in "My Orders"\n5. Pay on delivery (COD) or payment already done (GCash)\n\nDelivery fees are calculated based on distance from farmer to your location.'
      },
      {
        'question': 'How long does delivery take?',
        'answer': 'Delivery time depends on:\n• Distance from farmer to your address\n• Order preparation time\n• Farmer\'s delivery schedule\n\nTypically 1-3 days for local deliveries in Agusan del Sur. Check the product listing for estimated delivery times.'
      },
      {
        'question': 'Can I change my delivery address?',
        'answer': 'For pending orders, you may need to cancel and reorder with the correct address. For accepted orders, contact the farmer through chat to request an address change.\n\nTo manage addresses: Profile → Address Management'
      },
    ],
    'pickup': [
      {
        'question': 'Can I pick up my order instead?',
        'answer': 'Yes! During checkout, select "Pickup" as your delivery method if the farmer offers it.\n\nBenefits:\n• No delivery fees\n• Potentially faster\n• See products before taking them\n\nYou\'ll receive a notification when your order is "Ready for Pickup" with the pickup address.'
      },
      {
        'question': 'Where do I pick up my order?',
        'answer': 'Pickup locations are set by each farmer. When your order status changes to "Ready for Pickup", you\'ll see:\n• Complete pickup address\n• Contact information\n• Any special instructions\n\nCheck the order details screen for this information.'
      },
    ],
    'cancel': [
      {
        'question': 'How do I get a refund?',
        'answer': 'Refund Policy:\n\n• COD Orders: No refund needed (you haven\'t paid yet)\n• GCash Prepaid: Refunds processed for cancelled orders\n\nTo request a refund:\n1. Cancel your order (if still pending/accepted)\n2. Admin reviews the cancellation\n3. Refunds are processed within 3-5 business days\n\nNote: Orders in "Preparing" or later stages may not be eligible for full refunds.'
      },
      {
        'question': 'What is the cancellation policy?',
        'answer': 'You can cancel orders freely when:\n• Status is "Pending"\n• Status is "Accepted"\n\nLimited/no cancellation when:\n• Status is "Preparing" or later\n• Food is already prepared\n\nAlways communicate with farmers if you need to cancel later-stage orders.'
      },
    ],
    'track': [
      {
        'question': 'How do I track my order?',
        'answer': 'Track your orders:\n1. Go to "My Orders" from bottom navigation\n2. Tap on any order to view details\n3. See current status and history\n4. For delivery orders, check tracking number\n\nYou\'ll also receive notifications for status changes!'
      },
      {
        'question': 'Why hasn\'t my order status updated?',
        'answer': 'Possible reasons:\n• Farmer is still preparing your order\n• Waiting for payment verification (GCash orders)\n• High volume of orders\n• Weekend/holiday delays\n\nIf status hasn\'t changed in 24 hours, contact the farmer through the chat feature.'
      },
    ],
    'product': [
      {
        'question': 'How do I know products are fresh?',
        'answer': 'Agrilink ensures freshness:\n• All farmers are verified by admins\n• Products show "shelf life" information\n• Reviews from real buyers\n• Direct from farm to your door\n• Quality issues can be reported\n\nCheck product descriptions for freshness details and expected shelf life.'
      },
      {
        'question': 'What if I receive expired products?',
        'answer': 'If you receive expired or poor quality products:\n1. Take clear photos immediately\n2. Go to Order Details\n3. Tap "Report Issue"\n4. Select "Quality Issue" or "Expired Product"\n5. Upload photos and description\n6. Admin will review and take action\n\nYou may be eligible for refund or replacement.'
      },
      {
        'question': 'Can I see product location/distance?',
        'answer': 'Yes! Products show distance from your location. This helps you:\n• Choose local farmers\n• Estimate delivery time\n• Support nearby farmers\n• Reduce delivery costs\n\nUpdate your address in Profile → Address Management for accurate distances.'
      },
    ],
    'account': [
      {
        'question': 'How do I reset my password?',
        'answer': 'To reset your password:\n1. On login screen, tap "Forgot Password?"\n2. Enter your registered email\n3. Check email for reset link\n4. Click link and create new password\n5. Login with new password\n\nIf you don\'t receive the email, check spam folder or contact support.'
      },
      {
        'question': 'How do I update my profile?',
        'answer': 'Update your profile:\n1. Go to Profile tab (bottom right)\n2. Tap "Edit Profile" or profile picture\n3. Update information (name, photo, phone, email)\n4. Save changes\n\nFor address changes: Profile → Address Management'
      },
      {
        'question': 'Can I delete my account?',
        'answer': 'Account deletion is permanent and removes:\n• Your profile and order history\n• Cart and wishlist items\n• Reviews and ratings\n• Chat history\n\nFor account deletion, please contact admin support through the app settings. Make sure to cancel any pending orders first.'
      },
    ],
    'farmer': [
      {
        'question': 'How do I contact a farmer?',
        'answer': 'To contact farmers:\n1. View any product from that farmer\n2. Tap on farmer\'s store name/profile\n3. On their profile, tap "Chat" button\n4. Send your message\n\nYou can also access chats from your order details page.'
      },
      {
        'question': 'How can I follow my favorite farmers?',
        'answer': 'Follow farmers to get updates:\n1. Visit farmer\'s store profile\n2. Tap the "Follow" button\n3. View followed stores: Home → "Followed Stores"\n4. Get notified of new products and updates\n\nFollowing helps you discover new products from farmers you trust!'
      },
      {
        'question': 'What is a Premium Farmer?',
        'answer': 'Premium Farmers have a gold badge and benefits:\n• Featured in premium carousel\n• Higher visibility in search\n• Priority listing\n• Verified and established sellers\n\nPremium status shows commitment to quality and service!'
      },
    ],
    'review': [
      {
        'question': 'How do I leave a review?',
        'answer': 'Leave reviews after order completion:\n1. Go to "My Orders"\n2. Find completed/delivered order\n3. Tap "Write Review"\n4. Rate product (1-5 stars)\n5. Add written review (optional)\n6. Upload photos (optional)\n7. Submit review\n\nReviews help other buyers and encourage quality!'
      },
      {
        'question': 'Can I edit my review?',
        'answer': 'Currently, reviews cannot be edited after submission. Please write thoughtfully!\n\nIf you need to report inappropriate content or have concerns about a review, use the "Report" feature on the review.'
      },
      {
        'question': 'Can I add photos to reviews?',
        'answer': 'Yes! Photo reviews are encouraged:\n• Take clear photos of the products\n• Upload up to 3 photos per review\n• Shows actual product quality\n• Helps other buyers make decisions\n\nPhotos are uploaded when you write your review.'
      },
    ],
    'cart': [
      {
        'question': 'How do I add items to cart?',
        'answer': 'Adding items to cart:\n1. Browse products on home screen\n2. Tap a product to view details\n3. Select quantity\n4. Tap "Add to Cart" button\n5. Continue shopping or go to cart\n\nView your cart: Cart icon in top right or bottom navigation'
      },
      {
        'question': 'Can I buy from multiple farmers?',
        'answer': 'You can add products from multiple farmers to your cart, but you need to checkout separately for each farmer.\n\nThis ensures:\n• Correct delivery fees per farmer\n• Separate order tracking\n• Individual farmer fulfillment\n\nYour cart groups items by farmer automatically.'
      },
      {
        'question': 'Why did items disappear from my cart?',
        'answer': 'Items may be removed if:\n• Product was deleted by farmer\n• Product is out of stock\n• Product expired or shelf-life ended\n• Farmer deactivated their store\n\nYou\'ll see a notification if this happens. Check for similar products from other farmers!'
      },
    ],
    'search': [
      {
        'question': 'How do I search for products?',
        'answer': 'Search products easily:\n1. Tap search icon (top of home screen)\n2. Enter product name or keyword\n3. Use filters: category, price range, distance\n4. Sort by: price, distance, rating, newest\n5. Tap product to view details\n\nExamples: "organic tomatoes", "fresh eggs", "vegetables"'
      },
      {
        'question': 'Can I filter by location?',
        'answer': 'Yes! Use location-based filtering:\n• Products show distance from your address\n• Sort by "Nearest First"\n• Filter by maximum distance\n• See farmers on map view\n\nMake sure your address is set correctly in Profile → Address Management'
      },
      {
        'question': 'What categories are available?',
        'answer': 'Agrilink product categories:\n• Vegetables\n• Fruits\n• Rice & Grains\n• Meat & Poultry\n• Fish & Seafood\n• Eggs & Dairy\n• Herbs & Spices\n• Others\n\nBrowse categories from home screen or Categories tab!'
      },
    ],
  };

  // Greeting messages
  static const List<String> _greetings = [
    'Hello! 👋 I\'m your Agrilink support assistant. How can I help you today?',
    'Hi there! 🌾 Welcome to Agrilink support. What would you like to know?',
    'Greetings! 🌱 I\'m here to help with any questions about Agrilink. What can I assist you with?',
  ];

  // Default responses when no match is found
  static const List<String> _defaultResponses = [
    'I\'m not quite sure about that. Here are some topics I can help with:\n\n• Placing and tracking orders\n• Payment methods (COD, GCash)\n• Delivery and pickup options\n• Product quality and freshness\n• Account management\n• Contacting farmers\n• Reviews and ratings\n\nWhat would you like to know more about?',
    'Hmm, I don\'t have specific information about that. Let me suggest some common topics:\n\n📦 Orders & Tracking\n💰 Payments & Refunds\n🚚 Delivery & Pickup\n🥬 Product Quality\n👤 Account Settings\n⭐ Reviews & Ratings\n\nPlease ask about any of these!',
  ];

  // Conversation history
  final List<ChatMessage> _messages = [];

  /// Get conversation history
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Initialize chat with greeting
  void initialize() {
    if (_messages.isEmpty) {
      _messages.add(ChatMessage(
        text: _greetings[0],
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Process user message and generate response
  Future<ChatMessage> sendMessage(String userMessage) async {
    // Add user message to history
    final userMsg = ChatMessage(
      text: userMessage.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);

    // Simulate thinking delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Generate response
    final response = _generateResponse(userMessage.toLowerCase());

    // Add bot response to history
    final botMsg = ChatMessage(
      text: response,
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(botMsg);

    return botMsg;
  }

  /// Generate intelligent response based on user input
  String _generateResponse(String input) {
    // Check for greetings
    if (_isGreeting(input)) {
      return 'Hello! 👋 How can I assist you today? Feel free to ask about orders, payments, delivery, or anything else about Agrilink!';
    }

    // Check for thanks
    if (_isThanks(input)) {
      return 'You\'re welcome! 😊 Is there anything else I can help you with?';
    }

    // Find matching category
    String? matchedCategory;
    int maxMatches = 0;

    for (var entry in _keywords.entries) {
      int matches = 0;
      for (var keyword in entry.value) {
        if (input.contains(keyword)) {
          matches++;
        }
      }
      if (matches > maxMatches) {
        maxMatches = matches;
        matchedCategory = entry.key;
      }
    }

    // If we found a matching category, return relevant FAQs
    if (matchedCategory != null && maxMatches > 0) {
      final faqs = _faqs[matchedCategory] ?? [];
      if (faqs.isNotEmpty) {
        // Find the most relevant FAQ
        for (var faq in faqs) {
          final question = faq['question']!.toLowerCase();
          final answer = faq['answer']!;
          
          // Check if user's question is similar to FAQ question
          if (_calculateSimilarity(input, question) > 0.3 || 
              _containsKeyWords(input, question)) {
            return answer;
          }
        }
        
        // Return all FAQs in this category if no specific match
        return _formatCategoryFaqs(matchedCategory, faqs);
      }
    }

    // No match found, return default response
    return _defaultResponses[0];
  }

  /// Format all FAQs in a category
  String _formatCategoryFaqs(String category, List<Map<String, String>> faqs) {
    String categoryTitle = category.substring(0, 1).toUpperCase() + category.substring(1);
    StringBuffer buffer = StringBuffer('Here\'s what I can tell you about $categoryTitle:\n\n');
    
    for (int i = 0; i < faqs.length && i < 3; i++) {
      buffer.write('${i + 1}. ${faqs[i]['question']}\n\n');
    }
    
    buffer.write('Ask me about any of these, or type your specific question!');
    return buffer.toString();
  }

  /// Check if input is a greeting
  bool _isGreeting(String input) {
    const greetings = ['hello', 'hi', 'hey', 'good morning', 'good afternoon', 'good evening', 'greetings'];
    return greetings.any((g) => input.contains(g));
  }

  /// Check if input is thanks
  bool _isThanks(String input) {
    const thanks = ['thank', 'thanks', 'thank you', 'appreciate', 'helpful'];
    return thanks.any((t) => input.contains(t));
  }

  /// Calculate similarity between two strings (simple version)
  double _calculateSimilarity(String s1, String s2) {
    final words1 = s1.split(' ');
    final words2 = s2.split(' ');
    int commonWords = 0;

    for (var word in words1) {
      if (words2.contains(word) && word.length > 3) {
        commonWords++;
      }
    }

    return commonWords / words1.length;
  }

  /// Check if input contains key words from question
  bool _containsKeyWords(String input, String question) {
    final questionWords = question.split(' ')
        .where((w) => w.length > 4 && !['what', 'where', 'when', 'how', 'can', 'do'].contains(w))
        .toList();
    
    int matches = 0;
    for (var word in questionWords) {
      if (input.contains(word)) {
        matches++;
      }
    }
    
    return matches >= 2;
  }

  /// Get quick reply suggestions based on context
  List<String> getQuickReplies() {
    if (_messages.length <= 1) {
      return [
        'How do I place an order?',
        'What payment methods are available?',
        'How does delivery work?',
        'How do I track my order?',
      ];
    }

    // Return contextual quick replies
    return [
      'Tell me more',
      'How do I do that?',
      'What else should I know?',
      'Thank you!',
    ];
  }

  /// Clear conversation history
  void clearHistory() {
    _messages.clear();
    initialize();
  }

  /// Get suggested topics
  static List<String> getSuggestedTopics() {
    return [
      '📦 How do I place an order?',
      '💰 What payment methods are available?',
      '🚚 How does delivery work?',
      '📍 Can I pick up my order instead?',
      '❌ How do I cancel my order?',
      '📊 How do I track my order?',
      '🥬 How do I know products are fresh?',
      '👤 How do I update my profile?',
      '👨‍🌾 How do I contact a farmer?',
      '⭐ How do I leave a review?',
    ];
  }
}

/// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
