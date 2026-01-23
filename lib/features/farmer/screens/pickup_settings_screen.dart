import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/constants/location_data.dart';
import '../../../core/models/user_model.dart';

class PickupSettingsScreen extends StatefulWidget {
  const PickupSettingsScreen({super.key});

  @override
  State<PickupSettingsScreen> createState() => _PickupSettingsScreenState();
}

class _PickupSettingsScreenState extends State<PickupSettingsScreen> {
  final AuthService _authService = AuthService();
  final SupabaseService _supabase = SupabaseService.instance;
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _pickupEnabled = false;
  
  // Pickup addresses management
  List<Map<String, dynamic>> _pickupAddresses = [];
  int _selectedAddressIndex = 0;
  
  // Location dropdowns
  String? _selectedMunicipality;
  String? _selectedBarangay;
  List<String> _availableBarangays = [];
  
  final TextEditingController _streetAddressController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _addressLabelController = TextEditingController();
  
  // Farm location
  String? _farmMunicipality;
  String? _farmBarangay;
  
  // Available days checkboxes
  final Map<String, bool> _availableDays = {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': true,
    'Sunday': false,
  };
  
  // Pickup hours
  TimeOfDay _openingTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPickupSettings();
  }

  @override
  void dispose() {
    _streetAddressController.dispose();
    _instructionsController.dispose();
    _addressLabelController.dispose();
    super.dispose();
  }

  Future<void> _loadPickupSettings() async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      // Load user profile to get farm location
      final userResponse = await _supabase.client
          .from('users')
          .select('pickup_enabled, pickup_addresses, pickup_instructions, pickup_hours, municipality, barangay, street')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse != null && mounted) {
        setState(() {
          _pickupEnabled = userResponse['pickup_enabled'] ?? false;
          _instructionsController.text = userResponse['pickup_instructions'] ?? '';
          
          // Store farm location
          _farmMunicipality = userResponse['municipality'] as String?;
          _farmBarangay = userResponse['barangay'] as String?;
          final farmStreetAddress = userResponse['street'] as String?;
          
          // Load pickup addresses
          final addressesData = userResponse['pickup_addresses'];
          if (addressesData != null && addressesData is List && addressesData.isNotEmpty) {
            _pickupAddresses = List<Map<String, dynamic>>.from(
              addressesData.map((addr) => Map<String, dynamic>.from(addr))
            );
          } else if (_farmMunicipality != null && _farmBarangay != null) {
            // Create default farm location address if no addresses exist
            _pickupAddresses = [
              {
                'label': 'Farm Location',
                'municipality': _farmMunicipality,
                'barangay': _farmBarangay,
                'street_address': farmStreetAddress ?? '',
                'is_default': true,
              }
            ];
          }
          
          // Load selected address
          if (_pickupAddresses.isNotEmpty) {
            _selectedAddressIndex = 0;
            _loadSelectedAddress();
          }
          
          // Parse pickup hours JSON
          if (userResponse['pickup_hours'] != null) {
            final hours = userResponse['pickup_hours'] as Map<String, dynamic>;
            
            // Update available days
            hours.forEach((day, value) {
              final capitalizedDay = day[0].toUpperCase() + day.substring(1).toLowerCase();
              if (_availableDays.containsKey(capitalizedDay)) {
                _availableDays[capitalizedDay] = value != 'CLOSED';
              }
            });
            
            // Try to parse opening/closing times from first available day
            for (var entry in hours.entries) {
              if (entry.value != 'CLOSED' && entry.value.toString().contains('-')) {
                final times = entry.value.toString().split('-');
                if (times.length == 2) {
                  _openingTime = _parseTime(times[0].trim()) ?? _openingTime;
                  _closingTime = _parseTime(times[1].trim()) ?? _closingTime;
                  break;
                }
              }
            }
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading pickup settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _loadSelectedAddress() {
    if (_pickupAddresses.isEmpty) return;
    
    final address = _pickupAddresses[_selectedAddressIndex];
    setState(() {
      _selectedMunicipality = address['municipality'] as String?;
      _selectedBarangay = address['barangay'] as String?;
      _streetAddressController.text = address['street_address'] as String? ?? '';
      _addressLabelController.text = address['label'] as String? ?? 'Address ${_selectedAddressIndex + 1}';
      
      // Update available barangays
      if (_selectedMunicipality != null) {
        _availableBarangays = LocationData.municipalityBarangays[_selectedMunicipality] ?? [];
      }
    });
  }

  TimeOfDay? _parseTime(String timeStr) {
    try {
      // Parse formats like "9:00 AM" or "5:00 PM"
      final parts = timeStr.replaceAll(RegExp(r'[^\d:]'), '').split(':');
      if (parts.length != 2) return null;
      
      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      if (timeStr.toUpperCase().contains('PM') && hour != 12) {
        hour += 12;
      } else if (timeStr.toUpperCase().contains('AM') && hour == 12) {
        hour = 0;
      }
      
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  Future<void> _savePickupSettings() async {
    // Validation is now handled later in the function
    setState(() => _isSaving = true);

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      // Build pickup hours JSON
      final pickupHours = <String, String>{};
      final hoursStr = '${_formatTime(_openingTime)} - ${_formatTime(_closingTime)}';
      
      _availableDays.forEach((day, isAvailable) {
        pickupHours[day.toLowerCase()] = isAvailable ? hoursStr : 'CLOSED';
      });

      // Validate current address before saving
      if (_selectedMunicipality == null || _selectedBarangay == null || _streetAddressController.text.trim().isEmpty) {
        _showErrorSnackBar('Please complete all address fields');
        setState(() => _isSaving = false);
        return;
      }
      
      // Update current address
      _updateCurrentAddress();

      // Update database
      await _supabase.client.from('users').update({
        'pickup_enabled': _pickupEnabled,
        'pickup_addresses': _pickupAddresses,
        'pickup_instructions': _instructionsController.text.trim(),
        'pickup_hours': pickupHours,
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pickup settings saved successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      _showErrorSnackBar('Error saving settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
  
  void _addNewAddress() {
    setState(() {
      _pickupAddresses.add({
        'label': 'Additional Location ${_pickupAddresses.length}',
        'municipality': null,
        'barangay': null,
        'street_address': '',
        'is_default': false,
      });
      _selectedAddressIndex = _pickupAddresses.length - 1;
      _selectedMunicipality = null;
      _selectedBarangay = null;
      _availableBarangays = [];
      _streetAddressController.clear();
      _addressLabelController.text = 'Additional Location ${_pickupAddresses.length}';
    });
  }
  
  void _removeAddress(int index) {
    if (_pickupAddresses.length <= 1) {
      _showErrorSnackBar('You must have at least one pickup address');
      return;
    }
    
    setState(() {
      _pickupAddresses.removeAt(index);
      if (_selectedAddressIndex >= _pickupAddresses.length) {
        _selectedAddressIndex = _pickupAddresses.length - 1;
      }
      _loadSelectedAddress();
    });
  }
  
  void _updateCurrentAddress() {
    if (_pickupAddresses.isEmpty) return;
    
    _pickupAddresses[_selectedAddressIndex] = {
      'label': _addressLabelController.text.trim().isEmpty 
          ? 'Address ${_selectedAddressIndex + 1}' 
          : _addressLabelController.text.trim(),
      'municipality': _selectedMunicipality,
      'barangay': _selectedBarangay,
      'street_address': _streetAddressController.text.trim(),
      'is_default': _pickupAddresses[_selectedAddressIndex]['is_default'] ?? false,
    };
  }

  Future<void> _selectTime(BuildContext context, bool isOpening) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? _openingTime : _closingTime,
    );

    if (picked != null && mounted) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pick-up Settings'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Pick-up Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enable Pickup Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.store_rounded,
                            color: AppTheme.primaryGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Enable Pick-up Option',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Allow buyers to pick up orders from your location',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _pickupEnabled,
                          onChanged: (value) {
                            setState(() => _pickupEnabled = value);
                          },
                          activeThumbColor: AppTheme.primaryGreen,
                        ),
                      ],
                    ),
                    if (_pickupEnabled) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Buyers will see ₱0 delivery fee for pickup orders',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            if (_pickupEnabled) ...[
              const SizedBox(height: 16),
              
              // Pickup Addresses - Enhanced with multiple addresses and dropdowns
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Pick-up Addresses',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          // Add new address button
                          if (_pickupAddresses.length < 5)
                            TextButton.icon(
                              onPressed: _addNewAddress,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add', style: TextStyle(fontSize: 13)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Address selector dropdown
                      if (_pickupAddresses.isNotEmpty)
                        DropdownButtonFormField<int>(
                          value: _selectedAddressIndex,
                          decoration: InputDecoration(
                            labelText: 'Select Address',
                            prefixIcon: const Icon(Icons.my_location),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: List.generate(_pickupAddresses.length, (index) {
                            final addr = _pickupAddresses[index];
                            final label = addr['label'] ?? 'Address ${index + 1}';
                            final isDefault = addr['is_default'] == true;
                            return DropdownMenuItem<int>(
                              value: index,
                              child: Row(
                                children: [
                                  Text(label),
                                  if (isDefault) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successGreen.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'DEFAULT',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.successGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              // Save current address before switching
                              _updateCurrentAddress();
                              setState(() {
                                _selectedAddressIndex = value;
                                _loadSelectedAddress();
                              });
                            }
                          },
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Address label/name field
                      TextField(
                        controller: _addressLabelController,
                        decoration: InputDecoration(
                          labelText: 'Address Name',
                          hintText: 'e.g., Main Farm, Market Stall, Warehouse',
                          prefixIcon: const Icon(Icons.label_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          helperText: 'Give this address a memorable name',
                          helperStyle: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Municipality dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedMunicipality,
                        decoration: InputDecoration(
                          labelText: 'Municipality *',
                          prefixIcon: const Icon(Icons.location_city),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: LocationData.municipalityBarangays.keys.map((municipality) {
                          return DropdownMenuItem<String>(
                            value: municipality,
                            child: Text(municipality),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMunicipality = value;
                            _selectedBarangay = null;
                            _availableBarangays = value != null
                                ? LocationData.municipalityBarangays[value] ?? []
                                : [];
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Barangay dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedBarangay,
                        decoration: InputDecoration(
                          labelText: 'Barangay *',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: _availableBarangays.map((barangay) {
                          return DropdownMenuItem<String>(
                            value: barangay,
                            child: Text(barangay),
                          );
                        }).toList(),
                        onChanged: _selectedMunicipality == null
                            ? null
                            : (value) {
                                setState(() => _selectedBarangay = value);
                              },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Street address
                      TextField(
                        controller: _streetAddressController,
                        decoration: InputDecoration(
                          labelText: 'Street Address / Landmark *',
                          hintText: 'e.g., 123 Main St, near City Hall',
                          prefixIcon: const Icon(Icons.home),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        maxLines: 2,
                      ),
                      
                      // Remove address button (only if more than 1 address)
                      if (_pickupAddresses.length > 1) ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => _removeAddress(_selectedAddressIndex),
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          label: const Text(
                            'Remove This Address',
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                      
                      // Info box
                      if (_farmMunicipality != null && _farmBarangay != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your farm location ($_farmMunicipality, $_farmBarangay) is set as your default pickup address.',
                                  style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Available Days
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppTheme.primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Available Days',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableDays.keys.map((day) {
                          final isSelected = _availableDays[day]!;
                          return FilterChip(
                            label: Text(day.substring(0, 3)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _availableDays[day] = selected;
                              });
                            },
                            selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
                            checkmarkColor: AppTheme.primaryGreen,
                            backgroundColor: Colors.grey.shade100,
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Pickup Hours
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, color: AppTheme.primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Pick-up Hours',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context, true),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Opening Time',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(_openingTime),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward, color: AppTheme.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context, false),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Closing Time',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(_closingTime),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Pickup Instructions
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Pick-up Instructions (Optional)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _instructionsController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'E.g., "Enter through main gate. Farm office is on the right. Ring bell if door is closed. Parking available on the left."',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 100), // Space for button
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _savePickupSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
