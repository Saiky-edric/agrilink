import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/farmer_profile_service.dart';
import '../../../core/constants/location_data.dart';
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

  // Form controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _streetController = TextEditingController();
  
  String? _selectedMunicipality;
  String? _selectedBarangay;
  
  bool _isLoading = true;
  bool _isSaving = false;
  FarmerProfileData? _profileData;

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
         _selectedBarangay = profile.barangay;
         _streetController.text = profile.street ?? '';
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
                      initialValue: _selectedMunicipality,
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
                          _selectedBarangay = null; // Reset barangay
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
                      initialValue: _selectedBarangay,
                      decoration: InputDecoration(
                        labelText: 'Barangay',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: (_selectedMunicipality != null)
                          ? LocationData.getBarangaysForMunicipality(_selectedMunicipality!).map((b) => DropdownMenuItem(
                                value: b,
                                child: Text(b),
                              )).toList()
                          : const [],
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