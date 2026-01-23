import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/models/admin_analytics_model.dart';
import '../../../shared/widgets/loading_widgets.dart';

class AdminActivitiesScreen extends StatefulWidget {
  const AdminActivitiesScreen({super.key});

  @override
  State<AdminActivitiesScreen> createState() => _AdminActivitiesScreenState();
}

class _AdminActivitiesScreenState extends State<AdminActivitiesScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  List<AdminActivity> _activities = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';
  String? _selectedAdmin;
  DateTimeRange? _dateRange;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final activities = await _adminService.getRecentActivities(limit: 100);

      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<AdminActivity> get _filteredActivities {
    var filtered = _activities;

    // Filter by type
    if (_selectedFilter != 'all') {
      filtered = filtered.where((activity) => activity.type == _selectedFilter).toList();
    }

    // Filter by admin
    if (_selectedAdmin != null && _selectedAdmin != 'all') {
      filtered = filtered.where((activity) => activity.userName == _selectedAdmin).toList();
    }

    // Filter by date range
    if (_dateRange != null) {
      filtered = filtered.where((activity) {
        return activity.timestamp.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
               activity.timestamp.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((activity) {
        final query = _searchQuery.toLowerCase();
        return activity.title.toLowerCase().contains(query) ||
               activity.description.toLowerCase().contains(query) ||
               (activity.userName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  List<String> get _uniqueAdmins {
    final admins = _activities
        .where((a) => a.userName != null)
        .map((a) => a.userName!)
        .toSet()
        .toList();
    admins.sort();
    return admins;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Admin Activities',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: AppTheme.primaryGreen),
            onPressed: _exportActivities,
            tooltip: 'Export Activities',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textPrimary),
            onPressed: _loadActivities,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ModernLoadingWidget();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Error loading activities',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: _loadActivities,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: AppTheme.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No activities yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Admin activities will appear here',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search activities...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.cardWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.lightGrey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.lightGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
              ),
            ),
          ),
        ),

        // Advanced Filters Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              // Date Range Filter
              Expanded(
                child: InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: _dateRange != null
                          ? AppTheme.primaryGreen.withOpacity(0.1)
                          : AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _dateRange != null
                            ? AppTheme.primaryGreen
                            : AppTheme.lightGrey,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.date_range,
                          size: 18,
                          color: _dateRange != null
                              ? AppTheme.primaryGreen
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dateRange != null
                                ? '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}'
                                : 'Date Range',
                            style: TextStyle(
                              fontSize: 12,
                              color: _dateRange != null
                                  ? AppTheme.primaryGreen
                                  : AppTheme.textSecondary,
                              fontWeight: _dateRange != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_dateRange != null)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _dateRange = null;
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Admin Filter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: _selectedAdmin != null && _selectedAdmin != 'all'
                        ? AppTheme.primaryGreen.withOpacity(0.1)
                        : AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedAdmin != null && _selectedAdmin != 'all'
                          ? AppTheme.primaryGreen
                          : AppTheme.lightGrey,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAdmin ?? 'all',
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: _selectedAdmin != null && _selectedAdmin != 'all'
                            ? AppTheme.primaryGreen
                            : AppTheme.textSecondary,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: _selectedAdmin != null && _selectedAdmin != 'all'
                            ? AppTheme.primaryGreen
                            : AppTheme.textSecondary,
                        fontWeight: _selectedAdmin != null && _selectedAdmin != 'all'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('All Admins'),
                        ),
                        ..._uniqueAdmins.map((admin) => DropdownMenuItem(
                              value: admin,
                              child: Text(admin, overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedAdmin = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Filter Chips
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Verifications', 'verification'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Users', 'user'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Orders', 'order'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Reports', 'report_management'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('System', 'system'),
              ],
            ),
          ),
        ),

        // Activities List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadActivities,
            child: _filteredActivities.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_alt_off,
                          size: 64,
                          color: AppTheme.textSecondary.withOpacity(0.3),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'No activities found',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilter = 'all';
                            });
                          },
                          child: const Text('Clear Filter'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _filteredActivities.length,
                    itemBuilder: (context, index) {
                      final activity = _filteredActivities[index];
                      return _buildActivityCard(activity);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: AppTheme.cardWhite,
      selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryGreen : AppTheme.lightGrey,
      ),
    );
  }

  Widget _buildActivityCard(AdminActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getActivityColor(activity.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getActivityIcon(activity.type),
            color: _getActivityColor(activity.type),
            size: 24,
          ),
        ),
        title: Text(
          activity.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Text(
              activity.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: AppTheme.textSecondary.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTimestamp(activity.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
                ),
                if (activity.userName != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.person_outline,
                    size: 12,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      activity.userName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary.withOpacity(0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: _getActivityColor(activity.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _formatActivityType(activity.type),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _getActivityColor(activity.type),
            ),
          ),
        ),
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'verification':
        return AppTheme.primaryGreen;
      case 'user':
      case 'user_management':
        return AppTheme.secondaryGreen;
      case 'order':
        return AppTheme.warningOrange;
      case 'report_management':
        return AppTheme.errorRed;
      case 'platform_management':
        return AppTheme.infoBlue;
      case 'system':
        return AppTheme.textSecondary;
      default:
        return AppTheme.primaryGreen;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'verification':
        return Icons.verified_user;
      case 'user':
      case 'user_management':
        return Icons.person;
      case 'order':
        return Icons.shopping_cart;
      case 'report_management':
        return Icons.flag;
      case 'platform_management':
        return Icons.settings;
      case 'system':
        return Icons.computer;
      default:
        return Icons.notifications;
    }
  }

  String _formatActivityType(String type) {
    return type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        // Show date for older activities
        return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              surface: AppTheme.cardWhite,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  Future<void> _exportActivities() async {
    try {
      if (_filteredActivities.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No activities to export'),
              backgroundColor: AppTheme.warningOrange,
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Exporting activities...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final csv = _convertActivitiesToCSV(_filteredActivities);
      await _downloadCSV('admin_activities', csv);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  String _convertActivitiesToCSV(List<AdminActivity> activities) {
    final StringBuffer csv = StringBuffer();
    csv.writeln('ID,Title,Description,Type,Admin,Timestamp');

    for (final activity in activities) {
      csv.writeln(
        '"${activity.id}","${activity.title}","${activity.description}","${activity.type}","${activity.userName ?? 'System'}","${activity.timestamp.toIso8601String()}"',
      );
    }

    return csv.toString();
  }

  Future<void> _downloadCSV(String filename, String content) async {
    try {
      if (kIsWeb) {
        // Web implementation - would use html download
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Web export coming soon'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Android/iOS implementation
      Directory? directory;

      if (Platform.isAndroid) {
        // Try to get Downloads directory
        try {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } catch (e) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Create file with timestamp
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final filePath = '${directory.path}/agrilink_${filename}_$timestamp.csv';
      final file = File(filePath);

      // Write CSV content
      await file.writeAsString(content);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Exported ${_filteredActivities.length} activities'),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving file: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}
