import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/models/user_model.dart';
import '../../../shared/widgets/loading_widgets.dart';
import '../../../shared/widgets/admin_data_table.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminService _adminService = AdminService();
  String _selectedTab = 'all';
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      List<UserModel> users;
      if (_selectedTab == 'all') {
        users = await _adminService.getUsersList();
      } else {
        users = await _adminService.getUsersByRole(_selectedTab);
      }

      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });

      _filterUsers();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_users);
      } else {
        _filteredUsers = _users.where((user) {
          return user.name.toLowerCase().contains(query) ||
                 user.email.toLowerCase().contains(query) ||
                 user.role.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'User Management',
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
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                _filterUsers();
              },
            ),
          ),
          
          // Filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                _buildFilterChip('all', 'All Users'),
                _buildFilterChip('buyers', 'Buyers'),
                _buildFilterChip('farmers', 'Farmers'),
                _buildFilterChip('admins', 'Admins'),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // User list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: AdminDataTable(
                users: _filteredUsers,
                isLoading: _isLoading,
                searchQuery: _searchController.text,
                onUserTap: _handleUserTap,
                onUserAction: _handleUserAction,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedTab == value;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedTab = value);
          _loadUsers();
        },
        selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
        checkmarkColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _handleUserTap(UserModel user) {
    // Navigate to user details or show user info
    showDialog(
      context: context,
      builder: (context) => _buildUserDetailsDialog(user),
    );
  }

  Future<void> _handleUserAction(UserModel user, String action) async {
    switch (action) {
      case 'view':
        _handleUserTap(user);
        break;
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'suspend':
      case 'activate':
        await _toggleUserStatus(user);
        break;
      case 'delete':
        _showDeleteUserDialog(user);
        break;
    }
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    try {
      await _adminService.toggleUserStatus(user.id, !user.isActive);
      
      // Log the activity
      await _adminService.logActivity(
        title: user.isActive ? 'User Suspended' : 'User Activated',
        description: '${user.name} (${user.email}) was ${user.isActive ? 'suspended' : 'activated'}',
        type: 'user',
        userId: user.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User ${user.isActive ? 'suspended' : 'activated'} successfully'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      
      _loadUsers(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user status: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _showEditUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => _buildEditUserDialog(user),
    );
  }

  void _showDeleteUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteUser(user);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(UserModel user) async {
    try {
      await _adminService.deleteUser(user.id);
      
      // Log the activity
      await _adminService.logActivity(
        title: 'User Deleted',
        description: '${user.name} (${user.email}) was deleted',
        type: 'user',
        userId: user.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User deleted successfully'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      
      _loadUsers(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting user: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Widget _buildUserDetailsDialog(UserModel user) {
    return AlertDialog(
      title: Text(user.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Email', user.email),
          _buildDetailRow('Role', user.role.toUpperCase()),
          _buildDetailRow('Status', user.isActive ? 'Active' : 'Inactive'),
          _buildDetailRow('Joined', _formatDate(user.createdAt)),
          _buildDetailRow('Phone', user.phoneNumber!),
          _buildDetailRow('Address', user.address!),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildEditUserDialog(UserModel user) {
    String selectedRole = user.role.name;
    
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text('Edit ${user.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: ['buyer', 'farmer', 'admin'].map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedRole = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _adminService.updateUserRole(user.id, selectedRole);
                  
                  // Log the activity
                  await _adminService.logActivity(
                    title: 'User Role Updated',
                    description: '${user.name}\'s role changed from ${user.role} to $selectedRole',
                    type: 'user',
                    userId: user.id,
                  );

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User role updated successfully'),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                  _loadUsers();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating user role: $e'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}