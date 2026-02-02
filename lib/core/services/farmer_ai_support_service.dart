/// Type alias for FAQ entries
typedef FAQ = Map<String, String>;

/// AI-like support service for handling farmer FAQs and queries
/// This service provides intelligent responses to common farmer questions
class FarmerAiSupportService {
  // Keywords and their associated response categories
  static const Map<String, List<String>> _keywords = {
    'verification': ['verification', 'verify', 'verified', 'documents', 'approve', 'approved', 'reject', 'rejected', 'pending', 'id', 'clearance', 'selfie'],
    'product': ['product', 'add product', 'edit product', 'delete', 'price', 'pricing', 'stock', 'inventory', 'photo', 'image', 'shelf life', 'expiry', 'expire'],
    'order': ['order', 'accept', 'reject', 'prepare', 'preparing', 'deliver', 'delivery', 'track', 'tracking', 'complete', 'status', 'buyer'],
    'premium': ['premium', 'subscription', 'subscribe', 'featured', 'upgrade', 'benefits', 'gold', 'badge', 'unlimited', 'cost', 'price'],
    'premium_subscription': ['premium', 'subscription', 'subscribe', 'featured', 'upgrade'],
    'payout': ['payout', 'withdraw', 'withdrawal', 'earnings', 'wallet', 'balance', 'money', 'gcash', 'bank', 'transfer', 'commission'],
    'store': ['store', 'shop', 'banner', 'customize', 'profile', 'farm name', 'description', 'followers', 'follow'],
    'delivery': ['delivery', 'shipping', 'fee', 'pickup', 'collect', 'address', 'arrange', 'courier'],
    'payment': ['payment', 'cod', 'gcash', 'verified', 'proof', 'screenshot', 'buyer payment'],
    'review': ['review', 'rating', 'feedback', 'star', 'customer', 'complaint', 'bad review'],
    'analytics': ['analytics', 'sales', 'reports', 'statistics', 'stats', 'earnings', 'chart', 'dashboard'],
    'account': ['account', 'profile', 'password', 'login', 'sign in', 'email', 'settings'],
    'photo': ['photo', 'image', 'camera', 'picture', 'take photo', 'quality', 'lighting'],
    'tips': ['tip', 'tips', 'advice', 'best practice', 'how to sell', 'improve', 'better'],
    'help': ['help', 'how to', 'how do i', 'can i', 'unable to', 'tutorial', 'guide', 'steps'],
  };

