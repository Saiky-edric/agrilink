import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/user_model.dart';

class AdminDataTable extends StatefulWidget {
  final List<UserModel> users;
  final Function(UserModel) onUserTap;
  final Function(UserModel, String) onUserAction;
  final bool isLoading;
  final String searchQuery;

  const AdminDataTable({
    super.key,
    required this.users,
    required this.onUserTap,
    required this.onUserAction,
    this.isLoading = false,
    this.searchQuery = '',
  });

  @override
  State<AdminDataTable> createState() => _AdminDataTableState();
}

class _AdminDataTableState extends State<AdminDataTable> {
  int? _sortColumnIndex;
  bool _sortAscending = true;
  List<UserModel> _sortedUsers = [];

  @override
  void initState() {
    super.initState();
    _updateSortedUsers();
  }

  @override
  void didUpdateWidget(AdminDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.users != widget.users || oldWidget.searchQuery != widget.searchQuery) {
      _updateSortedUsers();
    }
  }

  void _updateSortedUsers() {
    _sortedUsers = List.from(widget.users);
    
    // Apply search filter
    if (widget.searchQuery.isNotEmpty) {
      _sortedUsers = _sortedUsers.where((user) {
        final query = widget.searchQuery.toLowerCase();
        return user.name.toLowerCase().contains(query) ||
               user.email.toLowerCase().contains(query) ||
               user.role.toLowerCase().contains(query);
      }).toList();
    }
    
    // Apply sorting
    if (_sortColumnIndex != null) {
      _sortUsers(_sortColumnIndex!, _sortAscending);
    }
  }

  void _sortUsers(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      
      switch (columnIndex) {
        case 0: // Name
          _sortedUsers.sort((a, b) => ascending 
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name));
          break;
        case 1: // Email
          _sortedUsers.sort((a, b) => ascending 
              ? a.email.compareTo(b.email)
              : b.email.compareTo(a.email));
          break;
        case 2: // Role
          _sortedUsers.sort((a, b) => ascending 
              ? a.role.compareTo(b.role)
              : b.role.compareTo(a.role));
          break;
        case 3: // Status
          _sortedUsers.sort((a, b) => ascending 
              ? a.isActive.toString().compareTo(b.isActive.toString())
              : b.isActive.toString().compareTo(a.isActive.toString()));
          break;
        case 4: // Created Date
          _sortedUsers.sort((a, b) => ascending 
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryGreen,
        ),
      );
    }

    if (_sortedUsers.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      itemCount: _sortedUsers.length,
      padding: const EdgeInsets.all(8),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildUserCard(_sortedUsers[index]);
      },
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => widget.onUserTap(user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar, Name, Role, Actions
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryGreen,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionsMenu(user),
                ],
              ),
              const SizedBox(height: 12),
              // Bottom Row: Role, Status, Date
              Row(
                children: [
                  _buildRoleChip(user.role.name),
                  const SizedBox(width: 8),
                  _buildStatusChip(user.isActive),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(user.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    Color color;
    switch (role.toLowerCase()) {
      case 'admin':
        color = AppTheme.errorRed;
        break;
      case 'farmer':
        color = AppTheme.primaryGreen;
        break;
      case 'buyer':
        color = AppTheme.secondaryGreen;
        break;
      default:
        color = AppTheme.textSecondary;
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 60,
        maxWidth: 80,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            role.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 70,
        maxWidth: 90,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive 
              ? AppTheme.successGreen.withValues(alpha: 0.1)
              : AppTheme.errorRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            isActive ? 'ACTIVE' : 'INACTIVE',
            style: TextStyle(
              color: isActive ? AppTheme.successGreen : AppTheme.errorRed,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildActionsMenu(UserModel user) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      onSelected: (action) => widget.onUserAction(user, action),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 16),
              SizedBox(width: 8),
              Text('View Details'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 16),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: user.isActive ? 'suspend' : 'activate',
          child: Row(
            children: [
              Icon(
                user.isActive ? Icons.block : Icons.check_circle,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(user.isActive ? 'Suspend' : 'Activate'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.searchQuery.isNotEmpty 
                ? 'No users found matching "${widget.searchQuery}"'
                : 'No users found',
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          if (widget.searchQuery.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Try adjusting your search criteria',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}