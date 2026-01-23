import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/address_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/address_model.dart';
import '../../../core/constants/location_data.dart';
import '../../../core/utils/keyboard_utils.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class AddressSetupScreen extends StatefulWidget {
  final bool isEditMode;
  final AddressModel? existingAddress;
  final bool showSkipButton;
  final String? title;

  const AddressSetupScreen({
    super.key,
    this.isEditMode = false,
    this.existingAddress,
    this.showSkipButton = true,
    this.title,
  });

  @override
  State<AddressSetupScreen> createState() => _AddressSetupScreenState();
}

class _AddressSetupScreenState extends State<AddressSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final AuthService _authService = AuthService();
  final AddressService _addressService = AddressService();

  bool _isLoading = false;
  String? _selectedMunicipality;
  String? _selectedBarangay;
  List<String> _availableBarangays = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingAddress != null) {
      _initializeWithExistingAddress();
    } else {
      // Set default name for new addresses
      _nameController.text = 'Home';
    }
  }

  void _initializeWithExistingAddress() {
    final address = widget.existingAddress!;
    _nameController.text = address.name;
    _selectedMunicipality = address.municipality;
    _selectedBarangay = address.barangay;
    _streetController.text = address.streetAddress;

    // Update available barangays for the selected municipality
    _updateAvailableBarangays(_selectedMunicipality!);
  }

  void _updateAvailableBarangays(String municipality) {
    setState(() {
      _availableBarangays = LocationData.getBarangaysForMunicipality(
        municipality,
      );
      // Reset barangay selection if current selection is not valid for new municipality
      if (_selectedBarangay != null &&
          !_availableBarangays.contains(_selectedBarangay)) {
        _selectedBarangay = null;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _handleAddressSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      AddressModel savedAddress;

      if (widget.isEditMode && widget.existingAddress != null) {
        // Update existing address
        savedAddress = await _addressService.updateAddress(
          addressId: widget.existingAddress!.id,
          userId: currentUser.id,
          name: _nameController.text.trim(),
          streetAddress: _streetController.text.trim(),
          barangay: _selectedBarangay!,
          municipality: _selectedMunicipality!,
        );
      } else {
        // Create new address
        savedAddress = await _addressService.createAddress(
          userId: currentUser.id,
          name: _nameController.text.trim(),
          streetAddress: _streetController.text.trim(),
          barangay: _selectedBarangay!,
          municipality: _selectedMunicipality!,
          isDefault: !(await _addressService.hasAddresses(currentUser.id)),
        );

        // If this is the first address during onboarding, also update profile for backward compatibility
        if (!widget.isEditMode && widget.showSkipButton) {
          await _authService.updateUserProfile(
            userId: currentUser.id,
            municipality: _selectedMunicipality!,
            barangay: _selectedBarangay!,
            street: _streetController.text.trim(),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditMode
                  ? 'Address updated successfully!'
                  : 'Address saved successfully!',
            ),
            backgroundColor: AppTheme.successGreen,
          ),
        );

        if (widget.isEditMode) {
          // Return the updated address for address management screen
          Navigator.of(context).pop(savedAddress);
        } else if (!widget.showSkipButton) {
          // Return the new address for address management screen
          Navigator.of(context).pop(savedAddress);
        } else {
          // Navigate to home after onboarding
          final user = await _authService.getCurrentUserProfile();

          if (user != null) {
            switch (user.role) {
              case UserRole.buyer:
                context.go(RouteNames.buyerHome);
                break;
              case UserRole.farmer:
                context.go(RouteNames.farmerDashboard);
                break;
              case UserRole.admin:
                context.go(RouteNames.adminDashboard);
                break;
            }
          } else {
            // Fallback to buyer home if user profile fetch fails
            print(
              'WARNING: Could not fetch user profile, defaulting to buyer home',
            );
            if (mounted) {
              context.go(RouteNames.buyerHome);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save address: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: widget.isEditMode || !widget.showSkipButton,
        leading: widget.isEditMode || !widget.showSkipButton
            ? IconButton(
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
                onPressed: () async {
                  // Use go_router to go back
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    // Navigate based on role when backing out of setup
                    final user = await _authService.getCurrentUserProfile();
                    if (!context.mounted) return;
                    if (user == null) {
                      context.go(RouteNames.login);
                      return;
                    }
                    switch (user.role) {
                      case UserRole.buyer:
                        context.go(RouteNames.buyerHome);
                        break;
                      case UserRole.farmer:
                        context.go(RouteNames.farmerDashboard);
                        break;
                      case UserRole.admin:
                        context.go(RouteNames.adminDashboard);
                        break;
                    }
                  }
                },
              )
            : null,
        title: Text(
          widget.title ?? 'Complete Your Profile',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          if (!widget.isEditMode && widget.showSkipButton)
            TextButton(
              onPressed: () async {
                // Skip address setup and go to correct home by role
                final user = await _authService.getCurrentUserProfile();
                if (!context.mounted) return;
                if (user == null) {
                  context.go(RouteNames.login);
                  return;
                }
                switch (user.role) {
                  case UserRole.buyer:
                    context.go(RouteNames.buyerHome);
                    break;
                  case UserRole.farmer:
                    context.go(RouteNames.farmerDashboard);
                    break;
                  case UserRole.admin:
                    context.go(RouteNames.adminDashboard);
                    break;
                }
              },
              child: Text(
                'Skip',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => KeyboardUtils.dismissKeyboard(context),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),

                // Info text
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primaryGreen),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          'Please provide your address to help us connect you with local farmers and enable accurate delivery.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Address name field
                CustomTextField(
                  label: 'Address Name',
                  hintText: 'e.g., Home, Work, etc.',
                  controller: _nameController,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.label_outline),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Municipality dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Municipality *',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedMunicipality,
                      decoration: InputDecoration(
                        hintText: 'Select your municipality',
                        prefixIcon: const Icon(Icons.location_city),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.small,
                          ),
                        ),
                      ),
                      items: LocationData.municipalities.map((municipality) {
                        return DropdownMenuItem(
                          value: municipality,
                          child: Text(municipality),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMunicipality = value;
                          _updateAvailableBarangays(value!);
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Municipality is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Barangay dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Barangay *',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBarangay,
                      decoration: InputDecoration(
                        hintText: _selectedMunicipality == null
                            ? 'Select municipality first'
                            : 'Select your barangay',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.small,
                          ),
                        ),
                      ),
                      items: _availableBarangays.map((barangay) {
                        return DropdownMenuItem(
                          value: barangay,
                          child: Text(barangay),
                        );
                      }).toList(),
                      onChanged: _selectedMunicipality == null
                          ? null
                          : (value) {
                              setState(() {
                                _selectedBarangay = value;
                              });
                            },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Barangay is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Street field
                CustomTextField(
                  label: 'Street/Purok/Sitio',
                  hintText: 'Enter your street, purok, or sitio',
                  controller: _streetController,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.home_outlined),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Buttons Row
                if (widget.isEditMode || !widget.showSkipButton)
                  Row(
                    children: [
                      // Back/Cancel Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            side: const BorderSide(color: AppTheme.lightGrey),
                          ),
                          child: Text(
                            widget.isEditMode ? 'Cancel' : 'Back',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Save/Continue Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleAddressSetup,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.textOnPrimary,
                                    ),
                                  ),
                                )
                              : Text(
                                  widget.isEditMode
                                      ? 'Save Address'
                                      : 'Add Address',
                                ),
                        ),
                      ),
                    ],
                  )
                else
                  // Continue button for onboarding
                  CustomButton(
                    text: 'Continue',
                    type: ButtonType.primary,
                    isFullWidth: true,
                    isLoading: _isLoading,
                    onPressed: _handleAddressSetup,
                  ),

                const SizedBox(height: AppSpacing.lg),

                // Skip note
                Center(
                  child: Text(
                    'You can update this information later in your profile settings.',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