  // FAQ responses organized by category
  static const Map<String, List<Map<String, String>>> _faqs = {
    'verification': [
      {
        'question': 'How do I get verified as a farmer?',
        'answer': '🔐 Verification Process:\n\nSTEP 1: Go to Profile\n• Tap your profile picture\n• Select "Verification Status"\n\nSTEP 2: Upload 3 Documents\n• Valid ID (driver\'s license, UMID, passport)\n• Barangay Clearance or Farm Registration\n• Selfie holding your ID (for verification)\n\nSTEP 3: Submit for Review\n• Tap "Submit for Verification"\n• Wait 2-3 business days\n\nSTEP 4: Get Approved\n• Receive notification\n• Unlock all features!\n\n✅ Benefits of Verification:\n• Accept and fulfill orders\n• Request payouts\n• Build buyer trust\n• Access all features\n\n📸 Photo Tips:\n• Use clear, well-lit photos\n• All text must be readable\n• No blurry or dark images\n• Valid, unexpired documents'
      },
      {
        'question': 'What documents do I need for verification?',
        'answer': '📄 Required Documents (3):\n\n1️⃣ Valid Government ID:\n• Driver\'s License\n• UMID / SSS / PhilHealth ID\n• Passport\n• Voter\'s ID\n• National ID\n\n2️⃣ Proof of Farming:\n• Barangay Clearance\n• Farm Registration Certificate\n• Agricultural Business Permit\n• Farmer\'s ID from LGU\n\n3️⃣ Verification Selfie:\n• Hold your ID next to your face\n• Both face and ID clearly visible\n• Good lighting\n• No sunglasses or mask\n\n⚠️ Important:\n• Documents must be valid (not expired)\n• Photos must be clear and readable\n• All names must match\n• Selfie verifies you are the document holder'
      },
      {
        'question': 'How long does verification take?',
        'answer': '⏱️ Verification Timeline:\n\n📤 After Submission:\n• Documents sent to admin review\n• Usually reviewed within 2-3 business days\n• May take up to 5 days during peak times\n\n✅ If Approved:\n• Receive notification immediately\n• All features unlocked\n• Can start accepting orders\n• Can request payouts\n\n❌ If Rejected:\n• Receive notification with reason\n• Can resubmit immediately\n• Fix the issues mentioned\n• No waiting period to resubmit\n\n💡 Tips for Faster Approval:\n• Upload clear, high-quality photos\n• Ensure all documents are valid\n• Make sure all names match\n• Follow photo requirements\n\n🔔 Check notifications regularly!'
      },
      {
        'question': 'Why was my verification rejected?',
        'answer': '❌ Common Rejection Reasons:\n\n📸 Photo Quality Issues:\n• Blurry or dark images\n• Text not readable\n• Document cut off in photo\n• Solution: Retake with good lighting\n\n📄 Document Problems:\n• Expired ID or documents\n• Names don\'t match between documents\n• Invalid or fake documents\n• Solution: Use valid, matching documents\n\n🤳 Selfie Issues:\n• Face not clearly visible\n• ID not readable in selfie\n• Wrong person in selfie\n• Solution: Take clear selfie with ID\n\n📋 Missing Information:\n• Incomplete documents\n• Required document not uploaded\n• Solution: Upload all 3 required documents\n\n✅ How to Fix:\n1. Check notification for specific reason\n2. Fix the mentioned issue\n3. Resubmit immediately (no waiting)\n4. Usually approved within 24 hours if fixed\n\n💬 Need help? Contact admin support!'
      },
      {
        'question': 'Can I resubmit verification documents?',
        'answer': '✅ Yes, you can resubmit anytime!\n\n🔄 Resubmission Process:\n\n1️⃣ Check Rejection Reason:\n• Read notification carefully\n• Understand what needs fixing\n\n2️⃣ Fix the Issues:\n• Retake photos if needed\n• Get valid documents\n• Ensure everything is clear\n\n3️⃣ Resubmit:\n• Go to Profile → Verification Status\n• Upload corrected documents\n• Submit again\n\n4️⃣ Faster Review:\n• Fixed submissions reviewed faster\n• Usually within 24-48 hours\n\n⚠️ No Limits:\n• No limit on resubmissions\n• No waiting period\n• No penalty for rejections\n\n💡 Pro Tip:\n• Take time to get it right\n• Clear photos = faster approval\n• All names must match exactly'
      },
      {
        'question': 'What happens after I\'m verified?',
        'answer': '✅ After Verification Approval:\n\n🎉 Immediate Benefits:\n• ✅ Accept orders from buyers\n• ✅ Request payouts (withdraw earnings)\n• ✅ Full access to all features\n• ✅ Verified badge on profile\n• ✅ Increased buyer trust\n\n📦 What You Can Do:\n• Add unlimited products (or 3 for free tier)\n• Accept and fulfill orders\n• Update order statuses\n• Communicate with buyers\n• Request payouts anytime\n• Access sales analytics\n\n💰 Earnings:\n• Start earning immediately\n• 0% commission - keep 100%!\n• Withdraw anytime (min ₱100)\n• GCash or bank transfer\n\n⭐ Optional:\n• Consider Premium subscription\n• Get featured on homepage\n• Unlimited products\n• Priority placement\n\n🚀 Ready to Start Selling:\n1. Add your first product\n2. Wait for orders\n3. Fulfill orders promptly\n4. Build your reputation\n5. Grow your farming business!'
      },
    ],
    'product': [
      {
        'question': 'How do I add a new product?',
        'answer': '📦 Adding Products:\n\nSTEP 1: Go to Dashboard\n• Tap "Products" section\n• Tap "Add Product" button (➕)\n\nSTEP 2: Fill Product Details\n• Product name (e.g., "Fresh Tomatoes")\n• Category (Vegetables, Fruits, etc.)\n• Price per unit\n• Available quantity\n• Unit type (kg, piece, bunch, sack)\n\nSTEP 3: Add Photos\n• Tap "Add Photos" button\n• Select up to 4 photos (5 for Premium)\n• Use clear, well-lit photos\n• Show product quality\n\nSTEP 4: Set Shelf Life\n• How many days product stays fresh\n• Example: Tomatoes = 7 days\n• Lettuce = 5 days\n• Rice = 365 days\n\nSTEP 5: Add Description\n• Describe your product\n• Mention: freshness, organic, farming method\n• Include any special features\n\nSTEP 6: Submit\n• Tap "Add Product" button\n• Product goes live immediately!\n• Buyers can see it right away\n\n💡 TIP: Good photos = more sales!'
      },
      {
        'question': 'How many products can I list?',
        'answer': '📊 Product Limits:\n\n🆓 FREE TIER:\n• Maximum: 3 active products\n• 4 photos per product\n• Full product features\n• Good for starting out\n\n⭐ PREMIUM TIER:\n• Unlimited products!\n• 5 photos per product\n• Featured on homepage\n• Priority in search results\n• Gold badge on profile\n\n📈 Why Upgrade?\n• Sell more product varieties\n• More visibility\n• More photos per product\n• Attract more buyers\n• Grow your business faster\n\n💰 Premium Cost:\n• ₱299/month or ₱2,999/year\n• Worth it if selling >3 products\n\n🎯 Choose Based On:\n• Free: Testing, seasonal farmers\n• Premium: Serious sellers, multiple crops'
      },
      {
        'question': 'How do I set product prices?',
        'answer': '💵 Pricing Your Products:\n\n📊 Research Market Prices:\n• Check prices at local markets\n• See competitor prices on Agrilink\n• Consider seasonal variations\n• Factor in quality differences\n\n🧮 Calculate Your Costs:\n• Production/farming costs\n• Labor and time\n• Packaging materials\n• Transportation/delivery\n• Your desired profit margin\n\n💡 Pricing Strategies:\n\n1️⃣ Competitive Pricing:\n• Match or slightly below market\n• Good for gaining customers\n• Build reputation first\n\n2️⃣ Premium Pricing:\n• Higher than average\n• For organic/special products\n• Highlight quality in description\n\n3️⃣ Value Pricing:\n• Fair price for quality\n• Most common strategy\n• Balance profit and sales\n\n✅ Best Practices:\n• Price per standard unit (kg, piece)\n• Round numbers (₱50, ₱100)\n• Be consistent with quality\n• Update for seasonal changes\n• Offer bulk discounts\n\n⚠️ Remember:\n• You keep 100% - NO commission!\n• Set prices you\'re happy with\n• Can change anytime'
      },
      {
        'question': 'What is shelf life and how do I set it?',
        'answer': '🗓️ Shelf Life Explained:\n\n❓ What Is It?\n• Number of days product stays fresh\n• Helps buyers know product lifespan\n• Auto-hides expired products\n• Maintains product quality\n\n⏰ How It Works:\n1. You set shelf life when adding product\n2. System tracks days since harvest/listing\n3. Shows "X days fresh" to buyers\n4. Auto-marks as expired when time\'s up\n5. Expired products hidden from buyers\n\n📅 Common Shelf Life Examples:\n\n🥬 Leafy Vegetables:\n• Lettuce, Pechay: 5-7 days\n• Kangkong, Mustard: 3-5 days\n\n🍅 Fruits & Vegetables:\n• Tomatoes: 7-10 days\n• Eggplant: 7-10 days\n• Squash: 14-21 days\n• Potatoes: 30-60 days\n\n🌾 Grains & Dry Goods:\n• Rice: 365 days\n• Corn (dried): 180 days\n• Beans: 365 days\n\n🥚 Animal Products:\n• Eggs: 21-28 days\n• Fresh meat: 2-3 days\n\n💡 Tips:\n• Be honest about freshness\n• Consider storage conditions\n• Set realistic timeframes\n• Update if product condition changes'
      },
      {
        'question': 'How do I add product photos?',
        'answer': '📸 Adding Product Photos:\n\nSTEP 1: When Adding/Editing Product\n• Tap "Add Photos" or "📷" button\n• Choose from:\n  - Take Photo (camera)\n  - Choose from Gallery\n\nSTEP 2: Select Multiple Photos\n• Free Tier: Up to 4 photos\n• Premium: Up to 5 photos\n• First photo = main product image\n\nSTEP 3: Photo Tips:\n✅ Good Lighting:\n• Natural daylight is best\n• Avoid shadows\n• No flash if possible\n\n✅ Clear Focus:\n• Product should be sharp\n• Show product details\n• No blurry images\n\n✅ Multiple Angles:\n• Front view (main photo)\n• Close-up of quality\n• Size reference\n• Packaging (if applicable)\n\n✅ Clean Background:\n• Plain or simple background\n• Remove clutter\n• Focus on product\n\n✅ Show Quality:\n• Fresh, appealing products\n• Vibrant colors\n• Clean presentation\n\n❌ Avoid:\n• Dark or blurry photos\n• Messy backgrounds\n• Poor quality products\n• Misleading images\n\n💡 Pro Tip:\n• Good photos = 3x more sales!\n• Take multiple shots, choose best\n• Update photos if quality improves'
      },
      {
        'question': 'How do I edit or delete a product?',
        'answer': '✏️ Edit or Delete Products:\n\n📝 EDIT PRODUCT:\n\nSTEP 1: Go to Products\n• Dashboard → Products\n• Find product to edit\n\nSTEP 2: Tap Product\n• Tap the product card\n• Select "Edit Product" button\n\nSTEP 3: Make Changes\n• Update any field:\n  - Name, price, quantity\n  - Photos, description\n  - Shelf life, category\n\nSTEP 4: Save\n• Tap "Save Changes"\n• Updates visible immediately\n\n🗑️ DELETE PRODUCT:\n\nSTEP 1: Go to Product Details\n• Find product in your list\n• Tap to open details\n\nSTEP 2: Delete\n• Tap "Delete Product" button\n• Confirm deletion\n\nSTEP 3: Confirm\n• Type confirmation if requested\n• Product removed immediately\n\n⚠️ Important:\n• Can\'t delete if active orders exist\n• Deleted products can\'t be restored\n• Consider "Out of Stock" instead\n\n💡 Better Option:\n• Set quantity to 0 (out of stock)\n• Keeps product history\n• Easy to restock later\n• Maintains reviews/ratings'
      },
      {
        'question': 'Why is my product not showing to buyers?',
        'answer': '🔍 Product Not Visible? Check:\n\n1️⃣ Verification Status:\n❌ NOT verified = Products hidden\n✅ Verified = Products visible\n• Solution: Complete verification first\n\n2️⃣ Product Quantity:\n• Quantity = 0 → Hidden\n• Solution: Update quantity > 0\n\n3️⃣ Shelf Life Expired:\n• Check "Days Fresh" field\n• Expired products auto-hidden\n• Solution: Update/re-add product\n\n4️⃣ Product Deleted:\n• Accidentally deleted?\n• Solution: Add product again\n\n5️⃣ Account Status:\n• Suspended account?\n• Check notifications\n• Solution: Contact admin\n\n6️⃣ Photos Missing:\n• Products without photos rank lower\n• Solution: Add quality photos\n\n7️⃣ Just Added:\n• Wait 1-2 minutes for system update\n• Refresh buyer app\n\n✅ How to Check:\n• Ask a friend to search\n• Use buyer account to test\n• Check product list on your dashboard\n\n💡 Quick Fix:\n1. Verify you\'re verified ✓\n2. Check quantity > 0\n3. Ensure not expired\n4. Add photos if missing\n5. Wait 2 minutes, test again'
      },
      {
        'question': 'What are product units?',
        'answer': '⚖️ Product Units Explained:\n\n📊 Available Units:\n\n🌾 Weight-Based:\n• Kilogram (kg) - Most common\n• Gram (g) - Small items\n• Sack - Rice, grains (25kg, 50kg)\n\n🔢 Count-Based:\n• Piece (pc) - Individual items\n• Bunch - Leafy vegetables\n• Dozen - Eggs, fruits\n• Tray - Eggs (30 pieces)\n\n📏 Volume-Based:\n• Liter (L) - Liquids, honey\n• Gallon - Large volumes\n\n🎯 How to Choose:\n\n🥬 Leafy Vegetables:\n• Use: Bunch or Kilogram\n• Example: "₱30 per bunch"\n\n🍅 Fruits/Vegetables:\n• Use: Kilogram or Piece\n• Example: "₱80 per kg" or "₱20 per piece"\n\n🌾 Grains:\n• Use: Kilogram or Sack\n• Example: "₱45 per kg" or "₱2,000 per sack (50kg)"\n\n🥚 Eggs:\n• Use: Dozen or Tray\n• Example: "₱90 per dozen"\n\n💡 Best Practices:\n• Use standard market units\n• Be clear in description\n• Specify sack size if applicable\n• Buyers understand better\n• Easier to compare prices\n\n✅ Can Change:\n• Edit product to change unit\n• Update price accordingly'
      },
      {
        'question': 'How do I manage product stock?',
        'answer': '📦 Stock Management:\n\n🔢 Update Quantity:\n\nSTEP 1: Go to Products\n• Dashboard → Products list\n\nSTEP 2: Edit Product\n• Tap product to edit\n• Find "Available Quantity" field\n\nSTEP 3: Update Number\n• Enter current stock\n• Example: 50 kg, 100 pieces\n\nSTEP 4: Save\n• Changes reflect immediately\n• Buyers see updated quantity\n\n📊 Stock Levels:\n\n✅ In Stock:\n• Quantity > 0\n• Visible to buyers\n• Can receive orders\n\n⚠️ Low Stock:\n• Quantity = 1-5 units\n• Buyers see "Only X left!"\n• Creates urgency\n\n❌ Out of Stock:\n• Quantity = 0\n• Hidden from search\n• Can\'t receive new orders\n\n💡 Smart Tips:\n\n1️⃣ Regular Updates:\n• Update after each harvest\n• Check daily during busy season\n\n2️⃣ Buffer Stock:\n• Set quantity slightly lower\n• Prevents over-selling\n• Account for quality sorting\n\n3️⃣ Seasonal Products:\n• Mark out of stock (0) when season ends\n• Re-add next season\n\n4️⃣ Reserve for Orders:\n• Reduce quantity after accepting order\n• Prevents double-selling\n\n🔄 Auto-Update:\n• System auto-reduces quantity when order placed\n• You manage restocking'
      },
      {
        'question': 'Can I offer discounts or promotions?',
        'answer': '💰 Discounts & Promotions:\n\n✅ YES - Here\'s How:\n\n1️⃣ Manual Price Reduction:\n• Edit product\n• Lower the price\n• Update description: "SALE! Was ₱100, Now ₱80"\n• Set time limit in description\n\n2️⃣ Bulk Discounts:\n• In product description, mention:\n• "Buy 10kg+ get ₱5/kg discount"\n• "5 bunches for ₱100 (save ₱25)"\n• Buyers message you for bulk orders\n\n3️⃣ Bundle Offers:\n• Create bundle product:\n• "Vegetable Pack (3kg mixed) - ₱150"\n• List included items\n• Show savings\n\n4️⃣ Seasonal Sales:\n• During harvest peak:\n• "Fresh harvest sale - 20% off!"\n• Helps move inventory\n• Attracts buyers\n\n5️⃣ Premium Featured:\n• Premium farmers:\n• Products featured on homepage\n• Daily rotation\n• More visibility = natural promotion\n\n💡 Promotion Tips:\n\n✅ Do:\n• Mention in product description\n• Use clear pricing\n• Set time limits\n• Respond quickly to inquiries\n\n❌ Don\'t:\n• Mislead with fake original prices\n• Discount expired/low-quality products\n• Forget to update after promotion\n\n🎯 Future Feature:\n• Built-in promo codes coming soon!\n• Automated discount system'
      },
    ],
    'order': [
      {
        'question': 'How do I accept orders?',
        'answer': '📋 Accepting Orders:\n\nSTEP 1: Receive Notification\n• Get notification when order placed\n• Check "New Orders" in dashboard\n\nSTEP 2: Review Order\n• Order details: items, quantity, total\n• Buyer information & delivery address\n• Payment method (COD or GCash)\n• Delivery or Pickup preference\n\nSTEP 3: Check Availability\n• Do you have the products?\n• Can you fulfill the quantity?\n• Can you deliver on time?\n\nSTEP 4: Accept or Reject\n\n✅ TO ACCEPT:\n• Tap "Accept Order" button\n• Confirm acceptance\n• Order status → "Accepted"\n• Buyer gets notification\n\n❌ TO REJECT:\n• Tap "Reject Order" button\n• Select reason (out of stock, etc.)\n• Order cancelled\n• Buyer notified to find alternative\n\n⏱️ Response Time:\n• Respond within 24 hours\n• Faster = better reputation\n• Ignored orders auto-cancelled after 48hrs\n\n💡 Best Practice:\n• Accept only what you can fulfill\n• Check stock before accepting\n• Update product quantity if low'
      },
      {
        'question': 'What do I do after accepting an order?',
        'answer': '✅ After Accepting Order:\n\nSTEP 1: Prepare the Products\n• Harvest/gather the items\n• Check quality carefully\n• Clean and package properly\n• Match order specifications exactly\n\nSTEP 2: Update Status to "Preparing"\n• Go to Orders → Order Details\n• Tap "Update Status"\n• Select "Preparing"\n• Buyer sees you\'re working on it\n\nSTEP 3: Arrange Delivery/Pickup\n\n🚚 FOR DELIVERY:\n• Pack items securely\n• Arrange courier/personal delivery\n• Update status to "On The Way"\n• Add tracking number if available\n\n📍 FOR PICKUP:\n• Pack items ready\n• Update status to "Ready for Pickup"\n• Buyer gets notification with address\n• Wait for buyer to collect\n\nSTEP 4: Complete Order\n• After successful delivery/pickup\n• Tap "Mark as Delivered/Picked Up"\n• Order completed!\n\nSTEP 5: Collect Payment (COD)\n• If COD: Collect cash on delivery\n• If GCash: Payment already received\n\n💰 Get Paid:\n• Earnings added to wallet automatically\n• Request payout anytime (min ₱100)\n• 0% commission - keep 100%!\n\n💡 Communication:\n• Message buyer if delays\n• Update status promptly\n• Build good reputation'
      },
      {
        'question': 'How do I update order status?',
        'answer': '🔄 Update Order Status:\n\nSTEP 1: Go to Orders\n• Dashboard → Orders\n• Find the order\n\nSTEP 2: Open Order Details\n• Tap on order\n• See current status\n\nSTEP 3: Update Status\n• Tap "Update Status" button\n• Select new status\n\nSTEP 4: Add Notes (Optional)\n• Provide update details\n• Example: "On the way, ETA 2pm"\n• Buyer sees notes\n\n📊 Order Status Flow:\n\n1️⃣ New Order (Initial)\n• Just received\n• Review and decide\n\n2️⃣ Accepted\n• You confirmed order\n• Start preparing\n\n3️⃣ Preparing (toPack)\n• Gathering/packing products\n• Quality checking\n\n4️⃣ Ready for Delivery (toDeliver)\n• Packed and ready\n• Arranging transport\n\n5️⃣ On The Way (Delivery)\n• Out for delivery\n• Add tracking if available\n\n5️⃣ Ready for Pickup (Pickup)\n• Packed and waiting\n• Buyer can collect\n\n6️⃣ Delivered / Picked Up\n• Order completed\n• Payment collected\n• Earnings in wallet\n\n⚠️ Important:\n• Update promptly\n• Each update notifies buyer\n• Good communication = happy buyers\n• Better ratings and reviews'
      },
      {
        'question': 'What are the order statuses?',
        'answer': '📊 Order Status Guide:\n\n🆕 NEW ORDER:\n• Just placed by buyer\n• Waiting for your response\n• Action: Accept or Reject\n\n✅ ACCEPTED:\n• You confirmed the order\n• Buyer notified\n• Action: Start preparing\n\n📦 PREPARING (toPack):\n• You\'re gathering/packing items\n• Buyer knows it\'s being prepared\n• Action: Pack carefully, check quality\n\n🚚 TO DELIVER (toDeliver):\n• Ready for delivery\n• Arranging courier/transport\n• Action: Dispatch soon\n\n🛵 ON THE WAY:\n• Out for delivery\n• Has tracking number\n• Action: Deliver to buyer\n\n📍 READY FOR PICKUP:\n• Packed and ready at your location\n• Buyer can collect\n• Action: Wait for buyer\n\n✔️ DELIVERED / PICKED UP:\n• Order successfully completed\n• Payment collected (COD)\n• Earnings in wallet\n• Action: Request payout when ready\n\n❌ CANCELLED:\n• Order was cancelled\n• By you, buyer, or system\n• No payment involved\n\n🚫 REJECTED:\n• You rejected the order\n• Stock unavailable or other reason\n• Buyer finds alternative\n\n💡 Timeline:\n• New → Accepted: Within 24 hours\n• Accepted → Preparing: Start immediately\n• Preparing → Delivery: 1-2 days\n• Delivery → Complete: Same day\n\n⏰ Total: Usually 2-4 days'
      },
      {
        'question': 'How do I mark order as delivered?',
        'answer': '✔️ Mark as Delivered:\n\n🚚 FOR DELIVERY ORDERS:\n\nSTEP 1: Complete Delivery\n• Physically deliver to buyer\n• Collect payment if COD\n• Get buyer confirmation\n\nSTEP 2: Update in App\n• Go to Orders → Order Details\n• Tap "Update Status"\n• Select "Delivered"\n• Confirm\n\nSTEP 3: Verify\n• Order status = "Delivered"\n• Earnings added to wallet\n• Buyer can now review\n\n📍 FOR PICKUP ORDERS:\n\nSTEP 1: Buyer Collects\n• Buyer arrives at pickup location\n• Hand over the items\n• Collect payment if COD\n\nSTEP 2: Update in App\n• Go to Orders → Order Details\n• Tap "Update Status"\n• Select "Picked Up"\n• Confirm\n\nSTEP 3: Verify\n• Order status = "Picked Up"\n• Earnings added to wallet\n• Buyer can now review\n\n💰 Payment Collection:\n\n💵 COD (Cash on Delivery):\n• Collect exact amount\n• Provide receipt if requested\n• Money is yours (0% commission!)\n\n💳 GCash (Prepaid):\n• Already paid and verified\n• Just deliver the items\n• Earnings already in wallet\n\n⚠️ Important:\n• Only mark delivered after actual delivery\n• Buyer can dispute if not received\n• Be honest about delivery status\n\n🎯 After Completion:\n• Earnings show in wallet\n• Can request payout anytime\n• Wait for buyer review (optional)'
      },
      {
        'question': 'What if I need to reject an order?',
        'answer': '❌ Rejecting Orders:\n\n⚠️ When to Reject:\n• Out of stock / sold out\n• Can\'t fulfill quantity\n• Quality issues with product\n• Can\'t deliver to location\n• Personal emergency\n\n📋 How to Reject:\n\nSTEP 1: Go to Order Details\n• Find the order\n• Open details page\n\nSTEP 2: Tap "Reject Order"\n• Button usually at bottom\n• Or in order actions menu\n\nSTEP 3: Select Reason\n• Out of stock\n• Insufficient quantity\n• Quality concerns\n• Delivery issues\n• Other (specify)\n\nSTEP 4: Add Notes (Optional)\n• Explain reason briefly\n• Be professional and polite\n• Example: "Sorry, ran out of stock today"\n\nSTEP 5: Confirm Rejection\n• Order cancelled\n• Buyer notified immediately\n• Buyer can find alternative\n\n💡 Best Practices:\n\n✅ Do:\n• Reject early (within 24 hours)\n• Provide honest reason\n• Update product stock\n• Communicate politely\n\n❌ Don\'t:\n• Wait too long to reject\n• Accept then reject later\n• Reject without reason\n• Reject too often (hurts reputation)\n\n🎯 Better Alternative:\n• Message buyer first\n• Offer substitute product\n• Adjust quantity if needed\n• Try to fulfill if possible\n\n📊 Impact:\n• High rejection rate affects reputation\n• Keep products updated to avoid\n• Only accept what you can fulfill'
      },
      {
        'question': 'How do I contact the buyer?',
        'answer': '💬 Contact Buyer:\n\nSTEP 1: Go to Order Details\n• Find the order\n• Open order details page\n\nSTEP 2: Find Chat Button\n• Look for "Message Buyer" or chat icon\n• Usually near top or bottom\n\nSTEP 3: Send Message\n• Opens chat conversation\n• Type your message\n• Send\n\n📱 What to Message:\n\n✅ Good Messages:\n• "Order accepted! Will prepare today"\n• "On the way, ETA 2pm"\n• "Ready for pickup at [address]"\n• "Any special packaging requests?"\n• "Product quality update: extra fresh!"\n\n❌ Avoid:\n• Asking for payment outside app\n• Personal information requests\n• Spam or promotional messages\n• Rude or unprofessional tone\n\n💡 Communication Tips:\n\n1️⃣ Be Prompt:\n• Reply within hours\n• Faster = better reputation\n\n2️⃣ Be Clear:\n• Specific delivery times\n• Clear pickup instructions\n• Honest about status\n\n3️⃣ Be Professional:\n• Polite and friendly\n• Use proper grammar\n• Stay on topic\n\n4️⃣ Be Proactive:\n• Update on delays\n• Confirm before delivery\n• Thank after completion\n\n🎯 Benefits:\n• Happy buyers\n• Better reviews\n• Repeat customers\n• Higher ratings\n\n📞 Other Contact:\n• Buyer phone shown in order details\n• Call if urgent\n• App messages preferred for record'
      },
      {
        'question': 'When do I get paid for orders?',
        'answer': '💰 Getting Paid:\n\n⏰ Payment Timeline:\n\nSTEP 1: Order Placed\n• Buyer places order\n• Payment method shown (COD/GCash)\n\nSTEP 2: During Order Processing\n\n💳 GCash Prepaid:\n• Buyer pays upfront\n• Admin verifies payment\n• Money held in system\n• Added to wallet after delivery\n\n💵 COD:\n• No payment yet\n• Collect on delivery\n• Keep cash immediately (0% commission!)\n\nSTEP 3: After Delivery\n• Mark order as "Delivered/Picked Up"\n• System processes payment\n• Earnings added to wallet IMMEDIATELY\n• See balance in Dashboard → Wallet\n\nSTEP 4: Withdraw Earnings\n• Request payout anytime\n• Minimum: ₱100\n• GCash or Bank Transfer\n• Processed within 2-3 business days\n\n💡 Key Points:\n\n✅ 0% Commission:\n• You keep 100% of order amount!\n• Example: ₱500 order = ₱500 earnings\n• No hidden fees\n\n✅ Fast Access:\n• Earnings available immediately after delivery\n• No waiting period\n• Request payout anytime\n\n✅ Transparent:\n• See all earnings in wallet\n• Complete order breakdown\n• Payment history available\n\n📊 Wallet Status:\n• Available Balance: Ready to withdraw\n• Pending Earnings: Orders in progress\n• Total Earnings: Lifetime earnings\n\n🎯 Best Practice:\n• Complete orders promptly\n• Update status accurately\n• Build up balance before payout\n• Withdraw regularly'
      },
    ],
    'premium': [],
    'payout': [
      {
        'question': 'How do I request a payout?',
        'answer': '💰 Request Payout:\n\nSTEP 1: Setup Payment Details (First Time)\n• Go to Profile → Payment Settings\n• Add GCash number OR Bank details\n• GCash: Mobile number + Name\n• Bank: Account number, Bank name, Account name\n• Save information\n\nSTEP 2: Check Available Balance\n• Go to Dashboard → Wallet\n• See "Available Balance"\n• Must be at least ₱100 (minimum)\n\nSTEP 3: Request Payout\n• Tap "Request Payout" button\n• Enter amount (max = available balance)\n• Select payment method:\n  - GCash (instant to 24hrs)\n  - Bank Transfer (2-3 days)\n• Add optional notes\n• Submit request\n\nSTEP 4: Wait for Processing\n• Status: Pending → Processing → Completed\n• Admin reviews within 24 hours\n• Payment sent to your account\n• Receive notification when done\n\n⏱️ Processing Time:\n• GCash: Usually within 24 hours\n• Bank: 2-3 business days\n• Weekends may take longer\n\n💵 Important:\n• Minimum: ₱100\n• Maximum: Your available balance\n• 0% fees - You get full amount!\n• Can request anytime\n\n🎯 Track Your Request:\n• Go to Wallet → Payout History\n• See all requests and status'
      },
      {
        'question': 'When can I withdraw my earnings?',
        'answer': '⏰ Withdrawal Conditions:\n\n✅ You Can Withdraw When:\n\n1️⃣ Available Balance ≥ ₱100\n• Check Dashboard → Wallet\n• "Available Balance" must be ₱100+\n• This is money from completed orders\n\n2️⃣ Verified Account\n• Must be verified farmer\n• Complete verification first\n\n3️⃣ Payment Details Added\n• GCash or Bank account set up\n• Go to Payment Settings\n• Add your details\n\n4️⃣ No Pending Payout\n• Can\'t have active payout request\n• Wait for current request to complete\n• Then request again\n\n💰 Balance Types:\n\n✅ Available Balance:\n• From completed/delivered orders\n• Ready to withdraw NOW\n• Request payout anytime\n\n⏳ Pending Earnings:\n• Orders in progress\n• Not completed yet\n• Wait until delivered\n• Then becomes available\n\n📊 Example:\n• Completed 5 orders = ₱800\n• Available Balance = ₱800\n• Can withdraw ₱800 now!\n\n• Active orders = ₱300\n• Pending Earnings = ₱300\n• Can\'t withdraw yet\n• Complete orders first\n\n💡 Best Practice:\n• Let balance build up\n• Withdraw weekly/monthly\n• Saves processing time\n• Easier tracking'
      },
      {
        'question': 'What payment methods are available?',
        'answer': '💳 Payout Methods:\n\n📱 1. GCASH (Recommended)\n\n✅ Advantages:\n• Fastest (usually 24 hours)\n• Widely used in Philippines\n• Easy to setup\n• Instant mobile access\n• No bank account needed\n\n📋 What You Need:\n• GCash-registered mobile number\n• Account holder name\n• Account must be verified\n\n💡 Setup:\n• Profile → Payment Settings\n• Select GCash\n• Enter: 09XX XXX XXXX\n• Enter your full name\n• Save\n\n🏦 2. BANK TRANSFER\n\n✅ Advantages:\n• Direct to bank account\n• Secure and official\n• Good for large amounts\n• Keep in savings\n\n📋 What You Need:\n• Bank account number\n• Bank name (BDO, BPI, LandBank, etc.)\n• Account holder name\n• Branch (optional)\n\n💡 Setup:\n• Profile → Payment Settings\n• Select Bank Transfer\n• Enter account details\n• Save\n\n⏱️ Processing Times:\n• GCash: Same day to 24 hours\n• Bank: 2-3 business days\n• Weekends add 1-2 days\n\n💵 Fees:\n• NONE! 0% fees\n• You receive full amount\n• ₱500 payout = ₱500 received\n\n🎯 Choose Based On:\n• Need fast? → GCash\n• Large amount? → Bank\n• Have both? → Set up both!'
      },
      {
        'question': 'How long does payout processing take?',
        'answer': '⏱️ Payout Timeline:\n\n📤 STEP 1: Submit Request\n• You: Request payout\n• Status: Pending\n• Time: Instant\n\n👀 STEP 2: Admin Review\n• Admin: Reviews request\n• Verifies: Account, amount, details\n• Status: Pending\n• Time: Within 24 hours\n• Usually: Same day if submitted AM\n\n✅ STEP 3: Approval & Processing\n• Admin: Approves request\n• Status: Processing\n• Admin: Sends payment\n• Time: Few hours\n\n💰 STEP 4: Payment Sent\n• Status: Completed\n• You: Receive notification\n\n📱 GCASH TOTAL TIME:\n• Best case: 2-6 hours\n• Average: 24 hours\n• Worst case: 48 hours\n• Weekend: Add 1-2 days\n\n🏦 BANK TRANSFER TOTAL TIME:\n• Best case: 1 business day\n• Average: 2-3 business days\n• Worst case: 5 business days\n• Weekend: Not counted\n\n⏰ Factors Affecting Speed:\n\n✅ Faster:\n• Submit on weekdays\n• Submit in morning (8am-12pm)\n• GCash payments\n• First payout (priority)\n\n⏳ Slower:\n• Weekend submissions\n• Late submissions (after 5pm)\n• Bank transfers\n• Holidays\n• High volume periods\n\n💡 Tips:\n• Submit Mon-Fri mornings\n• Use GCash for speed\n• Check payout history\n• Be patient on weekends'
      },
      {
        'question': 'What is minimum payout amount?',
        'answer': '💵 Minimum Payout: ₱100\n\n❓ Why ₱100 Minimum?\n• Reduces processing workload\n• Practical amount for farmers\n• Covers typical transaction\n• Industry standard\n\n✅ How It Works:\n\n📊 If Balance < ₱100:\n• Can\'t request payout yet\n• Keep selling and earning\n• Wait until ≥ ₱100\n• Button disabled/grayed out\n\n📊 If Balance ≥ ₱100:\n• Can request payout!\n• Minimum: ₱100\n• Maximum: Full balance\n• Choose any amount in range\n\n💡 Examples:\n\n❌ Balance = ₱80\n• Can\'t withdraw\n• Need ₱20 more\n• Complete more orders\n\n✅ Balance = ₱150\n• Can withdraw ₱100-₱150\n• Or wait for more\n• Your choice!\n\n✅ Balance = ₱1,000\n• Can withdraw ₱100-₱1,000\n• Take all or partial\n• Leave some for future\n\n🎯 Smart Strategies:\n\n1️⃣ Build Up Method:\n• Wait until ₱500-₱1,000\n• Withdraw less frequently\n• More meaningful amount\n• Less admin processing\n\n2️⃣ Regular Withdrawal:\n• Withdraw every ₱100\n• Keep cash flowing\n• Weekly income\n• Good for daily needs\n\n3️⃣ Monthly Method:\n• Collect for whole month\n• Withdraw once per month\n• Larger lump sum\n• Easier budgeting\n\n💰 No Maximum:\n• No limit on withdrawal amount\n• Withdraw entire balance if you want\n• Withdraw partially and save rest\n• Your money, your choice!'
      },
      {
        'question': 'How do I set up my payment details?',
        'answer': '⚙️ Setup Payment Details:\n\n📱 GCASH SETUP:\n\nSTEP 1: Go to Payment Settings\n• Profile → Payment Settings\n• Or Dashboard → Wallet → Payment Settings\n\nSTEP 2: Select GCash\n• Tap "GCash" option\n• Payment method selector\n\nSTEP 3: Enter Details\n• Mobile Number: 09XX XXX XXXX\n• Account Name: Your full name (as registered)\n• Example:\n  - Number: 0917 123 4567\n  - Name: Juan Dela Cruz\n\nSTEP 4: Verify & Save\n• Double-check number (no typos!)\n• Name must match GCash account\n• Tap "Save" button\n\n🏦 BANK TRANSFER SETUP:\n\nSTEP 1: Go to Payment Settings\n• Profile → Payment Settings\n\nSTEP 2: Select Bank Transfer\n• Tap "Bank Transfer" option\n\nSTEP 3: Enter Details\n• Account Number: Your bank account #\n• Bank Name: Select from dropdown\n  (BDO, BPI, LandBank, PNB, etc.)\n• Account Name: Full name on account\n• Branch: Optional but helpful\n\nSTEP 4: Save\n• Verify all details correct\n• Tap "Save" button\n\n⚠️ IMPORTANT:\n\n✅ Do:\n• Use YOUR account only\n• Enter exact registered name\n• Double-check numbers\n• Use active accounts\n\n❌ Don\'t:\n• Use someone else\'s account\n• Enter wrong numbers\n• Use closed accounts\n• Typos in name\n\n🔄 Can Change Anytime:\n• Edit payment details\n• Switch between GCash/Bank\n• Update if number changes\n• No penalty for changes\n\n💡 Pro Tips:\n• Set up both methods\n• Keep details updated\n• Verify before first payout\n• Screenshot for your records'
      },
      {
        'question': 'Why can\'t I request a payout?',
        'answer': '🚫 Can\'t Request Payout? Check:\n\n1️⃣ Insufficient Balance\n❌ Balance < ₱100\n• Check: Dashboard → Wallet\n• Solution: Complete more orders\n• Need: At least ₱100\n\n2️⃣ Not Verified\n❌ Account not verified\n• Check: Profile → Verification Status\n• Solution: Submit verification documents\n• Wait: 2-3 days for approval\n\n3️⃣ Payment Details Missing\n❌ No GCash/Bank info\n• Check: Profile → Payment Settings\n• Solution: Add payment method\n• Enter: Account details\n\n4️⃣ Pending Payout Request\n❌ Already have active request\n• Check: Wallet → Payout History\n• Status: "Pending" or "Processing"\n• Solution: Wait for completion\n• Then: Request again\n\n5️⃣ No Completed Orders\n❌ All earnings still pending\n• Check: Wallet → Pending Earnings\n• Solution: Complete and deliver orders\n• Then: Earnings move to Available Balance\n\n6️⃣ Account Suspended\n❌ Suspended by admin\n• Check: Notifications\n• Reason: Violations, complaints\n• Solution: Contact admin support\n• Resolve: Issues first\n\n7️⃣ System Maintenance\n❌ Temporary downtime\n• Rare occurrence\n• Solution: Try again later\n• Usually: Few hours\n\n✅ Quick Checklist:\n□ Verified? ✓\n□ Balance ≥ ₱100? ✓\n□ Payment details added? ✓\n□ No pending payout? ✓\n□ Orders completed? ✓\n\n💡 If All Checked:\n• Button should work\n• Try: Restart app\n• Still issue? Contact support'
      },
      {
        'question': 'How do I check my wallet balance?',
        'answer': '💰 Check Wallet Balance:\n\n📍 LOCATION 1: Dashboard\n• Open app → Dashboard\n• See "Wallet" card/section\n• Shows quick summary:\n  - Available Balance\n  - Pending Earnings\n  - Recent transactions\n\n📍 LOCATION 2: Full Wallet View\n• Dashboard → Tap "Wallet"\n• Or Profile → Wallet\n• See complete details:\n\n📊 Wallet Breakdown:\n\n💵 Available Balance:\n• Money ready to withdraw\n• From completed orders\n• Can request payout now\n• Green amount/positive\n\n⏳ Pending Earnings:\n• Orders in progress\n• Not yet completed/delivered\n• Will become available later\n• Yellow amount/processing\n\n📈 Total Earnings:\n• Lifetime earnings\n• All time total\n• Historical reference\n• Shows your success!\n\n📜 Recent Transactions:\n• Last 10 transactions\n• Order completions\n• Payout requests\n• Date and amount\n\n💡 Understanding Balances:\n\nExample Scenario:\n• 3 completed orders: ₱900\n  → Available Balance: ₱900\n  → Can withdraw now\n\n• 2 active orders: ₱400\n  → Pending Earnings: ₱400\n  → Complete first, then withdraw\n\n• Total Earnings: ₱5,000\n  → All time earnings\n  → Already withdrawn: ₱3,700\n\n🔄 Real-Time Updates:\n• Balance updates immediately\n• After marking order delivered\n• After payout processed\n• Auto-refresh on app open\n\n📱 Quick Access:\n• Dashboard widget shows balance\n• No need to navigate deep\n• Check anytime, anywhere'
      },
      {
        'question': 'What is available balance vs pending earnings?',
        'answer': '💰 Balance Types Explained:\n\n✅ AVAILABLE BALANCE:\n\n❓ What Is It?\n• Money from COMPLETED orders\n• Orders marked "Delivered/Picked Up"\n• Payment already collected\n• Ready to withdraw NOW\n\n💵 Characteristics:\n• ✅ Can withdraw anytime\n• ✅ Minimum ₱100\n• ✅ 100% yours\n• ✅ No waiting period\n\n📊 Increases When:\n• You mark order as delivered\n• Payment auto-added\n• Instantly available\n\n⏳ PENDING EARNINGS:\n\n❓ What Is It?\n• Money from IN-PROGRESS orders\n• Orders not yet delivered\n• Status: Accepted, Preparing, On The Way\n• Will become available LATER\n\n⏰ Characteristics:\n• ❌ Can\'t withdraw yet\n• ⏳ Waiting for completion\n• 📦 Complete orders first\n• ✅ Then becomes available\n\n📊 Increases When:\n• You accept new orders\n• Buyer places order\n• Shows potential earnings\n\n🔄 Movement Flow:\n\nSTEP 1: Order Placed\n• ₱200 order accepted\n• Pending Earnings: +₱200\n• Available Balance: No change\n\nSTEP 2: Order Delivered\n• Mark as delivered\n• Pending Earnings: -₱200\n• Available Balance: +₱200\n\nSTEP 3: Request Payout\n• Withdraw ₱200\n• Available Balance: -₱200\n• Money in your GCash/Bank: +₱200\n\n💡 Real Example:\n\n📊 Current Status:\n• Available Balance: ₱800\n  (5 completed orders)\n• Pending Earnings: ₱400\n  (2 active orders)\n• Total: ₱1,200\n\n✅ Can Do Now:\n• Withdraw up to ₱800\n• Wait for ₱400 to complete\n\n⏰ After Completing 2 Orders:\n• Available Balance: ₱1,200\n• Pending Earnings: ₱0\n• Can withdraw full ₱1,200\n\n🎯 Key Takeaway:\n• Available = Withdraw now\n• Pending = Complete orders first'
      },
      {
        'question': 'Do you charge commission?',
        'answer': '🎉 ZERO COMMISSION! 🎉\n\n💯 You Keep 100%:\n\n✅ What This Means:\n• ₱500 sale = ₱500 earnings\n• ₱1,000 sale = ₱1,000 earnings\n• ₱10,000 sale = ₱10,000 earnings\n• NO deductions!\n• NO hidden fees!\n• NO percentage taken!\n\n💰 Examples:\n\n📦 Order 1:\n• Buyer pays: ₱350\n• Commission: ₱0\n• You receive: ₱350\n• Platform keeps: ₱0\n\n📦 Order 2:\n• Buyer pays: ₱1,250\n• Commission: ₱0\n• You receive: ₱1,250\n• Platform keeps: ₱0\n\n🆚 Compare to Others:\n\n❌ Other Platforms:\n• Shopee: 5-10% commission\n• Lazada: 5-15% commission\n• Facebook Marketplace: Payment fees\n• Example: ₱1,000 sale = ₱850-950 for you\n\n✅ Agrilink:\n• Commission: 0%\n• Example: ₱1,000 sale = ₱1,000 for you\n• Difference: ₱50-150 MORE per sale!\n\n🤔 How We Make Money:\n\n⭐ Premium Subscriptions:\n• Farmers can upgrade for benefits\n• Unlimited products\n• Featured placement\n• Optional, not required\n• Farmers choose to upgrade\n\n💡 Why 0% Commission?\n\n🌾 Support Farmers:\n• Direct farm-to-buyer\n• Maximize farmer income\n• Fair pricing for buyers\n• Build sustainable agriculture\n\n🎯 Our Mission:\n• Help farmers earn MORE\n• Make farming profitable\n• Support local agriculture\n• Connect communities\n\n✅ Verified:\n• Check your wallet\n• Order amount = Earnings amount\n• No deductions ever\n• Complete transparency\n\n💚 Thank you for choosing Agrilink!\n• Keep 100% of your hard work\n• Grow your farming business\n• We grow when you grow!'
      },
    ],
    'premium_subscription': [
      {
        'question': 'What is Premium subscription?',
        'answer': '⭐ Premium Subscription Explained:\n\n🎯 WHAT YOU GET:\n\n1️⃣ Unlimited Products:\n• FREE Tier: Maximum 3 products\n• PREMIUM: Unlimited products!\n• Sell all your crop varieties\n• No restrictions on listings\n\n2️⃣ More Photos Per Product:\n• FREE: 4 photos per product\n• PREMIUM: 5 photos per product\n• Show products from more angles\n• Better product presentation\n\n3️⃣ Featured on Homepage:\n• Your products appear in premium carousel\n• Shown to ALL buyers on home screen\n• Daily rotation system\n• Featured up to 10 products daily\n• Massive visibility boost!\n\n4️⃣ Priority in Search:\n• Your products rank FIRST\n• Appear before free tier farmers\n• Higher in category browsing\n• More buyer views\n\n5️⃣ Gold Premium Badge:\n• ⭐ Gold star on your profile\n• Shows on all your products\n• Trust signal for buyers\n• Professional appearance\n• Stands out from competitors\n\n💰 PRICING:\n\n📅 Monthly Plan:\n• Cost: ₱299 per month\n• Billed monthly\n• Cancel anytime\n• No commitment\n• Try before committing\n\n📆 Annual Plan (BEST VALUE!):\n• Cost: ₱2,999 per year\n• Save ₱589 compared to monthly!\n• That\'s 2 months FREE\n• One-time payment\n• Worry-free for whole year\n\n🧮 Comparison:\n• Monthly × 12 = ₱3,588/year\n• Annual = ₱2,999/year\n• Your Savings = ₱589/year\n\n📈 WHY UPGRADE?\n\n✅ More Sales:\n• Featured placement = 3-5x more views\n• Priority in search = more clicks\n• Premium badge = more trust\n• More products = more options for buyers\n\n✅ Professional Image:\n• Gold badge shows commitment\n• Better than competitors\n• Buyers prefer premium sellers\n• Builds credibility\n\n✅ Business Growth:\n• Expand your product range\n• Reach more buyers\n• Increase monthly earnings\n• Scale your farming business\n\n💡 IS IT WORTH IT?\n\n🎯 Premium pays for itself if:\n• You have more than 3 products\n• You get just 2-3 extra orders/month\n• Example: ₱299 cost, 2 orders × ₱200 = ₱400 gain = Profit!\n\n✅ Recommended For:\n• Farmers with multiple crops\n• Serious sellers\n• Year-round farmers\n• Those wanting to grow business\n• Professional farmers\n\n❌ Stick with Free If:\n• Just starting out\n• Testing the platform\n• Only 1-2 products\n• Seasonal farmer\n• Limited product variety\n\n🚀 HOW TO SUBSCRIBE:\n\nSTEP 1: Go to Subscription\n• Profile → Subscription\n• Or Dashboard → "Upgrade to Premium"\n\nSTEP 2: Choose Your Plan\n• Monthly: ₱299\n• Annual: ₱2,999 (recommended)\n• Compare benefits\n• Select preferred option\n\nSTEP 3: See Payment Details\n• Admin GCash number displayed\n• Amount to pay shown\n• Reference instructions given\n\nSTEP 4: Send Payment via GCash\n• Open your GCash app\n• Send to admin number\n• Exact amount (₱299 or ₱2,999)\n• Add reference: Your farm name\n\nSTEP 5: Upload Payment Proof\n• Take screenshot of GCash receipt\n• Back to Agrilink app\n• Upload the screenshot\n• Add transaction reference number\n\nSTEP 6: Submit for Verification\n• Tap "Submit Request"\n• Admin reviews payment\n• Usually approved within 24 hours\n• Faster during weekdays\n\nSTEP 7: Get Activated!\n• Receive approval notification\n• Gold ⭐ badge appears immediately\n• Features unlock instantly\n• Start adding unlimited products!\n• Get featured on homepage!\n\n⏱️ ACTIVATION TIME:\n• Submit: Instant\n• Admin Review: Within 24 hours\n• Approval: Usually same day (weekdays)\n• Weekend: May take 1-2 days\n• Activation: Immediate after approval\n\n🎉 AFTER ACTIVATION:\n\n✅ Immediate Benefits:\n• Gold badge on your profile\n• Add unlimited products right away\n• Upload 5 photos per product\n• Featured in premium carousel\n• Priority search placement starts\n• Buyers see you first!\n\n📊 Track Your Results:\n• Check sales analytics\n• Compare before/after premium\n• See increased views\n• Track extra orders\n• Measure ROI\n\n🔄 RENEWAL:\n\n📅 Monthly:\n• Auto-expires after 30 days\n• Re-subscribe same way\n• No auto-renewal (manual)\n\n📆 Annual:\n• Valid for 365 days\n• Reminder before expiry\n• Re-subscribe for next year\n\n❓ Can I Switch Plans?\n• Yes! Upgrade from monthly to annual\n• Contact admin for plan changes\n• Pro-rated adjustments available\n\n💚 OUR PROMISE:\n• More visibility guaranteed\n• Priority placement confirmed\n• Featured carousel rotation\n• No hidden fees\n• Cancel anytime (no penalty)\n\n🎯 SUCCESS STORIES:\n• Farmers report 2-3x more orders\n• Premium badge increases trust\n• Featured products sell faster\n• More buyer inquiries\n• Better long-term earnings\n\n💡 PRO TIP:\n• Start with monthly to test\n• Track your sales increase\n• Upgrade to annual if working\n• Save ₱589 per year!\n\n✅ Ready to Grow Your Business?\nUpgrade to Premium and watch your sales increase!'
      },
      {
        'question': 'How much does Premium cost?',
        'answer': '💰 Premium Subscription Pricing:\n\n📊 TWO PLANS AVAILABLE:\n\n📅 PLAN 1: MONTHLY\n• Price: ₱299 per month\n• Billing: Every 30 days\n• Commitment: None\n• Cancel: Anytime\n• Best for: Testing premium, new sellers\n\n📆 PLAN 2: ANNUAL (RECOMMENDED! 💚)\n• Price: ₱2,999 per year\n• Billing: Once per year\n• Commitment: 12 months\n• Cancel: After 1 year\n• Best for: Serious sellers, save money\n\n🧮 COST COMPARISON:\n\nMonthly Plan:\n• ₱299 × 12 months = ₱3,588/year\n• Flexible but costs more\n• Good for trying premium\n\nAnnual Plan:\n• ₱2,999 for full year\n• Save ₱589 compared to monthly!\n• That\'s 2 months FREE\n• Better value for committed sellers\n\n💡 SAVINGS BREAKDOWN:\n• Monthly total: ₱3,588/year\n• Annual cost: ₱2,999/year\n• Your savings: ₱589/year\n• Percentage saved: 16.4%\n\n📈 RETURN ON INVESTMENT:\n\n💵 If You\'re Free Tier:\n• Limited to 3 products\n• No featured placement\n• Standard search ranking\n• Average: 5-10 orders/month\n• Monthly earnings: ₱1,500-3,000\n\n⭐ With Premium:\n• Unlimited products\n• Featured on homepage\n• Priority in search\n• Average: 15-25 orders/month (2-3x more!)\n• Monthly earnings: ₱4,500-7,500\n\n🎯 BREAK-EVEN ANALYSIS:\n\n📊 Monthly Plan (₱299):\n• Need just 2-3 extra orders to profit\n• If avg order = ₱150\n• 2 extra orders = ₱300\n• Profit = ₱300 - ₱299 = ₱1!\n• But typically get 5-10 extra orders\n• Real profit = ₱450-1,200/month\n\n📊 Annual Plan (₱2,999):\n• ₱2,999 ÷ 12 = ₱250/month\n• Need only 2 extra orders/month\n• Break even in first month!\n• Rest of year = pure profit\n\n💡 IS IT AFFORDABLE?\n\n✅ YES, because:\n• ₱299/month = ₱10/day\n• Less than a meal out\n• Less than transportation daily\n• Invests in your business\n• Returns multiply the cost\n\n📊 Compare to Other Platforms:\n\nShopee/Lazada:\n• FREE to list\n• BUT: 5-15% commission per sale\n• Example: ₱1,000 sale = ₱850-950 for you\n• Commission = ₱50-150 EVERY sale\n\nAgrilink Premium:\n• ₱299/month flat fee\n• 0% commission\n• Example: ₱1,000 sale = ₱1,000 for you\n• Keep 100% of earnings!\n• Premium pays off after 2-6 sales\n\n🎯 WHO SHOULD UPGRADE?\n\n✅ Upgrade to Premium If:\n• You have 4+ products\n• Selling year-round\n• Want more visibility\n• Serious about farming business\n• Already making regular sales\n• Want to grow faster\n\n⏸️ Stay Free If:\n• Just starting out\n• Only 1-3 products\n• Testing the platform\n• Seasonal farmer\n• Limited product variety\n\n💡 RECOMMENDATION BY EARNINGS:\n\n📊 If you earn < ₱3,000/month:\n• Start with free tier\n• Build customer base\n• Upgrade when ready\n\n📊 If you earn ₱3,000-₱10,000/month:\n• Try monthly premium (₱299)\n• Test the benefits\n• Upgrade to annual if working\n\n📊 If you earn > ₱10,000/month:\n• Go annual immediately (₱2,999)\n• Save money\n• Maximize visibility\n• Best ROI\n\n🎁 WHAT\'S INCLUDED?\n\nYour ₱299/month or ₱2,999/year includes:\n• ✅ Unlimited product listings\n• ✅ 5 photos per product\n• ✅ Featured homepage carousel\n• ✅ Priority search ranking\n• ✅ Gold premium badge\n• ✅ Daily rotation showcase\n• ✅ All free tier features\n• ✅ 0% commission (keep 100%!)\n\n❌ What\'s NOT Included:\n• Transaction fees: NONE\n• Commission: 0%\n• Hidden charges: NONE\n• Payout fees: FREE\n• Extra costs: NONE\n\n💳 PAYMENT METHODS:\n• GCash only\n• One-time payment\n• No auto-renewal\n• Manual subscription\n\n⏱️ VALIDITY PERIOD:\n• Monthly: 30 days from activation\n• Annual: 365 days from activation\n• Expires automatically\n• Re-subscribe manually\n\n🔄 AFTER EXPIRY:\n• Return to free tier\n• Keep your products\n• Lose premium features\n• Can re-subscribe anytime\n\n💚 GUARANTEE:\n• Try premium risk-free\n• See increased sales\n• Cancel anytime (no penalty)\n• Re-subscribe if needed\n\n🎯 FINAL RECOMMENDATION:\n\n🆓 Free Tier:\n• Good for: Beginners, 1-3 products\n• Cost: ₱0\n• Commission: 0%\n\n📅 Premium Monthly:\n• Good for: Testing, 4-10 products\n• Cost: ₱299/month\n• Commission: 0%\n• Visibility: 3x higher\n\n📆 Premium Annual:\n• Good for: Serious sellers, 10+ products\n• Cost: ₱2,999/year (₱250/month)\n• Commission: 0%\n• Visibility: 3x higher\n• BEST VALUE! Save ₱589!\n\n💡 Most farmers start monthly, then upgrade to annual after seeing results!'
      },
      {
        'question': 'How do I subscribe to Premium?',
        'answer': '⭐ Complete Premium Subscription Guide:\n\n🎯 STEP-BY-STEP PROCESS:\n\n━━━━━━━━━━━━━━━━━━━━━━\nSTEP 1: Navigate to Subscription\n━━━━━━━━━━━━━━━━━━━━━━\n\n📱 Method 1 (Profile):\n• Open Agrilink app\n• Tap Profile icon (bottom right)\n• Scroll down\n• Tap "Subscription" or "Upgrade to Premium"\n\n📱 Method 2 (Dashboard):\n• Go to Farmer Dashboard\n• Look for "Upgrade" banner/card\n• Tap "Upgrade to Premium"\n\n📱 Method 3 (Notification):\n• If you hit product limit (3 products)\n• App shows upgrade prompt\n• Tap "Upgrade Now"\n\n━━━━━━━━━━━━━━━━━━━━━━\nSTEP 2: Choose Your Plan\n━━━━━━━━━━━━━━━━━━━━━━\n\n📊 You\'ll see two options:\n\n📅 MONTHLY:\n✓ Price: ₱299/month\n✓ Best for: Testing premium\n✓ Flexibility: High\n✓ Commitment: 30 days\n\n📆 ANNUAL (Recommended!):\n✓ Price: ₱2,999/year\n✓ Best for: Serious sellers\n✓ Savings: ₱589/year\n✓ Commitment: 365 days\n\n💡 Tap your preferred plan\n• Read benefits listed\n• Check pricing\n• Select by tapping the card\n\n━━━━━━━━━━━━━━━━━━━━━━\nSTEP 3: Review Payment Details\n━━━━━━━━━━━━━━━━━━━━━━\n\n📋 You\'ll see:\n• Admin GCash number\n• Exact amount to pay\n• Your reference code\n• Payment instructions\n\n💡 IMPORTANT:\n• Screenshot this screen OR\n• Write down the GCash number\n• Note the exact amount\n• Remember your reference\n\n━━━━━━━━━━━━━━━━━━━━━━\nSTEP 4: Send Payment via GCash\n━━━━━━━━━━━━━━━━━━━━━━\n\n📱 Open GCash App:\n\n1️⃣ Tap "Send Money"\n2️⃣ Select "To Mobile Number"\n3️⃣ Enter admin GCash number\n   (shown in Agrilink app)\n4️⃣ Enter exact amount:\n   • ₱299 (monthly) OR\n   • ₱2,999 (annual)\n5️⃣ Add message/reference:\n   • Type your farm name\n   • Or your Agrilink username\n6️⃣ Review transaction\n7️⃣ Enter your MPIN\n8️⃣ Confirm payment\n\n✅ Payment Sent!\n• Keep GCash receipt\n• Don\'t close GCash yet\n• Take screenshot next\n\n━━━━━━━━━━━━━━━━━━━━━━\nSTEP 5: Take Screenshot\n━━━━━━━━━━━━━━━━━━━━━━\n\n📸 Capture GCash Receipt:\n\n✓ Show transaction success\n✓ Show amount paid\n✓ Show reference number\n✓ Show date/time\n✓ Show recipient (admin number)\n\n💡 Screenshot Tips:\n• Clear and readable\n• All details visible\n• No blurry images\n• No cropped information\n\n━━━━━━━━━━━━━━━━━━━━━━\nSTEP 6: Upload Payment Proof\n━━━━━━━━━━━━━━━━━━━━━━\n\n📱 Back to Agrilink App:\n\n1️⃣ Return to subscription screen\n2️⃣ Tap "Upload Payment Proof"\n3️⃣ Select screenshot from gallery\n4️⃣ Crop if needed (ensure clarity)\n5️⃣ Confirm upload\n\n📝 Add Transaction Details:\n• Reference Number: (from GCash)\n• Amount Paid: ₱299 or ₱2,999\n• Payment Date: Today\'s date\n• Optional Notes: Your message\n\n━━━━━━━━━━━━━━━━━━━━━━\nSTEP 7: Submit for Verification\n━━━━━━━━━━━━━━━━━━━━━━\n\n✓ Review all information:\n  • Plan selected\n  • Amount paid\n  • Screenshot uploaded\n  • Details correct\n\n✓ Tap "Submit Request" button\n✓ Confirmation message appears\n✓ Status changes to "Pending"\n\n📧 You\'ll receive:\n• In-app notification\n• Confirmation message\n• Request ID number\n\n━━━━━━━━━━━━━━━━━━━━━━\nSTEP 8: Wait for Admin Approval\n━━━━━━━━━━━━━━━━━━━━━━\n\n⏱️ Processing Time:\n\n📅 Weekdays (Mon-Fri):\n• Morning submission (8am-12pm): Same day\n• Afternoon submission (12pm-5pm): Same day or next day\n• Evening submission (after 5pm): Next day\n• Average: 4-12 hours\n\n📅 Weekends (Sat-Sun):\n• May take 1-2 days\n• Admin reviews on Monday\n• Be patient during weekends\n\n💡 During Wait:\n• Check notifications regularly\n• Status shows in Subscription tab\n• No need to resubmit\n• Contact support if >48 hours\n\n━━━━━━━━━━━━━━━━━━━━━━\nSTEP 9: Approval & Activation\n━━━━━━━━━━━━━━━━━━━━━━\n\n🎉 When Approved:\n\n✅ Instant Changes:\n• Notification: "Premium Activated!"\n• Gold ⭐ badge appears on profile\n• Product limit removed\n• Featured carousel access\n• Priority search enabled\n\n📱 What You\'ll See:\n• Subscription Status: "Active"\n• Tier: "Premium"\n• Valid Until: [Date]\n• Features: All unlocked\n\n━━━━━━━━━━━━━━━━━━━━━━\nSTEP 10: Start Using Premium!\n━━━━━━━━━━━━━━━━━━━━━━\n\n🚀 Immediate Actions:\n\n1️⃣ Add More Products:\n• No longer limited to 3\n• Add all your crop varieties\n• Upload 5 photos each\n\n2️⃣ Check Featured Carousel:\n• Your products rotating on homepage\n• Visible to all buyers\n• Daily rotation system\n\n3️⃣ Verify Premium Badge:\n• Visit your store profile\n• Gold ⭐ badge visible\n• Shows on all products\n\n4️⃣ Monitor Results:\n• Check analytics daily\n• Track increased views\n• Count new orders\n• Measure ROI\n\n━━━━━━━━━━━━━━━━━━━━━━\n⚠️ TROUBLESHOOTING\n━━━━━━━━━━━━━━━━━━━━━━\n\n❌ Payment Not Approved?\n\nPossible Reasons:\n1. Incorrect amount sent\n2. Wrong GCash number\n3. Screenshot unclear\n4. Missing reference\n5. Duplicate submission\n\nSolution:\n• Check notification for reason\n• Contact admin support\n• Resubmit if requested\n• Provide clearer proof\n\n❌ Didn\'t Receive GCash Receipt?\n• Check GCash transaction history\n• Take screenshot from history\n• Use that for proof\n\n❌ Uploaded Wrong Screenshot?\n• Contact admin immediately\n• Explain the situation\n• Upload correct screenshot\n• Admin can update manually\n\n━━━━━━━━━━━━━━━━━━━━━━\n💡 PRO TIPS\n━━━━━━━━━━━━━━━━━━━━━━\n\n✓ Submit on weekday mornings for faster approval\n✓ Use clear screenshots with all details visible\n✓ Add your farm name in GCash reference\n✓ Keep GCash receipt for your records\n✓ Screenshot the payment details page in Agrilink\n✓ Double-check amount before sending\n✓ Wait for approval before resubmitting\n✓ Check notifications for updates\n\n━━━━━━━━━━━━━━━━━━━━━━\n📞 NEED HELP?\n━━━━━━━━━━━━━━━━━━━━━━\n\n💬 Contact Support:\n• In-app: Profile → Help & Support\n• Email: farmer-support@agrilink.ph\n• Chat: AI Support Assistant\n\n🎉 Congratulations on upgrading to Premium!\nWatch your sales grow! 📈'
      },
    ],
    'store': [
      {
        'question': 'How do I customize my store?',
        'answer': '🏪 Store Customization:\n\n1️⃣ Store Banner:\n• Profile → Store Customization\n• Upload banner (1200×400px)\n• Shows at top of store\n\n2️⃣ Farm Information:\n• Add farm details\n• Location, size, methods\n• Your farming story\n\n3️⃣ Store Description:\n• Write about your farm\n• Highlight unique features\n• Max 500 characters\n\n💡 Professional store = More buyers!'
      },
    ],
    'delivery': [
      {
        'question': 'How does delivery work?',
        'answer': '🚚 Delivery Options:\n\n1️⃣ HOME DELIVERY:\n• You arrange transport\n• Buyer pays delivery fee\n• Based on distance\n\n2️⃣ PICKUP:\n• Buyer collects from you\n• No delivery fee\n• Set pickup address\n\n💡 Offer both for more sales!'
      },
    ],
    'payment': [
      {
        'question': 'What payment methods do buyers use?',
        'answer': '💳 Payment Methods:\n\n🆓 COD (Cash on Delivery):\n• Collect cash when delivering\n• Keep 100% immediately\n\n💳 GCash Prepaid:\n• Buyer pays upfront\n• Admin verifies\n• Added to wallet after delivery\n\n✅ Both methods: 0% commission!'
      },
    ],
    'review': [
      {
        'question': 'How do reviews work?',
        'answer': '⭐ Reviews:\n\n📊 After Delivery:\n• Buyer can leave 1-5 star rating\n• Write comments\n• Upload photos\n• Shows on your profile\n\n💡 Get Good Reviews:\n• Quality products\n• Fast delivery\n• Good communication\n• Professional service\n\n🏆 Higher rating = More sales!'
      },
    ],
    'analytics': [
      {
        'question': 'How do I view my sales?',
        'answer': '📊 Sales Analytics:\n\n📍 Location:\n• Dashboard → Sales Analytics\n\n📈 See:\n• Total earnings\n• Orders completed\n• Top products\n• Monthly trends\n• Revenue charts\n\n💡 Use to track growth!'
      },
    ],
    'account': [
      {
        'question': 'How do I update my profile?',
        'answer': '👤 Update Profile:\n\n1️⃣ Go to Profile\n• Tap Profile icon\n\n2️⃣ Edit:\n• Tap "Edit Profile"\n• Update photo, name, phone\n• Add bio\n\n3️⃣ Save:\n• Changes visible immediately\n\n💡 Complete profile = More trust!'
      },
    ],
    'photo': [
      {
        'question': 'Product photography tips?',
        'answer': '📸 Photography Tips:\n\n☀️ LIGHTING:\n• Natural daylight best\n• Avoid shadows\n• No flash\n\n🎯 COMPOSITION:\n• Clean background\n• Center product\n• Multiple angles\n\n🔍 QUALITY:\n• Sharp focus\n• Vibrant colors\n• Show freshness\n\n💡 Good photos = 3x more sales!'
      },
    ],
    'tips': [
      {
        'question': 'Tips for better sales?',
        'answer': '🚀 Increase Sales:\n\n1️⃣ Quality products always\n2️⃣ Great photos\n3️⃣ Competitive pricing\n4️⃣ Fast response\n5️⃣ On-time delivery\n6️⃣ Build good reviews\n7️⃣ Update stock regularly\n8️⃣ Consider Premium\n\n💡 Quality + Communication = Success!'
      },
    ],
  };

