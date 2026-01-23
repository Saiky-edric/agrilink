# 📡 Agrilink API Documentation

## 📋 Overview

This document provides comprehensive API documentation for all service classes and methods in the Agrilink application. All APIs are built on top of Supabase and follow REST principles.

## 🔐 Authentication Service

### AuthService

The `AuthService` handles all authentication-related operations including signup, login, social authentication, and user profile management.

#### Methods

##### `signUp()`
```dart
Future<AuthResponse> signUp({
  required String email,
  required String password, 
  required String fullName,
  required String phoneNumber,
  required UserRole role,
})
```

**Description**: Creates a new user account with email and password.

**Parameters**:
- `email` (String): User's email address
- `password` (String): User's password (min 6 characters)
- `fullName` (String): User's full name
- `phoneNumber` (String): User's phone number
- `role` (UserRole): User role (buyer, farmer, admin)

**Returns**: `AuthResponse` with user data or error

**Example**:
```dart
final response = await authService.signUp(
  email: 'user@example.com',
  password: 'password123',
  fullName: 'John Doe',
  phoneNumber: '+639123456789',
  role: UserRole.buyer,
);
```

##### `signIn()`
```dart
Future<AuthResponse> signIn({
  required String email,
  required String password,
})
```

**Description**: Authenticates user with email and password.

##### `signInWithGoogle()`
```dart
Future<UserModel?> signInWithGoogle()
```

**Description**: Authenticates user using Google OAuth.

##### `signInWithFacebook()`
```dart
Future<UserModel?> signInWithFacebook()
```

**Description**: Authenticates user using Facebook OAuth.

##### `getCurrentUserProfile()`
```dart
Future<UserModel?> getCurrentUserProfile()
```

**Description**: Retrieves current authenticated user's profile.

##### `updateUserProfile()`
```dart
Future<UserModel> updateUserProfile({
  required String userId,
  String? fullName,
  String? phoneNumber,
  String? municipality,
  String? barangay,
  String? street,
})
```

**Description**: Updates user profile information.

##### `resetPassword()`
```dart
Future<void> resetPassword(String email)
```

**Description**: Sends password reset email to user.

##### `signOut()`
```dart
Future<void> signOut()
```

**Description**: Signs out current user and clears session.

## 🛒 Product Service

### ProductService

Manages all product-related operations including CRUD operations, search, and filtering.

#### Methods

##### `getAllProducts()`
```dart
Future<List<Product>> getAllProducts()
```

**Description**: Retrieves all available products.

**Returns**: List of `Product` objects

##### `getProductById()`
```dart
Future<Product?> getProductById(String productId)
```

**Description**: Retrieves a specific product by ID.

##### `getProductsByCategory()`
```dart
Future<List<Product>> getProductsByCategory(String category)
```

**Description**: Retrieves products filtered by category.

##### `searchProducts()`
```dart
Future<List<Product>> searchProducts({
  String? query,
  String? category,
  double? minPrice,
  double? maxPrice,
  String? location,
})
```

**Description**: Advanced product search with multiple filters.

**Parameters**:
- `query` (String?): Search term for product name/description
- `category` (String?): Product category filter
- `minPrice` (double?): Minimum price filter
- `maxPrice` (double?): Maximum price filter
- `location` (String?): Location filter

##### `addProduct()`
```dart
Future<Product> addProduct({
  required String name,
  required String description,
  required double price,
  required String unit,
  required int stock,
  required String category,
  required String farmerId,
  String? imageUrl,
  String? location,
})
```

**Description**: Adds a new product to the catalog.

##### `updateProduct()`
```dart
Future<Product> updateProduct({
  required String productId,
  String? name,
  String? description,
  double? price,
  String? unit,
  int? stock,
  String? category,
  String? imageUrl,
  String? location,
})
```

**Description**: Updates an existing product.

##### `deleteProduct()`
```dart
Future<void> deleteProduct(String productId)
```

**Description**: Removes a product from the catalog.

##### `getFarmerProducts()`
```dart
Future<List<Product>> getFarmerProducts(String farmerId)
```

**Description**: Retrieves all products for a specific farmer.

## 🛍️ Cart Service

### CartService

Manages shopping cart operations and state.

#### Methods

##### `addToCart()`
```dart
Future<void> addToCart(String productId, int quantity)
```

