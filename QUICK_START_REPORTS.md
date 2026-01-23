# Quick Start Guide - Content Moderation & Reports

## ⚡ Quick Setup (5 Minutes)

### Step 1: Run Database Migration
1. Go to your Supabase project dashboard
2. Click on "SQL Editor" in the left menu
3. Click "New Query"
4. Copy and paste the contents of `supabase_setup/24_update_reports_schema.sql`
5. Click "Run" to execute the migration
6. ✅ Verify success message appears

### Step 2: Test User Report Flow
1. **Build and run the app**:
   ```bash
   flutter run
   ```

2. **Test Product Report**:
   - Navigate to any product details screen
   - Look for the **3-dot menu (⋮)** button in the top right
   - Tap it and select **"Report Product"**
   - Fill in the report form:
     - Select a reason (e.g., "Misleading information")
     - Add description
     - Submit
   - ✅ You should see a success message

3. **View Your Reports**:
   - Add "My Reports" to your profile menu (see instructions below)
   - Or navigate directly to `MyReportsScreen`
   - ✅ You should see your submitted report

### Step 3: Test Admin Report Management
1. **Login as admin user**
2. Navigate to Admin Dashboard
3. Click on **"Reports Management"**
4. ✅ You should see all pending reports
5. Click on a report to view details
6. Test actions:
   - Click "Dismiss" and add notes
   - OR click "Resolve" and add notes
7. ✅ Verify status updates

## 📋 Integration Points

### Add "My Reports" to Profile Menu

In your `buyer_profile_screen.dart` or `settings_screen.dart`:

```dart
import '../buyer/screens/my_reports_screen.dart';

// Add this tile to your menu
ListTile(
  leading: const Icon(Icons.flag_outlined, color: AppTheme.primaryGreen),
  title: const Text('My Reports'),
  subtitle: const Text('View your submitted reports'),
  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyReportsScreen(),
      ),
    );
  },
),
```

### Add Report to Order Details

In your `order_details_screen.dart`:

```dart
import '../../shared/widgets/report_dialog.dart';

// Add to app bar actions or as a button
IconButton(
  icon: const Icon(Icons.flag_outlined),
  tooltip: 'Report Order',
  onPressed: () {
    showReportDialog(
      context,
      targetId: order.id,
      targetType: 'order',
      targetName: 'Order #${order.id.substring(0, 8)}',
    );
  },
),
```

### Add Report to Farmer Profile

In your `public_farmer_profile_screen.dart`:

```dart
import '../../shared/widgets/report_dialog.dart';

// Add to app bar actions
PopupMenuButton<String>(
  icon: const Icon(Icons.more_vert),
  itemBuilder: (context) => [
    const PopupMenuItem(
      value: 'report',
      child: Row(
        children: [
          Icon(Icons.flag, color: AppTheme.errorRed, size: 20),
          SizedBox(width: 8),
          Text('Report User'),
        ],
      ),
    ),
  ],
  onSelected: (value) {
    if (value == 'report') {
      showReportDialog(
        context,
        targetId: farmerId,
        targetType: 'user',
        targetName: farmerName,
      );
    }
  },
),
```

## 🧪 Testing Checklist

### User Side
- [ ] Report a product
- [ ] Report a user/farmer
- [ ] Report an order
- [ ] View "My Reports" screen
- [ ] Cancel a pending report
- [ ] Verify resolved reports show admin notes

### Admin Side
- [ ] View all reports
- [ ] Filter by status (pending/resolved/dismissed)
- [ ] Dismiss a report with notes
- [ ] Resolve a report with notes
- [ ] Verify activity logging

## 🎨 UI Features

### Report Dialog
- ✅ Beautiful modal design
- ✅ Category-specific reasons
- ✅ 500 character description limit
- ✅ Validation and error handling
- ✅ Loading states
- ✅ Success feedback

### My Reports Screen
- ✅ Card-based UI
- ✅ Status color coding
- ✅ Resolution notes display
- ✅ Cancel pending reports
- ✅ Empty state handling
- ✅ Pull to refresh

### Admin Reports Management
- ✅ Filter chips for status
- ✅ Color-coded cards
- ✅ Quick actions (dismiss/resolve)
- ✅ Notes input dialogs
- ✅ Empty state handling
- ✅ Refresh button

## 🔧 Troubleshooting

### "Reports not showing"
- Verify database migration ran successfully
- Check RLS policies are enabled
- Ensure user is authenticated

### "Cannot submit report"
- Check internet connection
- Verify Supabase credentials in `.env`
- Check console for error messages

### "Admin cannot see reports"
- Verify user has role='admin' in users table
- Check admin RLS policies exist

## 📊 Database Schema

The reports table includes:
- `id` - Report UUID
- `reporter_id` - User who reported
- `reporter_name` - Reporter's name
- `reporter_email` - Reporter's email
- `target_id` - ID of reported item
- `target_type` - 'product', 'user', or 'order'
- `target_name` - Name of reported item
- `reason` - Selected reason
- `description` - Detailed description
- `status` - 'pending', 'resolved', or 'dismissed'
- `resolved_at` - When resolved
- `resolved_by` - Admin who resolved
- `resolution` - Admin notes
- `attachments` - Array of image URLs (future use)
- `created_at` - Timestamp

## 🚀 What's Included

### New Files Created
1. ✅ `lib/core/services/report_service.dart` - Backend service
2. ✅ `lib/shared/widgets/report_dialog.dart` - Report UI dialog
3. ✅ `lib/features/buyer/screens/my_reports_screen.dart` - User reports view
4. ✅ `supabase_setup/24_update_reports_schema.sql` - Database migration

### Modified Files
1. ✅ `lib/features/buyer/screens/modern_product_details_screen.dart` - Added report button

### Existing Files (Already Complete)
1. ✅ `lib/features/admin/screens/admin_reports_management_screen.dart`
2. ✅ `lib/features/admin/screens/report_details_screen.dart`
3. ✅ `lib/core/services/admin_service.dart` - Has report methods
4. ✅ `lib/core/models/admin_analytics_model.dart` - Has AdminReportData

## 📝 Next Steps

1. **Run the database migration** (Step 1 above)
2. **Add "My Reports" to profile menu** (code provided above)
3. **Add report buttons to other screens** (order details, farmer profile)
4. **Test the full flow** (submit report → admin review → see resolution)
5. **Optional**: Add email notifications for report updates

## 💡 Tips

- Reports are automatically linked to the current user
- Target information is fetched automatically
- Status transitions: pending → resolved/dismissed
- Users can only cancel their own pending reports
- Admins see all reports regardless of status
- False reports warning discourages abuse

## ✨ Features Ready to Use

✅ Submit reports (products, users, orders)
✅ View my submitted reports
✅ Cancel pending reports
✅ Admin reports management
✅ Filter by status
✅ Resolve/dismiss with notes
✅ Activity logging
✅ Beautiful UI/UX
✅ Full RLS security
✅ Mobile-responsive design

## 🎯 Success Metrics

After implementation, you can track:
- Total reports submitted
- Average resolution time
- Most reported items/users
- False report rate
- Admin response rate

---

**Need Help?** Check `CONTENT_MODERATION_IMPLEMENTATION.md` for detailed documentation.