  // Greeting messages (friendly and culturally appropriate)
  static const List<String> _greetings = [
    'Hello! 👋 I\'m your Agrilink farming assistant. How can I help you today?',
    'Hi there! 🌾 Welcome to farmer support. What would you like to know?',
    'Greetings! 🚜 I\'m here to help with your farming business. What can I assist you with?',
    'Kumusta! 🌱 I\'m here to support your farming journey. Ask me anything!',
    'Magandang araw! ☀️ How can I assist you with your farm today?',
  ];

  // Default responses when no match is found (friendly and helpful)
  static const List<String> _defaultResponses = [
    'I\'m not quite sure about that. 🤔 But don\'t worry! Here are some topics I can help with:\n\n• Getting verified as a farmer ✅\n• Adding and managing products 📦\n• Handling orders and deliveries 🚚\n• Requesting payouts (0% commission!) 💰\n• Premium subscription benefits ⭐\n• Store customization 🏪\n• Tips for better sales 📈\n• Analytics and reports 📊\n\nWhat would you like to know more about?',
    'Hmm, I don\'t have specific information about that. 💭 Let me suggest some common topics:\n\n🔐 Verification Process\n📦 Product Management\n📋 Order Handling\n💰 Payout System (0% commission!)\n⭐ Premium Benefits\n🏪 Store Customization\n📸 Photography Tips\n📊 Sales Analytics\n\nPlease ask about any of these! I\'m here to help. 😊',
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
      // Friendly greetings with a warm tone
      final greetingResponses = [
        'Hello! 👋 How can I assist you with your farming business today? Feel free to ask about verification, products, orders, payouts, or anything else!',
        'Hi there! 🌾 Great to see you! What would you like to know about selling on Agrilink?',
        'Kumusta! 🌱 I\'m here to help you succeed as a farmer. What can I assist you with today?',
      ];
      return greetingResponses[DateTime.now().millisecond % greetingResponses.length];
    }