**Description**: Adds a product to the shopping cart.

##### `removeFromCart()`
```dart
Future<void> removeFromCart(String productId)
```

**Description**: Removes a product from the shopping cart.

##### `updateQuantity()`
```dart
Future<void> updateQuantity(String productId, int quantity)
```

**Description**: Updates the quantity of a product in the cart.

##### `getCartItems()`
```dart
List<CartItem> getCartItems()
```

**Description**: Retrieves all items in the cart.

##### `getTotalAmount()`
```dart
double getTotalAmount()
```

**Description**: Calculates total amount of all items in cart.

##### `clearCart()`
```dart
Future<void> clearCart()
```

**Description**: Removes all items from the cart.

## 📦 Order Service

### OrderService

Handles order creation, tracking, and management.

#### Methods

##### `createOrder()`
```dart
Future<Order> createOrder({
  required List<OrderItem> items,
  required String deliveryAddress,
  required double totalAmount,
  required double deliveryFee,
  String? notes,
})
```

**Description**: Creates a new order from cart items.

##### `getOrderById()`
```dart
Future<Order?> getOrderById(String orderId)
```

**Description**: Retrieves a specific order by ID.

##### `getBuyerOrders()`
```dart
Future<List<Order>> getBuyerOrders(String buyerId)
```

**Description**: Retrieves all orders for a buyer.

##### `getFarmerOrders()`
```dart
Future<List<Order>> getFarmerOrders(String farmerId)
```

**Description**: Retrieves all orders for a farmer.

##### `updateOrderStatus()`
```dart
Future<Order> updateOrderStatus(String orderId, OrderStatus status)
```

**Description**: Updates the status of an order.

**Order Statuses**:
- `pending` - Order placed, awaiting farmer confirmation
- `confirmed` - Farmer confirmed the order
- `delivered` - Order has been delivered
- `cancelled` - Order was cancelled

##### `cancelOrder()`
```dart
Future<void> cancelOrder(String orderId, String reason)
```

**Description**: Cancels an order with a reason.

## 💬 Chat Service

### ChatService

Manages real-time messaging between users.

#### Methods

##### `getConversations()`
```dart
Future<List<Conversation>> getConversations(String userId)
```

**Description**: Retrieves all conversations for a user.

##### `getMessages()`
```dart
Future<List<Message>> getMessages(String conversationId)
```

**Description**: Retrieves all messages in a conversation.

##### `sendMessage()`
```dart
Future<Message> sendMessage({
  required String conversationId,
  required String content,
  required String senderId,
})
```

**Description**: Sends a new message in a conversation.

##### `createConversation()`
```dart
Future<Conversation> createConversation({
  required String buyerId,
  required String farmerId,
})
```

**Description**: Creates a new conversation between buyer and farmer.

##### `markAsRead()`
```dart
Future<void> markAsRead(String conversationId, String userId)
```

**Description**: Marks messages as read in a conversation.

## 🔔 Notification Service

### NotificationService

Handles push notifications and notification history.

#### Methods

##### `initialize()`
```dart
Future<void> initialize()
```

**Description**: Initializes the notification service and requests permissions.

##### `getToken()`
```dart
Future<String?> getToken()
```

**Description**: Gets the FCM token for push notifications.

##### `showLocalNotification()`
```dart
Future<void> showLocalNotification({
  required String title,
  required String body,
  NotificationType type = NotificationType.general,
  Map<String, dynamic>? data,
})
```

**Description**: Shows a local notification to the user.

**Notification Types**:
- `orderUpdate` - Order status changes
- `verificationStatus` - Farmer verification updates
- `newMessage` - New chat messages
- `productUpdate` - Product availability updates
- `general` - General notifications

##### `getNotificationHistory()`
```dart
Future<List<NotificationItem>> getNotificationHistory()
```

**Description**: Retrieves notification history for the user.

##### `markAsRead()`
```dart
Future<void> markAsRead(String notificationId)
```

**Description**: Marks a notification as read.

##### `clearNotificationHistory()`
```dart
Future<void> clearNotificationHistory()
```

**Description**: Clears all notification history.

## 🌐 Realtime Service

### RealtimeService

Manages real-time updates using Supabase realtime subscriptions.

#### Methods

