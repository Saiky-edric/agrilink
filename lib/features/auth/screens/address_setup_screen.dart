import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/address_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/address_model.dart';
import '../../../core/constants/location_data.dart';
import '../../../core/utils/keyboard_utils.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/map_location_picker.dart';

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
  final LocationService _locationService = LocationService();
  final GeocodingService _geocodingService = GeocodingService();

  bool _isLoading = false;
  bool _isGettingLocation = false;
  bool _isDetectingAddress = false;
  String? _selectedMunicipality;
  String? _selectedBarangay;
  List<String> _availableBarangays = [];
  LocationCoordinates? _currentCoordinates;

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
    
    // Load existing coordinates if available
    if (address.hasCoordinates) {
      _currentCoordinates = LocationCoordinates(
        latitude: address.latitude!,
        longitude: address.longitude!,
        accuracy: address.accuracy,
      );
    }

    // Update available barangays for the selected municipality
    _updateAvailableBarangays(_selectedMunicipality!);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      final coordinates = await _locationService.getCurrentLocation();
      
      if (coordinates == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not get location. Please check your location settings.'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      // Check if within Agusan del Sur
      if (!_locationService.isWithinAgusanDelSur(
        coordinates.latitude,
        coordinates.longitude,
      )) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location is outside Agusan del Sur. You can still save it.'),
              backgroundColor: AppTheme.warningOrange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      setState(() {
        _currentCoordinates = coordinates;
        _isGettingLocation = false;
      });

      // Auto-detect and fill address from GPS
      await _autoFillAddressFromGPS(coordinates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Location captured! (Accuracy: ${coordinates.accuracy?.round() ?? 'N/A'}m)',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _autoFillAddressFromGPS(LocationCoordinates coordinates) async {
    setState(() => _isDetectingAddress = true);

    try {
      final address = await _geocodingService.getAddressFromCoordinates(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
      );

      if (address == null) {
        setState(() => _isDetectingAddress = false);
        return;
      }

      // Try to match detected municipality with our list
      final detectedMunicipality = address.municipality;
      final matchingMunicipality = LocationData.municipalities.firstWhere(
        (m) => m.toLowerCase().contains(detectedMunicipality.toLowerCase()) ||
               detectedMunicipality.toLowerCase().contains(m.toLowerCase()),
        orElse: () => '',
      );

      // Auto-fill fields
      if (matchingMunicipality.isNotEmpty) {
        setState(() {
          _selectedMunicipality = matchingMunicipality;
        });
        _updateAvailableBarangays(matchingMunicipality);

        // Try to match barangay
        final detectedBarangay = address.barangay;
        if (detectedBarangay.isNotEmpty) {
          final matchingBarangay = _availableBarangays.firstWhere(
            (b) => b.toLowerCase().contains(detectedBarangay.toLowerCase()) ||
                   detectedBarangay.toLowerCase().contains(b.toLowerCase()),
            orElse: () => '',
          );
          
          if (matchingBarangay.isNotEmpty) {
            setState(() {
              _selectedBarangay = matchingBarangay;
            });
          }
        }
      }

      // Auto-fill street if available
      if (address.street.isNotEmpty && _streetController.text.isEmpty) {
        _streetController.text = address.street;
      }

      setState(() => _isDetectingAddress = false);

      // Show success message with detected address
      if (mounted) {
        final detectedInfo = <String>[];
        if (matchingMunicipality.isNotEmpty) detectedInfo.add(matchingMunicipality);
        if (_selectedBarangay != null) detectedInfo.add(_selectedBarangay!);
        if (address.street.isNotEmpty) detectedInfo.add(address.street);

        if (detectedInfo.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Address Auto-Filled!', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detectedInfo.join(', '),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Please verify and adjust if needed',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              backgroundColor: AppTheme.primaryGreen,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error detecting address: $e');
      setState(() => _isDetectingAddress = false);
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLatitude: _currentCoordinates?.latitude,
          initialLongitude: _currentCoordinates?.longitude,
          onLocationSelected: (lat, lng) {
            // Update coordinates in real-time as user selects on map
          },
        ),
      ),
    );

    // Update coordinates when user confirms location
    if (result != null && result is dynamic) {
      final coordinates = LocationCoordinates(
        latitude: result.latitude as double,
        longitude: result.longitude as double,
      );

      setState(() {
        _currentCoordinates = coordinates;
      });

      // Auto-detect and fill address from selected map location
      await _autoFillAddressFromGPS(coordinates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Location selected from map!')),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    }
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
          latitude: _currentCoordinates?.latitude,
          longitude: _currentCoordinates?.longitude,
          accuracy: _currentCoordinates?.accuracy,
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
          latitude: _currentCoordinates?.latitude,
          longitude: _currentCoordinates?.longitude,
          accuracy: _currentCoordinates?.accuracy,
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

  Widget _buildLocationButton({
    IconData? icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              else if (icon != null)
                Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

                const SizedBox(height: AppSpacing.lg),

                // Map Preview (if coordinates available)
                if (_currentCoordinates != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location Preview',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MapPreview(
                        latitude: _currentCoordinates?.latitude,
                        longitude: _currentCoordinates?.longitude,
                        height: 180,
                        onTap: _openMapPicker,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),

                // Location Action Buttons
                Row(
                  children: [
                    // Use My Location Button
                    Expanded(
                      child: _buildLocationButton(
                        icon: _isGettingLocation
                            ? null
                            : (_currentCoordinates != null
                                ? Icons.my_location
                                : Icons.gps_fixed),
                        label: _currentCoordinates != null
                            ? 'Update GPS'
                            : 'Use My Location',
                        isLoading: _isGettingLocation,
                        onTap: _getCurrentLocation,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Pick on Map Button
                    Expanded(
                      child: _buildLocationButton(
                        icon: Icons.map_outlined,
                        label: 'Pick on Map',
                        onTap: _openMapPicker,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Coordinates Display (if available)
                if (_currentCoordinates != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.successGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.successGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Location Captured ✓',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppTheme.successGreen,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'GPS: ${_currentCoordinates!.latitude.toStringAsFixed(6)}, ${_currentCoordinates!.longitude.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: AppSpacing.lg),

                // Old Location Button (keeping for backward compatibility - hidden)
                Visibility(
                  visible: false,
                  child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                    border: Border.all(
                      color: _currentCoordinates != null
                          ? AppTheme.successGreen
                          : AppTheme.primaryGreen.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isGettingLocation ? null : _getCurrentLocation,
                      borderRadius: BorderRadius.circular(AppBorderRadius.small),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _currentCoordinates != null
                                    ? AppTheme.successGreen
                                    : AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _isGettingLocation
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      _currentCoordinates != null
                                          ? Icons.check_circle
                                          : Icons.my_location,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentCoordinates != null
                                        ? 'Location Captured ✓'
                                        : 'Use My Current Location',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: _currentCoordinates != null
                                          ? AppTheme.successGreen
                                          : AppTheme.primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _currentCoordinates != null
                                        ? 'GPS: ${_currentCoordinates!.latitude.toStringAsFixed(6)}, ${_currentCoordinates!.longitude.toStringAsFixed(6)}'
                                        : 'Optional: Helps with distance calculations',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: _currentCoordinates != null
                                  ? AppTheme.successGreen
                                  : AppTheme.primaryGreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Save button
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