    // Check for thanks
    if (_isThanks(input)) {
      final thanksResponses = [
        'You\'re welcome! 😊 Is there anything else I can help you with?',
        'Happy to help! 💚 Feel free to ask if you have more questions.',
        'Walang anuman! 🌾 I\'m always here if you need assistance.',
      ];
      return thanksResponses[DateTime.now().millisecond % thanksResponses.length];
    }

    // Try intent detection first
    final intent = _extractIntent(input);
    if (intent != null) {
      final intentMap = {
        'add_product': 'product',
        'request_payout': 'payout',
        'verification': 'verification',
        'payout': 'payout',
        'premium': 'premium_subscription',
        'order': 'order',
      };
      
      final category = intentMap[intent];
      if (category != null) {
        final faqs = _faqs[category] ?? [];
        if (faqs.isNotEmpty) {
          // For specific intents, return the first FAQ directly
          if (intent == 'add_product' && faqs.isNotEmpty) {
            return faqs[0]['answer']!; // "How do I add a new product?"
          }
          if (intent == 'request_payout' && faqs.isNotEmpty) {
            return faqs[0]['answer']!; // "How do I request a payout?"
          }
        }
      }
    }

    // Enhanced keyword matching with better scoring
    String? bestMatchedCategory;
    int maxMatches = 0;
    double bestScore = 0.0;

