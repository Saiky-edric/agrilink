import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/address_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/address_service.dart';
import '../../auth/screens/address_setup_screen.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  final AuthService _authService = AuthService();
  final AddressService _addressService = AddressService();
  List<AddressModel> _addresses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserAddresses();
  }

  Future<void> _loadUserAddresses() async {
    setState(() => _isLoading = true);
    
    try {
      final user = await _authService.getCurrentUserProfile();
      if (user != null) {
        try {
          final addresses = await _addressService.getUserAddresses(user.id);
          
          if (addresses.isNotEmpty) {
            setState(() {
              _addresses = addresses;
            });
          } else {
            // No addresses in database, migrate from profile if available
            if (user.municipality != null && 
                user.municipality!.isNotEmpty && 
                user.barangay != null && 
                user.barangay!.isNotEmpty) {
              
              await _addressService.migrateProfileAddress(
                userId: user.id,
                municipality: user.municipality!,
                barangay: user.barangay!,
                street: user.street,
              );
              
              // Reload addresses after migration
              final migratedAddresses = await _addressService.getUserAddresses(user.id);
              setState(() {
                _addresses = migratedAddresses;
              });
            }
          }
        } catch (e) {
          print('Error loading addresses: $e');
          // Fallback to creating profile address manually
          _createProfileAddress(user);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading addresses: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _createProfileAddress(dynamic user) {
    if (user.municipality != null && 
        user.municipality!.isNotEmpty && 
        user.barangay != null && 
        user.barangay!.isNotEmpty) {
      
      final profileAddress = AddressModel(
        id: 'profile_address',
        name: 'Home',
        streetAddress: user.street ?? 'Street not specified',
        barangay: user.barangay!,
        municipality: user.municipality!,
        province: 'Philippines',
        postalCode: '',
        isDefault: true,
        createdAt: user.createdAt,
      );

      setState(() {
        _addresses = [profileAddress];
      });
    }
  }

  Future<void> _addNewAddress() async {
    final result = await Navigator.push<AddressModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressSetupScreen(
          isEditMode: false,
          showSkipButton: false,
          title: 'Add New Address',
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _addresses.add(result);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address added successfully!')),
      );
    }
  }

  Future<void> _editAddress(AddressModel address) async {
    final result = await Navigator.push<AddressModel>(
      context,
      MaterialPageRoute(
        builder: (context) => AddressSetupScreen(
          isEditMode: true,
          existingAddress: address,
          showSkipButton: false,
          title: 'Edit Address',
        ),
      ),
    );

    if (result != null) {
      setState(() {
        final index = _addresses.indexWhere((a) => a.id == address.id);
        if (index != -1) {
          _addresses[index] = result;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address updated successfully!')),
      );
    }
  }

  Future<void> _setDefaultAddress(String addressId) async {
    try {
      final user = await _authService.getCurrentUserProfile();
      if (user != null) {
        await _addressService.setDefaultAddress(user.id, addressId);
        
        // Update local state
        setState(() {
          for (var address in _addresses) {
            address.isDefault = address.id == addressId;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default address updated!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update default address: $e')),
      );
    }
  }

  void _deleteAddress(AddressModel address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete "${address.name}" address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final user = await _authService.getCurrentUserProfile();
                if (user != null) {
                  await _addressService.deleteAddress(address.id, user.id);
                  
                  setState(() {
                    _addresses.removeWhere((a) => a.id == address.id);
                  });
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${address.name} address deleted')),
                  );
                  
                  // Reload addresses to reflect any changes (like new default)
                  _loadUserAddresses();
                }
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete address: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.textOnPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Delivery Addresses'),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.lightGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppTheme.textPrimary,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? _buildEmptyState()
              : _buildAddressList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewAddress,
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(
          Icons.add,
          color: AppTheme.textOnPrimary,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 64,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'No delivery addresses',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Add delivery addresses to make ordering fresh products easier!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: _addNewAddress,
              icon: const Icon(Icons.add),
              label: const Text('Add Address'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList() {
    return Column(
      children: [
        // Header with count
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: AppTheme.primaryGreen),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${_addresses.length} address${_addresses.length > 1 ? 'es' : ''}',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addNewAddress,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New'),
              ),
            ],
          ),
        ),
        
        // Addresses list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: 80, // Space for FAB
            ),
            itemCount: _addresses.length,
            itemBuilder: (context, index) {
              final address = _addresses[index];
              return _buildAddressCard(address);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(AddressModel address) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: address.isDefault ? AppTheme.primaryGreen : AppTheme.lightGrey,
          width: address.isDefault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with name and default badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    address.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Default',
                      style: TextStyle(
                        color: AppTheme.textOnPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editAddress(address);
                        break;
                      case 'default':
                        _setDefaultAddress(address.id);
                        break;
                      case 'delete':
                        _deleteAddress(address);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    if (!address.isDefault)
                      const PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(Icons.star_outline, size: 20),
                            SizedBox(width: 8),
                            Text('Set as Default'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: AppTheme.errorRed),
                          const SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // Full address
            Text(
              '${address.streetAddress}\n${address.barangay}, ${address.municipality}\n${address.province} ${address.postalCode}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// AddressModel is now imported from core/models/address_model.dart