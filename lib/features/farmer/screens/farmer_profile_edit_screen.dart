import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/farmer_profile_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/constants/location_data.dart';
import '../../../shared/widgets/map_location_picker.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_widgets.dart';

class FarmerProfileEditScreen extends StatefulWidget {
  const FarmerProfileEditScreen({super.key});

  @override
  State<FarmerProfileEditScreen> createState() => _FarmerProfileEditScreenState();
}

class _FarmerProfileEditScreenState extends State<FarmerProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final FarmerProfileService _profileService = FarmerProfileService();
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();
  final GeocodingService _geocodingService = GeocodingService();

  // Form controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _streetController = TextEditingController();
  
  String? _selectedMunicipality;
  String? _selectedBarangay;
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isGettingLocation = false;
  bool _isDetectingAddress = false;
  FarmerProfileData? _profileData;
  LocationCoordinates? _currentCoordinates;

  final List<String> _municipalities = LocationData.municipalities;

  // Use centralized LocationData for barangays rather than hardcoding
  final Map<String, List<String>> _barangays = LocationData.municipalityBarangays;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final profile = await _profileService.getFarmerProfile(currentUser.id);
        
        setState(() {
          _profileData = profile;
          _fullNameController.text = profile.fullName;
          _phoneController.text = profile.phoneNumber ?? '';
          _emailController.text = profile.email;
          _selectedMunicipality = profile.municipality;
          _streetController.text = profile.street ?? '';
          
          // Load barangay only if it's valid for the selected municipality
          if (_selectedMunicipality != null) {
            final availableBarangays = LocationData.getBarangaysForMunicipality(_selectedMunicipality!);
            // Trim and exact match check
            final trimmedBarangay = profile.barangay?.trim();
            if (trimmedBarangay != null && trimmedBarangay.isNotEmpty) {
              // Check if the exact barangay exists in the list
              if (availableBarangays.contains(trimmedBarangay)) {
                _selectedBarangay = trimmedBarangay;
              } else {
                // Try to find a match by cleaning up the value
                final match = availableBarangays.firstWhere(
                  (b) => b.trim() == trimmedBarangay,
                  orElse: () => '',
                );
                _selectedBarangay = match.isNotEmpty ? match : null;
              }
            } else {
              _selectedBarangay = null;
            }
          } else {
            _selectedBarangay = null;
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _profileService.updateFarmerProfile(
          farmerId: currentUser.id,
          updates: {
            'full_name': _fullNameController.text.trim(),
            'phone_number': _phoneController.text.trim(),
            'municipality': _selectedMunicipality,
            'barangay': _selectedBarangay,
            'street': _streetController.text.trim(),
            'latitude': _currentCoordinates?.latitude,
            'longitude': _currentCoordinates?.longitude,
            'accuracy': _currentCoordinates?.accuracy,
            'updated_at': DateTime.now().toIso8601String(),
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
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

      // Try to match detected municipality
      final detectedMunicipality = address.municipality;
      final matchingMunicipality = _municipalities.firstWhere(
        (m) => m.toLowerCase().contains(detectedMunicipality.toLowerCase()) ||
               detectedMunicipality.toLowerCase().contains(m.toLowerCase()),
        orElse: () => '',
      );

      if (matchingMunicipality.isNotEmpty) {
        setState(() {
          _selectedMunicipality = matchingMunicipality;
        });

        // Try to match barangay
        final availableBarangays = LocationData.getBarangaysForMunicipality(matchingMunicipality);
        final detectedBarangay = address.barangay;
        if (detectedBarangay.isNotEmpty) {
          final matchingBarangay = availableBarangays.firstWhere(
            (b) => b.toLowerCase().contains(detectedBarangay.toLowerCase()) ||
                   detectedBarangay.toLowerCase().contains(b.toLowerCase()),
            orElse: () => '',
          );
          
          if (matchingBarangay.isNotEmpty) {
            setState(() => _selectedBarangay = matchingBarangay);
          }
        }
      }

      // Auto-fill street if available
      if (address.street.isNotEmpty && _streetController.text.isEmpty) {
        _streetController.text = address.street;
      }

      setState(() => _isDetectingAddress = false);

      // Show success message
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
                  Text(detectedInfo.join(', '), style: const TextStyle(fontSize: 13)),
                ],
              ),
              backgroundColor: AppTheme.primaryGreen,
              duration: const Duration(seconds: 3),
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
          onLocationSelected: (lat, lng) {},
        ),
      ),
    );

    if (result != null && result is dynamic) {
      final coordinates = LocationCoordinates(
        latitude: result.latitude as double,
        longitude: result.longitude as double,
      );

      setState(() => _currentCoordinates = coordinates);

      // Auto-detect and fill address
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
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
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
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
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
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture Section
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: AppTheme.primaryGreen,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    // Image picker functionality to be implemented
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Image picker feature coming soon!'),
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Photo upload coming soon!'),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryGreen,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const Text(
                            'Tap to change profile photo',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Personal Information
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    CustomTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      isRequired: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    CustomTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      type: TextFieldType.email,
                      enabled: false, // Email should not be editable
                    ),

                    const SizedBox(height: AppSpacing.md),

                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      type: TextFieldType.phone,
                      hintText: '+63 912 345 6789',
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length < 10) {
                            return 'Please enter a valid phone number';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Location Information
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Municipality Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedMunicipality,
                      decoration: InputDecoration(
                        labelText: 'Municipality',
                        prefixIcon: const Icon(Icons.location_city),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _municipalities.map((municipality) {
                        return DropdownMenuItem(
                          value: municipality,
                          child: Text(municipality),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMunicipality = value;
                          _selectedBarangay = null; // Reset barangay when municipality changes
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your municipality';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Street
                    CustomTextField(
                      controller: _streetController,
                      label: 'Street / House No. / Landmark',
                      prefixIcon: const Icon(Icons.home_outlined),
                      hintText: 'e.g., Purok 2, Poblacion',
                      validator: (value) {
                        if ((value == null || value.trim().isEmpty)) {
                          return 'Please enter your street / house / landmark';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Barangay Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedBarangay,
                      decoration: InputDecoration(
                        labelText: 'Barangay',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: (_selectedMunicipality != null)
                          ? LocationData.getBarangaysForMunicipality(_selectedMunicipality!)
                              .map((b) => DropdownMenuItem(
                                    value: b,
                                    child: Text(b),
                                  ))
                              .toList()
                          : [],
                      onChanged: (_selectedMunicipality != null)
                          ? (value) => setState(() => _selectedBarangay = value)
                          : null,
                      validator: (value) {
                        if (_selectedMunicipality != null) {
                          if (value == null || value.isEmpty) {
                            return 'Please select your barangay';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

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
                          const SizedBox(height: AppSpacing.md),
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

                    // Coordinates Display (if available)
                    if (_currentCoordinates != null) ...[
                      const SizedBox(height: 12),
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
                                    'Farm Location Captured ✓',
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
                    ],

                    const SizedBox(height: AppSpacing.xxl),

                    // Save Button
                    CustomButton(
                      text: 'Save Changes',
                      onPressed: _isSaving ? null : _saveProfile,
                      isLoading: _isSaving,
                      width: double.infinity,
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
    );
  }
}