    for (var entry in _keywords.entries) {
      int matches = 0;
      for (var keyword in entry.value) {
        if (input.contains(keyword)) {
          matches++;
        }
      }
      
      // Calculate a score based on both match count and keyword relevance
      double score = matches.toDouble();
      
      if (matches > maxMatches || (matches == maxMatches && score > bestScore)) {
        maxMatches = matches;
        bestScore = score;
        bestMatchedCategory = entry.key;
      }
    }

    // If we found a matching category, search for the best FAQ
    if (bestMatchedCategory != null && maxMatches > 0) {
      final faqs = _faqs[bestMatchedCategory] ?? [];
      if (faqs.isNotEmpty) {
        // Find the most relevant FAQ with improved matching
        FAQ? bestMatch;
        double bestSimilarity = 0.0;
        
        for (var faq in faqs) {
          final question = faq['question']!.toLowerCase();
          final similarity = _calculateSimilarity(input, question);
          final hasKeywords = _containsKeyWords(input, question);
          
          // Boost score if keywords match
          final finalScore = hasKeywords ? similarity + 0.3 : similarity;
          
          if (finalScore > bestSimilarity) {
            bestSimilarity = finalScore;
            bestMatch = faq;
          }
        }
        
        // Return best match if similarity is good enough
        if (bestMatch != null && bestSimilarity > 0.2) {
          return bestMatch['answer']!;
        }
        
        // Otherwise, return category FAQs
        return _formatCategoryFaqs(bestMatchedCategory, faqs);
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
    const greetings = [
      'hello', 'hi', 'hey', 'greetings',
      'good morning', 'good afternoon', 'good evening',
      'kumusta', 'kamusta', 'musta', 'magandang umaga', 'magandang hapon', 'magandang gabi',
      'maayong buntag', 'maayong hapon', 'maayong gabii', // Bisaya
    ];
    return greetings.any((g) => input.contains(g));
  }

  /// Check if input is thanks
  bool _isThanks(String input) {
    const thanks = [
      'thank', 'thanks', 'thank you', 'appreciate', 'helpful',
      'salamat', 'maraming salamat', 'thank u', 'thankyou',
      'salamat kaayo', 'daghang salamat', // Bisaya
    ];
    return thanks.any((t) => input.contains(t));
  }

  /// Calculate similarity between two strings (enhanced for long sentences)
  double _calculateSimilarity(String s1, String s2) {
    // Remove common question words and normalize
    final stopWords = ['how', 'do', 'i', 'the', 'a', 'an', 'to', 'is', 'are', 'what', 'when', 'where', 'can', 'my', 'me', 'you'];
    
    final words1 = s1.toLowerCase().split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !stopWords.contains(w))
        .toList();
    
    final words2 = s2.toLowerCase().split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !stopWords.contains(w))
        .toList();
    
