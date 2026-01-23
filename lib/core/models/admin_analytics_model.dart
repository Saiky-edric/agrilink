class AdminAnalytics {
  final double totalRevenue;
  final int totalOrders;
  final int totalUsers;
  final int totalProducts;
  final int activeOrders;
  final int newUsersToday;
  final int pendingVerifications;
  final int pendingSubscriptions;
  final int premiumUsers;
  final List<RevenueData> revenueChart;
  final List<UserGrowthData> userGrowthChart;
  final List<OrderStatusData> orderStatusChart;
  final List<CategorySalesData> categorySalesChart;

  const AdminAnalytics({
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalUsers,
    required this.totalProducts,
    required this.activeOrders,
    required this.newUsersToday,
    required this.pendingVerifications,
    required this.pendingSubscriptions,
    required this.premiumUsers,
    required this.revenueChart,
    required this.userGrowthChart,
    required this.orderStatusChart,
    required this.categorySalesChart,
  });

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) {
    return AdminAnalytics(
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      totalOrders: json['total_orders'] ?? 0,
      totalUsers: json['total_users'] ?? 0,
      totalProducts: json['total_products'] ?? 0,
      activeOrders: json['active_orders'] ?? 0,
      newUsersToday: json['new_users_today'] ?? 0,
      pendingVerifications: json['pending_verifications'] ?? 0,
      pendingSubscriptions: json['pending_subscriptions'] ?? 0,
      premiumUsers: json['premium_users'] ?? 0,
      revenueChart: (json['revenue_chart'] as List<dynamic>?)
          ?.map((item) => RevenueData.fromJson(item))
          .toList() ?? [],
      userGrowthChart: (json['user_growth_chart'] as List<dynamic>?)
          ?.map((item) => UserGrowthData.fromJson(item))
          .toList() ?? [],
      orderStatusChart: (json['order_status_chart'] as List<dynamic>?)
          ?.map((item) => OrderStatusData.fromJson(item))
          .toList() ?? [],
      categorySalesChart: (json['category_sales_chart'] as List<dynamic>?)
          ?.map((item) => CategorySalesData.fromJson(item))
          .toList() ?? [],
    );
  }
}

class RevenueData {
  final String date;
  final double amount;

  const RevenueData({required this.date, required this.amount});