##### `subscribeToOrders()`
```dart
RealtimeChannel subscribeToOrders(String userId, Function(Map<String, dynamic>) onUpdate)
```

**Description**: Subscribes to real-time order updates.

##### `subscribeToMessages()`
```dart
RealtimeChannel subscribeToMessages(String conversationId, Function(Map<String, dynamic>) onMessage)
```

**Description**: Subscribes to real-time chat messages.

##### `subscribeToVerificationUpdates()`
```dart
RealtimeChannel subscribeToVerificationUpdates(String farmerId, Function(Map<String, dynamic>) onUpdate)
```

**Description**: Subscribes to farmer verification status changes.

##### `subscribeToProductUpdates()`
```dart
RealtimeChannel subscribeToProductUpdates(String location, Function(Map<String, dynamic>) onUpdate)
```

**Description**: Subscribes to product updates in user's location.

##### `unsubscribeFromChannel()`
```dart
Future<void> unsubscribeFromChannel(String channelName)
```

**Description**: Unsubscribes from a specific realtime channel.

##### `unsubscribeAll()`
```dart
Future<void> unsubscribeAll()
```

**Description**: Unsubscribes from all active channels.

## 👨‍🌾 Farmer Verification Service

### FarmerVerificationService

Manages farmer verification process and document handling.

#### Methods

##### `submitVerification()`
```dart
Future<FarmerVerification> submitVerification({
  required String farmerId,
  required String farmerName,
  required String email,
  required String phoneNumber,
  required String farmLocation,
  required String farmSize,
  required List<String> primaryCrops,
  required int yearsExperience,
  required List<String> documentsUrls,
})
```

**Description**: Submits a farmer verification application.

##### `getVerificationStatus()`
```dart
Future<FarmerVerification?> getVerificationStatus(String farmerId)
```

**Description**: Gets the verification status for a farmer.

##### `getAllVerifications()`
```dart
Future<List<FarmerVerification>> getAllVerifications()
```

**Description**: Retrieves all verification applications (admin only).

##### `approveVerification()`
```dart
Future<void> approveVerification(String verificationId)
```

**Description**: Approves a farmer verification (admin only).

##### `rejectVerification()`
```dart
Future<void> rejectVerification(String verificationId, String reason)
```

**Description**: Rejects a farmer verification with reason (admin only).

## 🗂️ Storage Service

### StorageService

Handles file uploads and storage operations.

#### Methods

##### `uploadImage()`
```dart
Future<String> uploadImage({
  required String bucket,
  required String fileName,
  required Uint8List fileBytes,
})
```

**Description**: Uploads an image file and returns the public URL.

**Storage Buckets**:
- `products` - Product images
- `documents` - Verification documents
- `profiles` - Profile pictures

##### `deleteFile()`
```dart
Future<void> deleteFile({
  required String bucket,
  required String fileName,
})
```

**Description**: Deletes a file from storage.

##### `getPublicUrl()`
```dart
String getPublicUrl({
  required String bucket,
  required String fileName,
})
```

**Description**: Gets the public URL for a stored file.

## 🔧 Error Handling

All API methods use consistent error handling:

```dart
try {
  final result = await apiMethod();
  // Handle success
} catch (e) {
  // Handle error
  print('API Error: $e');
  // Show user-friendly error message
}
```

## 📊 Response Models

### User Model
```dart
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final UserRole role;
  final String? municipality;
  final String? barangay;
  final String? street;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

### Product Model
```dart
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String unit;
  final int stock;
  final String category;
  final String farmerId;
  final String farmerName;
  final String? imageUrl;
  final String location;
  final DateTime createdAt;
}
```

### Order Model
```dart
class OrderModel {
  final String id;
  final String buyerId;
  final String buyerName;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String deliveryAddress;
  final OrderStatus status;
  final String? notes;
  final DateTime createdAt;
}
```

## 🔒 Security

- All API calls require proper authentication
- Row-Level Security (RLS) enforced on database level
- Input validation on both client and server side
- File upload restrictions and virus scanning
- Rate limiting on sensitive endpoints

## 🚀 Performance

- Response caching for frequently accessed data
- Pagination for large data sets
- Image optimization and compression
- Database query optimization with proper indexing
- Real-time subscriptions for live updates

---

**Last Updated**: December 2024  
**Version**: 1.0.0  
**Base URL**: Your Supabase Project URL