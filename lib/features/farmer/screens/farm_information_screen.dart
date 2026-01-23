import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/farmer_profile_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class FarmInformationScreen extends StatefulWidget {
  const FarmInformationScreen({super.key});

  @override
  State<FarmInformationScreen> createState() => _FarmInformationScreenState();
}

class _FarmInformationScreenState extends State<FarmInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final FarmerProfileService _profileService = FarmerProfileService();
  final AuthService _authService = AuthService();
  final SupabaseService _supabase = SupabaseService.instance;

  // Form controllers
  final _sizeController = TextEditingController();
  final _experienceController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<String> _selectedCrops = [];
  List<String> _selectedMethods = [];
  
  // Farm size dropdown options
  String? _selectedSizeOption;
  bool _useCustomSize = false;
  final List<String> _farmSizeOptions = [
    'Less than 1 hectare',
    '1-2 hectares',
    '2-5 hectares',
    '5-10 hectares',
    '10-20 hectares',
    'More than 20 hectares',
    'Custom size',
  ];
  
  bool _isLoading = true;
  bool _isSaving = false;
  FarmInformation? _farmInfo;

  final List<String> _availableCrops = [
    'Rice',
    'Corn',
    'Coconut',
    'Banana',
    'Cassava',
    'Sweet Potato',
    'Vegetables',
    'Fruits',
    'Coffee',
    'Cacao',
    'Sugarcane',
    'Abaca',
    'Rubber',
    'Oil Palm',
    'Other Crops',
  ];

  final List<String> _farmingMethods = [
    'Organic Farming',
    'Conventional Farming',
    'Integrated Pest Management',
    'Sustainable Agriculture',
    'Precision Agriculture',
    'Permaculture',
    'Hydroponics',
    'Aquaponics',
    'Agroforestry',
    'No-Till Farming',
    'Crop Rotation',
    'Mixed Farming',
  ];

  @override
  void initState() {
    super.initState();
    _loadFarmInformation();
  }

  @override
  void dispose() {
    _sizeController.dispose();
    _experienceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadFarmInformation() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final farmInfo = await _profileService.getFarmInformation(currentUser.id);
        
        setState(() {
          _farmInfo = farmInfo;
          _sizeController.text = farmInfo.size;
          _experienceController.text = farmInfo.yearsExperience.toString();
          _descriptionController.text = farmInfo.description ?? '';
          _selectedCrops = List<String>.from(farmInfo.primaryCrops);
          _selectedMethods = List<String>.from(farmInfo.farmingMethods);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading farm information: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _saveFarmInformation() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please fill in all required fields'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate farm size
    if (_sizeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please select or enter your farm size'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate years of experience
    if (_experienceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please enter your years of farming experience'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate primary crops
    if (_selectedCrops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please select at least one primary crop'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate farming methods
    if (_selectedMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please select at least one farming method'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Get farmer's location from users table
        final userResponse = await _supabase.client
            .from('users')
            .select('municipality, barangay')
            .eq('id', currentUser.id)
            .single();
        
        final farmerLocation = '${userResponse['barangay'] ?? ''}, ${userResponse['municipality'] ?? ''}';

        final farmInfo = FarmInformation(
          location: farmerLocation.trim(), // Use farmer's profile location
          size: _sizeController.text.trim(),
          primaryCrops: _selectedCrops,
          yearsExperience: int.tryParse(_experienceController.text.trim()) ?? 0,
          farmingMethods: _selectedMethods,
          description: _descriptionController.text.trim(),
        );

        await _profileService.updateFarmInformation(
          farmerId: currentUser.id,
          farmInfo: farmInfo,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Farm information saved successfully!'),
              backgroundColor: AppTheme.successGreen,
              duration: Duration(seconds: 2),
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving: $e'),
            backgroundColor: AppTheme.errorRed,
            duration: Duration(seconds: 4),
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
          'Farm Information',
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
            onPressed: _isSaving ? null : _saveFarmInformation,
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
                    // Farm Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.agriculture,
                            size: 48,
                            color: Colors.white,
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            'Farm Details',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Manage your farm information',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Basic Farm Information
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),


                    // Farm Size - Dropdown with custom option
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Farm Size *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSizeOption,
                              hint: const Text('Select farm size'),
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down),
                              items: _farmSizeOptions.map((size) {
                                return DropdownMenuItem<String>(
                                  value: size,
                                  child: Text(size),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSizeOption = value;
                                  if (value == 'Custom size') {
                                    _useCustomSize = true;
                                    _sizeController.clear();
                                  } else {
                                    _useCustomSize = false;
                                    _sizeController.text = value ?? '';
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        if (_useCustomSize) ...[
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _sizeController,
                            label: '',
                            prefixIcon: const Icon(Icons.straighten),
                            hintText: 'Enter custom size (e.g., 2.5 hectares, 5000 sqm)',
                            isRequired: true,
                            validator: (value) {
                              if (_useCustomSize && (value == null || value.isEmpty)) {
                                return 'Please enter your farm size';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    CustomTextField(
                      controller: _experienceController,
                      label: 'Years of Experience',
                      prefixIcon: const Icon(Icons.timeline),
                      type: TextFieldType.number,
                      hintText: 'Number of years',
                      isRequired: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter years of experience';
                        }
                        final years = int.tryParse(value);
                        if (years == null || years < 0) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Primary Crops
                    const Text(
                      'Primary Crops',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.sm),
                    
                    const Text(
                      'Select the main crops you grow',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableCrops.map((crop) {
                        final isSelected = _selectedCrops.contains(crop);
                        return FilterChip(
                          label: Text(crop),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCrops.add(crop);
                              } else {
                                _selectedCrops.remove(crop);
                              }
                            });
                          },
                          selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          checkmarkColor: AppTheme.primaryGreen,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Farming Methods
                    const Text(
                      'Farming Methods',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.sm),
                    
                    const Text(
                      'Select your farming practices',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _farmingMethods.map((method) {
                        final isSelected = _selectedMethods.contains(method);
                        return FilterChip(
                          label: Text(method),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedMethods.add(method);
                              } else {
                                _selectedMethods.remove(method);
                              }
                            });
                          },
                          selectedColor: AppTheme.secondaryGreen.withValues(alpha: 0.2),
                          checkmarkColor: AppTheme.secondaryGreen,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Farm Description
                    const Text(
                      'Farm Description',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Tell us about your farm',
                      prefixIcon: const Icon(Icons.description),
                      hintText: 'Describe your farming practices, specialties, etc.',
                      maxLines: 4,
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Save Button
                    CustomButton(
                      text: 'Save Farm Information',
                      onPressed: _isSaving ? null : _saveFarmInformation,
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