  factory RevenueData.fromJson(Map<String, dynamic> json) {
    return RevenueData(
      date: json['date'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

class UserGrowthData {
  final String date;
  final int count;
  final String userType;

  const UserGrowthData({
    required this.date,
    required this.count,
    required this.userType,
  });

  factory UserGrowthData.fromJson(Map<String, dynamic> json) {
    return UserGrowthData(
      date: json['date'] ?? '',
      count: json['count'] ?? 0,
      userType: json['user_type'] ?? 'buyer',
    );
  }
}

class OrderStatusData {
  final String status;
  final int count;
  final double percentage;

  const OrderStatusData({
    required this.status,
    required this.count,
    required this.percentage,
  });

  factory OrderStatusData.fromJson(Map<String, dynamic> json) {
    return OrderStatusData(
      status: json['status'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class CategorySalesData {
  final String category;
  final double sales;
  final int productCount;

  const CategorySalesData({
    required this.category,
    required this.sales,
    required this.productCount,
  });

  factory CategorySalesData.fromJson(Map<String, dynamic> json) {
    return CategorySalesData(
      category: json['category'] ?? '',
      sales: (json['sales'] ?? 0).toDouble(),
      productCount: json['product_count'] ?? 0,
    );
  }
}

class AdminActivity {
  final String id;
  final String title;
  final String description;
  final String type;
  final DateTime timestamp;
  final String? userId;
  final String? userName;
  final Map<String, dynamic>? metadata;

  const AdminActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
    this.userId,
    this.userName,
    this.metadata,
  });

  factory AdminActivity.fromJson(Map<String, dynamic> json) {
    return AdminActivity(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'general',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      userId: json['user_id'],
      userName: json['user_name'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
      'user_name': userName,
      'metadata': metadata,
    };
  }
}

// Missing Admin Data Models
class AdminUserData {
  final String id;
  final String name;
  final String email;
  final String userType;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? phoneNumber;
  final String? address;
  final Map<String, dynamic>? metadata;

  const AdminUserData({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    this.lastLoginAt,
    this.phoneNumber,
    this.address,
    this.metadata,
  });

  factory AdminUserData.fromJson(Map<String, dynamic> json) {
    return AdminUserData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      userType: json['user_type'] ?? 'buyer',
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      lastLoginAt: json['last_login_at'] != null 
          ? DateTime.parse(json['last_login_at']) 
          : null,
      phoneNumber: json['phone_number'],
      address: json['address'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'user_type': userType,
      'is_active': isActive,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'phone_number': phoneNumber,
      'address': address,
      'metadata': metadata,
    };
  }
}

class UserStatistics {
  final int totalUsers;
  final int activeUsers;
  final int newUsersToday;
  final int newUsersThisWeek;
  final int newUsersThisMonth;
  final int buyerCount;
  final int farmerCount;
  final int adminCount;
  final int verifiedUsers;
  final int pendingVerifications;

  const UserStatistics({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsersToday,
    required this.newUsersThisWeek,
    required this.newUsersThisMonth,
    required this.buyerCount,
    required this.farmerCount,
    required this.adminCount,
    required this.verifiedUsers,
    required this.pendingVerifications,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      totalUsers: json['total_users'] ?? 0,
      activeUsers: json['active_users'] ?? 0,
      newUsersToday: json['new_users_today'] ?? 0,
      newUsersThisWeek: json['new_users_this_week'] ?? 0,
      newUsersThisMonth: json['new_users_this_month'] ?? 0,
      buyerCount: json['buyer_count'] ?? 0,
      farmerCount: json['farmer_count'] ?? 0,
      adminCount: json['admin_count'] ?? 0,
      verifiedUsers: json['verified_users'] ?? 0,
      pendingVerifications: json['pending_verifications'] ?? 0,
    );
  }
}

class AdminVerificationData {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String verificationType;
  final String status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNotes;
  final List<String> documents;
  final Map<String, dynamic>? farmDetails;
  final String? farmName;
  final String? farmAddress;

  const AdminVerificationData({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.verificationType,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNotes,
    required this.documents,
    this.farmDetails,
    this.farmName,
    this.farmAddress,
  });

  factory AdminVerificationData.fromJson(Map<String, dynamic> json) {
    // Count actual documents from URL fields
    final List<String> documents = [];
    
    if (json['farmer_id_image_url'] != null && json['farmer_id_image_url'].toString().isNotEmpty) {
      documents.add(json['farmer_id_image_url']);
    }
    if (json['barangay_cert_image_url'] != null && json['barangay_cert_image_url'].toString().isNotEmpty) {
      documents.add(json['barangay_cert_image_url']);
    }
    if (json['selfie_image_url'] != null && json['selfie_image_url'].toString().isNotEmpty) {
      documents.add(json['selfie_image_url']);
    }
    
    return AdminVerificationData(
      id: json['id'] ?? '',
      userId: json['farmer_id'] ?? json['user_id'] ?? '', // Use farmer_id as primary
      userName: json['user_name'] ?? '',
      userEmail: json['user_email'] ?? '',
      verificationType: json['verification_type'] ?? 'farmer',
      status: json['status'] ?? 'pending',
      submittedAt: DateTime.parse(json['submitted_at'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      reviewedAt: json['reviewed_at'] != null 
          ? DateTime.parse(json['reviewed_at']) 
          : null,
      reviewedBy: json['reviewed_by'],
      reviewNotes: json['review_notes'] ?? json['rejection_reason'], // Use rejection_reason as fallback
      documents: documents, // Use actual document URLs
      farmDetails: json['farm_details'],
      farmName: json['farm_name'],
      farmAddress: json['farm_address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'verification_type': verificationType,
      'status': status,
      'submitted_at': submittedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
      'review_notes': reviewNotes,
      'documents': documents,
      'farm_details': farmDetails,
      'farm_name': farmName,
      'farm_address': farmAddress,
    };
  }
}

class PlatformAnalytics {
  final AdminAnalytics overview;
  final UserStatistics userStats;
  final OrderAnalytics orderStats;
  final ProductAnalytics productStats;
  final RevenueAnalytics revenueStats;

  const PlatformAnalytics({
    required this.overview,
    required this.userStats,
    required this.orderStats,
    required this.productStats,
    required this.revenueStats,
  });

  factory PlatformAnalytics.fromJson(Map<String, dynamic> json) {
    return PlatformAnalytics(
      overview: AdminAnalytics.fromJson(json['overview'] ?? {}),
      userStats: UserStatistics.fromJson(json['user_stats'] ?? {}),
      orderStats: OrderAnalytics.fromJson(json['order_stats'] ?? {}),
      productStats: ProductAnalytics.fromJson(json['product_stats'] ?? {}),
      revenueStats: RevenueAnalytics.fromJson(json['revenue_stats'] ?? {}),
    );
  }
}

class OrderAnalytics {
  final int totalOrders;
  final int pendingOrders;
  final int processingOrders;
  final int shippedOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double averageOrderValue;
  final List<OrderTrendData> trends;

  const OrderAnalytics({
    required this.totalOrders,
    required this.pendingOrders,
    required this.processingOrders,
    required this.shippedOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.averageOrderValue,
    required this.trends,
  });

  factory OrderAnalytics.fromJson(Map<String, dynamic> json) {
    return OrderAnalytics(
      totalOrders: json['total_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      processingOrders: json['processing_orders'] ?? 0,
      shippedOrders: json['shipped_orders'] ?? 0,
      deliveredOrders: json['delivered_orders'] ?? 0,
      cancelledOrders: json['cancelled_orders'] ?? 0,
      averageOrderValue: (json['average_order_value'] ?? 0).toDouble(),
      trends: (json['trends'] as List<dynamic>?)
          ?.map((item) => OrderTrendData.fromJson(item))
          .toList() ?? [],
    );
  }
}

class OrderTrendData {
  final String date;
  final int count;
  final double value;

  const OrderTrendData({
    required this.date,
    required this.count,
    required this.value,
  });

  factory OrderTrendData.fromJson(Map<String, dynamic> json) {
    return OrderTrendData(
      date: json['date'] ?? '',
      count: json['count'] ?? 0,
      value: (json['value'] ?? 0).toDouble(),
    );
  }
}

class ProductAnalytics {
  final int totalProducts;
  final int activeProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final String topCategory;
  final List<ProductTrendData> trends;

  const ProductAnalytics({
    required this.totalProducts,
    required this.activeProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.topCategory,
    required this.trends,
  });

  factory ProductAnalytics.fromJson(Map<String, dynamic> json) {
    return ProductAnalytics(
      totalProducts: json['total_products'] ?? 0,
      activeProducts: json['active_products'] ?? 0,
      lowStockProducts: json['low_stock_products'] ?? 0,
      outOfStockProducts: json['out_of_stock_products'] ?? 0,
      topCategory: json['top_category'] ?? '',
      trends: (json['trends'] as List<dynamic>?)
          ?.map((item) => ProductTrendData.fromJson(item))
          .toList() ?? [],
    );
  }
}

class ProductTrendData {
  final String date;
  final int count;
  final String category;

  const ProductTrendData({
    required this.date,
    required this.count,
    required this.category,
  });

  factory ProductTrendData.fromJson(Map<String, dynamic> json) {
    return ProductTrendData(
      date: json['date'] ?? '',
      count: json['count'] ?? 0,
      category: json['category'] ?? '',
    );
  }
}

class RevenueAnalytics {
  final double totalRevenue;
  final double monthlyRevenue;
  final double dailyRevenue;
  final double growth;
  final List<RevenueData> trends;

  const RevenueAnalytics({
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.dailyRevenue,
    required this.growth,
    required this.trends,
  });

  factory RevenueAnalytics.fromJson(Map<String, dynamic> json) {
    return RevenueAnalytics(
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      monthlyRevenue: (json['monthly_revenue'] ?? 0).toDouble(),
      dailyRevenue: (json['daily_revenue'] ?? 0).toDouble(),
      growth: (json['growth'] ?? 0).toDouble(),
      trends: (json['trends'] as List<dynamic>?)
          ?.map((item) => RevenueData.fromJson(item))
          .toList() ?? [],
    );
  }
}

class AdminReportData {
  final String id;
  final String reportType;
  final String reporterName;
  final String reporterEmail;
  final String targetType;
  final String targetId;
  final String targetName;
  final String reason;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolution;
  final List<String> attachments;

  const AdminReportData({
    required this.id,
    required this.reportType,
    required this.reporterName,
    required this.reporterEmail,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.reason,
    required this.description,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolution,
    required this.attachments,
  });

  factory AdminReportData.fromJson(Map<String, dynamic> json) {
    return AdminReportData(
      id: json['id'] ?? '',
      reportType: json['report_type'] ?? 'user',
      reporterName: json['reporter_name'] ?? '',
      reporterEmail: json['reporter_email'] ?? '',
      targetType: json['target_type'] ?? 'user',
      targetId: json['target_id'] ?? '',
      targetName: json['target_name'] ?? '',
      reason: json['reason'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      resolvedAt: json['resolved_at'] != null 
          ? DateTime.parse(json['resolved_at']) 
          : null,
      resolvedBy: json['resolved_by'],
      resolution: json['resolution'],
      attachments: List<String>.from(json['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_type': reportType,
      'reporter_name': reporterName,
      'reporter_email': reporterEmail,
      'target_type': targetType,
      'target_id': targetId,
      'target_name': targetName,
      'reason': reason,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
      'resolution': resolution,
      'attachments': attachments,
    };
  }
}