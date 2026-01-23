# Agrlink - Next Steps Implementation Guide

## 🎯 **IMMEDIATE ACTION ITEMS**

### **Priority 1: Create Missing Models (30 minutes)**

Create `lib/core/models/admin_models.dart`:

```dart
// UserStatistics Model
class UserStatistics {
  final int totalUsers;
  final int totalBuyers;
  final int totalFarmers;
  final int totalAdmins;
  final int newUsersThisMonth;

  UserStatistics({
    required this.totalUsers,
    required this.totalBuyers,
    required this.totalFarmers,
    required this.totalAdmins,
    required this.newUsersThisMonth,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      totalUsers: json['totalUsers'] ?? 0,
      totalBuyers: json['totalBuyers'] ?? 0,
      totalFarmers: json['totalFarmers'] ?? 0,
      totalAdmins: json['totalAdmins'] ?? 0,
      newUsersThisMonth: json['newUsersThisMonth'] ?? 0,
    );
  }
}

// AdminVerificationData Model
class AdminVerificationData {
  final String id;
  final String farmerId;
  final String farmerName;
  final String status;
  final DateTime submittedAt;
  final Map<String, dynamic> documents;

  AdminVerificationData({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.status,
    required this.submittedAt,
    required this.documents,
  });

  factory AdminVerificationData.fromJson(Map<String, dynamic> json) {
    return AdminVerificationData(
      id: json['id'] ?? '',
      farmerId: json['farmer_id'] ?? '',
      farmerName: json['farmer_name'] ?? '',
      status: json['status'] ?? 'pending',
      submittedAt: DateTime.tryParse(json['submitted_at'] ?? '') ?? DateTime.now(),
      documents: json['documents'] ?? {},
    );
  }
}

// AdminReportData Model  
class AdminReportData {
  final String id;
  final String reporterId;
  final String reportedId;
  final String type;
  final String description;
  final String status;
  final DateTime createdAt;

  AdminReportData({
    required this.id,
    required this.reporterId,
    required this.reportedId,
    required this.type,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory AdminReportData.fromJson(Map<String, dynamic> json) {
    return AdminReportData(
      id: json['id'] ?? '',
      reporterId: json['reporter_id'] ?? '',
      reportedId: json['reported_id'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

// PlatformAnalytics Model
class PlatformAnalytics {
  final UserStatistics userStats;
  final int totalProducts;
  final int totalOrders;
  final double totalRevenue;
  final int pendingVerifications;
  final List<MonthlyAnalytics> monthlyData;

  PlatformAnalytics({
    required this.userStats,
    required this.totalProducts,
    required this.totalOrders,
    required this.totalRevenue,
    required this.pendingVerifications,
    required this.monthlyData,
  });
}

// Monthly Analytics for charts
class MonthlyAnalytics {
  final String month;
  final int newUsers;
  final double revenue;
  final int orders;

  MonthlyAnalytics({
    required this.month,
    required this.newUsers,
    required this.revenue,
    required this.orders,
  });
}

// Alias for backward compatibility
typedef AdminUserData = UserModel;
```

### **Priority 2: Complete AdminService (45 minutes)**

Add these methods to `lib/core/services/admin_service.dart`:

```dart
// Add after existing methods:

Future<UserStatistics> getUserStatistics() async {
  try {
    final totalUsers = await _client.from('profiles').select('id');
    final buyers = await _client.from('profiles').select('id').eq('role', 'buyer');
    final farmers = await _client.from('profiles').select('id').eq('role', 'farmer');
    final admins = await _client.from('profiles').select('id').eq('role', 'admin');
    
    final thisMonth = DateTime.now().subtract(Duration(days: 30));
    final newUsers = await _client.from('profiles')
        .select('id')
        .gte('created_at', thisMonth.toIso8601String());

    return UserStatistics(
      totalUsers: totalUsers.length,
      totalBuyers: buyers.length,
      totalFarmers: farmers.length,
      totalAdmins: admins.length,
      newUsersThisMonth: newUsers.length,
    );
  } catch (e) {
    debugPrint('Error getting user statistics: $e');
    rethrow;
  }
}

Future<void> toggleUserStatus(String userId, bool isActive) async {
  try {
    await _client
        .from('profiles')
        .update({'is_active': isActive})
        .eq('id', userId);
  } catch (e) {
    debugPrint('Error toggling user status: $e');
    rethrow;
  }
}

Future<void> deleteUser(String userId) async {
  try {
    await _client.from('profiles').delete().eq('id', userId);
  } catch (e) {
    debugPrint('Error deleting user: $e');
    rethrow;
  }
}

Future<List<AdminVerificationData>> getAllVerifications({
  String status = 'all',
  int limit = 50,
}) async {
  try {
    var query = _client.from('farmer_verifications').select('''
      id, farmer_id, farmer_name, status, submitted_at, documents
    ''');
    
    if (status != 'all') {
      query = query.eq('status', status);
    }
    
    final result = await query.order('submitted_at', ascending: false).limit(limit);
    return result.map((v) => AdminVerificationData.fromJson(v)).toList();
  } catch (e) {
    debugPrint('Error getting verifications: $e');
    return [];
  }
}

Future<void> approveVerification(String verificationId) async {
  try {
    await _client
        .from('farmer_verifications')
        .update({'status': 'approved', 'reviewed_at': DateTime.now().toIso8601String()})
        .eq('id', verificationId);
  } catch (e) {
    debugPrint('Error approving verification: $e');
    rethrow;
  }
}

Future<void> rejectVerification(String verificationId, String reason) async {
  try {
    await _client
        .from('farmer_verifications')
        .update({
          'status': 'rejected',
          'rejection_reason': reason,
          'reviewed_at': DateTime.now().toIso8601String()
        })
        .eq('id', verificationId);
  } catch (e) {
    debugPrint('Error rejecting verification: $e');
    rethrow;
  }
}

Future<PlatformAnalytics> getPlatformAnalytics() async {
  try {
    final userStats = await getUserStatistics();
    final products = await _client.from('products').select('id');
    final orders = await _client.from('orders').select('id, total_amount');
    final verifications = await _client.from('farmer_verifications')
        .select('id').eq('status', 'pending');

    double totalRevenue = 0;
    for (final order in orders) {
      totalRevenue += (order['total_amount'] ?? 0).toDouble();
    }

    return PlatformAnalytics(
      userStats: userStats,
      totalProducts: products.length,
      totalOrders: orders.length,
      totalRevenue: totalRevenue,
      pendingVerifications: verifications.length,
      monthlyData: [], // Implement as needed
    );
  } catch (e) {
    debugPrint('Error getting platform analytics: $e');
    rethrow;
  }
}

Future<List<AdminReportData>> getAllReports({
  String status = 'all',
  int limit = 50,
}) async {
  try {
    var query = _client.from('reports').select('''
      id, reporter_id, reported_id, type, description, status, created_at
    ''');
    
    if (status != 'all') {
      query = query.eq('status', status);
    }
    
    final result = await query.order('created_at', ascending: false).limit(limit);
    return result.map((r) => AdminReportData.fromJson(r)).toList();
  } catch (e) {
    debugPrint('Error getting reports: $e');
    return [];
  }
}

Future<void> resolveReport(String reportId, String resolution, {String? notes}) async {
  try {
    await _client
        .from('reports')
        .update({
          'status': 'resolved',
          'resolution': resolution,
          'resolution_notes': notes,
          'resolved_at': DateTime.now().toIso8601String()
        })
        .eq('id', reportId);
  } catch (e) {
    debugPrint('Error resolving report: $e');
    rethrow;
  }
}

Future<Map<String, dynamic>> getPlatformSettings() async {
  try {
    final result = await _client.from('platform_settings').select();
    Map<String, dynamic> settings = {};
    for (final setting in result) {
      settings[setting['key']] = setting['value'];
    }
    return settings;
  } catch (e) {
    debugPrint('Error getting platform settings: $e');
    return {};
  }
}

Future<void> updatePlatformSetting(String key, dynamic value) async {
  try {
    await _client.from('platform_settings').upsert({
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String()
    });
  } catch (e) {
    debugPrint('Error updating platform setting: $e');
    rethrow;
  }
}
```

### **Priority 3: Update Admin Screen Imports (15 minutes)**

Add to admin screen files:
```dart
import '../../../core/models/admin_models.dart';
```

Change type references:
```dart
// OLD:
List<AdminUserData> _users = [];

// NEW: 
List<UserModel> _users = [];  // or keep AdminUserData since it's aliased
```

### **Priority 4: Test Compilation (10 minutes)**
```bash
flutter clean
flutter pub get
flutter analyze
flutter build web --release
```

---

## 🚀 **QUICK WINS AFTER COMPLETION**

1. **Basic Admin Panel** - Should work immediately
2. **User Management** - Create, edit, delete users
3. **Verification System** - Approve/reject farmers  
4. **Reporting Dashboard** - Basic analytics
5. **Settings Management** - Platform configuration

---

## 📱 **TESTING CHECKLIST**

- [ ] App compiles without errors
- [ ] Login screen loads
- [ ] User registration works
- [ ] Admin dashboard accessible
- [ ] User list displays
- [ ] Verification list shows data
- [ ] Basic navigation functional

---

## 🎯 **SUCCESS METRICS**

- **Zero compilation errors**
- **All admin screens load**
- **Database operations work**
- **UI components render properly**
- **Navigation flows correctly**

**Estimated Total Time: 1.5-2 hours to full functionality**