    if (words1.isEmpty || words2.isEmpty) return 0.0;
    
    int commonWords = 0;
    int partialMatches = 0;
    
    for (var word1 in words1) {
      for (var word2 in words2) {
        // Exact match
        if (word1 == word2) {
          commonWords++;
          break;
        }
        // Partial match (one word contains the other)
        if (word1.length > 3 && word2.length > 3) {
          if (word1.contains(word2) || word2.contains(word1)) {
            partialMatches++;
            break;
          }
        }
      }
    }
    
    // Calculate weighted similarity score
    final exactScore = commonWords / words1.length;
    final partialScore = (partialMatches * 0.5) / words1.length;
    
    return exactScore + partialScore;
  }

  /// Check if input contains key words from question (enhanced)
  bool _containsKeyWords(String input, String question) {
    // Extract meaningful keywords from question
    final stopWords = ['how', 'do', 'i', 'the', 'a', 'an', 'to', 'is', 'are', 'what', 'when', 'where', 'can', 'my', 'me', 'you'];
    
    final questionWords = question.toLowerCase().split(RegExp(r'\s+'))
        .where((w) => w.length > 3 && !stopWords.contains(w))
        .toList();
    
    if (questionWords.isEmpty) return false;
    
    final inputLower = input.toLowerCase();
    int matches = 0;
    
    for (var word in questionWords) {
      if (inputLower.contains(word)) {
        matches++;
      }
    }
    
    // More lenient matching: need at least 1 match for short questions, 2+ for longer ones
    if (questionWords.length <= 3) {
      return matches >= 1;
    } else if (questionWords.length <= 5) {
      return matches >= 2;
    } else {
      return matches >= 3;
    }
  }

  /// Extract key intent from user input
  String? _extractIntent(String input) {
    final inputLower = input.toLowerCase();
    
    // Question patterns
    if (inputLower.contains('how') && (inputLower.contains('add') || inputLower.contains('create'))) {
      if (inputLower.contains('product')) return 'add_product';
      if (inputLower.contains('payout') || inputLower.contains('withdraw')) return 'request_payout';
    }
    
    if (inputLower.contains('verify') || inputLower.contains('verification')) {
      return 'verification';
    }
    
    if (inputLower.contains('payout') || inputLower.contains('withdraw') || inputLower.contains('earnings')) {
      return 'payout';
    }
    
    if (inputLower.contains('premium') || inputLower.contains('subscription') || inputLower.contains('upgrade')) {
      return 'premium';
    }
    
    if (inputLower.contains('product') && (inputLower.contains('add') || inputLower.contains('list') || inputLower.contains('sell'))) {
      return 'add_product';
    }
    
    if (inputLower.contains('order') || inputLower.contains('accept') || inputLower.contains('deliver')) {
      return 'order';
    }
    
    return null;
  }

  /// Get quick reply suggestions based on context
  List<String> getQuickReplies() {
    if (_messages.length <= 1) {
      return [
        'How do I add products?',
        'How does payout work?',
        'Premium benefits?',
        'View all topics',
      ];
    }

    // Return contextual quick replies
    return [
      'Tell me more',
      'Show me how',
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
      '🔐 How do I get verified?',
      '📦 How do I add products?',
      '📋 How do I handle orders?',
      '💰 How do I request a payout?',
      '⭐ What is Premium subscription?',
      '📸 Product photography tips',
      '🏪 How do I customize my store?',
      '🚚 How does delivery work?',
      '📊 How do I view my sales?',
      '⭐ How do I manage reviews?',
      '💵 Do you charge commission?',
      '📱 How do I set payment details?',
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
