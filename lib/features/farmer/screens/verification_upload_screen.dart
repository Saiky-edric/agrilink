import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/farmer_verification_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/image_picker_widget.dart';
import '../../../core/constants/location_data.dart';

class VerificationUploadScreen extends StatefulWidget {
  const VerificationUploadScreen({super.key});

  @override
  State<VerificationUploadScreen> createState() => _VerificationUploadScreenState();
}

class _VerificationUploadScreenState extends State<VerificationUploadScreen> {
  final FarmerVerificationService _verificationService = FarmerVerificationService();
  final _formKey = GlobalKey<FormState>();
  final _farmNameController = TextEditingController();
  final _farmAddressController = TextEditingController();
  
  // Farm address dropdown values
  String? _selectedMunicipality;
  String? _selectedBarangay;
  final TextEditingController _streetController = TextEditingController();
  
  File? _farmerIdImage;
  File? _barangayCertImage;
  File? _selfieImage;
  
  bool _isLoading = false;
  final _authService = AuthService();

  @override
  void dispose() {
    _farmNameController.dispose();
    _farmAddressController.dispose();
    super.dispose();
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_farmerIdImage == null || _barangayCertImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload all required documents'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser!.id;
      
      // Submit verification using the service
      // Construct full farm address from dropdown selections
      final farmAddress = '${_streetController.text.trim()}, $_selectedBarangay, $_selectedMunicipality, Agusan del Sur';
      
      await _verificationService.submitVerification(
        farmerId: userId,
        farmName: _farmNameController.text.trim(),
        farmAddress: farmAddress,
        farmerIdImage: _farmerIdImage!,
        barangayCertImage: _barangayCertImage!,
        selfieImage: _selfieImage!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification submitted successfully! You will be notified once reviewed.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go(RouteNames.verificationStatus);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit verification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Verification'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue[600]),
                                const SizedBox(width: 8),
                                const Text(
                                  'Verification Requirements',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'To become a verified farmer on AgrLink, please provide the following:',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• Farm information (name and address)'),
                                Text('• Government-issued ID with photo'),
                                Text('• Barangay certification'),
                                Text('• Recent selfie for identity verification'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Farm Information Section
                    const Text(
                      'Farm Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      controller: _farmNameController,
                      label: 'Farm Name',
                      hintText: 'Enter your farm or business name',
                      prefixIcon: Icon(Icons.agriculture),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Farm name is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Farm Address Dropdown Section
                    const Text(
                      'Farm Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Municipality Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedMunicipality,
                      decoration: const InputDecoration(
                        labelText: 'Municipality',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      items: LocationData.municipalities
                          .map((municipality) => DropdownMenuItem(
                                value: municipality,
                                child: Text(municipality),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMunicipality = value;
                          _selectedBarangay = null; // Reset barangay when municipality changes
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a municipality';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Barangay Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBarangay,
                      decoration: const InputDecoration(
                        labelText: 'Barangay',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      items: _selectedMunicipality != null
                          ? LocationData.getBarangaysForMunicipality(_selectedMunicipality!)
                              .map((barangay) => DropdownMenuItem(
                                    value: barangay,
                                    child: Text(barangay),
                                  ))
                              .toList()
                          : [],
                      onChanged: _selectedMunicipality != null
                          ? (value) {
                              setState(() {
                                _selectedBarangay = value;
                              });
                            }
                          : null,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a barangay';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Street/Additional Address
                    CustomTextField(
                      controller: _streetController,
                      label: 'Street/Sitio/Additional Details',
                      hintText: 'Enter street, sitio, or additional farm location details',
                      prefixIcon: const Icon(Icons.place),
                      maxLines: 2,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please provide additional location details';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Documents Section
                    const Text(
                      'Required Documents',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Farmer ID
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DA RSBSA Farmer ID',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Upload a clear photo of your Department of Agriculture (DA) RSBSA Farmer ID.',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            ImagePickerWidget(
                              label: 'Upload Government ID',
                              onImageSelected: (file) {
                                setState(() => _farmerIdImage = file);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Barangay Certificate
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Barangay Certification',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Upload your Barangay Certificate confirming your farm location',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            ImagePickerWidget(
                              label: 'Upload Barangay Certificate',
                              onImageSelected: (file) {
                                setState(() => _barangayCertImage = file);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Selfie
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Identity Verification Selfie',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Take a recent selfie holding your government ID for identity verification',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            ImagePickerWidget(
                              label: 'Upload Verification Selfie',
                              onImageSelected: (file) {
                                setState(() => _selfieImage = file);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    CustomButton(
                      onPressed: _submitVerification,
                      text: 'Submit Verification',
                      isFullWidth: true,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Center(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}