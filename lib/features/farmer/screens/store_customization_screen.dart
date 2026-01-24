import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/store_management_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widgets.dart';

class StoreCustomizationScreen extends StatefulWidget {
  const StoreCustomizationScreen({super.key});

  @override
  State<StoreCustomizationScreen> createState() =>
      _StoreCustomizationScreenState();
}

class _StoreCustomizationScreenState extends State<StoreCustomizationScreen>
    with SingleTickerProviderStateMixin {
  final StoreManagementService _storeService = StoreManagementService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storeDescriptionController =
      TextEditingController();
  final TextEditingController _storeMessageController = TextEditingController();
  final TextEditingController _businessHoursController =
      TextEditingController();

  bool _isStoreOpen = true;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _currentBannerUrl;
  String? _currentLogoUrl;
  Uint8List? _newBannerData;
  Uint8List? _newLogoData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentStoreInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _storeNameController.dispose();
    _storeDescriptionController.dispose();
    _storeMessageController.dispose();
    _businessHoursController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentStoreInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Get current user data
      final userData = await _authService.getCurrentUserProfile();
      if (userData != null) {
        setState(() {
          _storeNameController.text = userData.storeName ?? userData.fullName;
          _storeDescriptionController.text = userData.storeDescription ?? '';
          _storeMessageController.text = userData.storeMessage ?? '';
          _businessHoursController.text =
              userData.businessHours ?? 'Mon-Sun 6:00 AM - 6:00 PM';
          _isStoreOpen = userData.isStoreOpen;
          _currentBannerUrl = userData.storeBannerUrl;
          _currentLogoUrl = userData.storeLogoUrl ?? userData.avatarUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading store info: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickBannerImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 400,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _newBannerData = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickLogoImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _newLogoData = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveStoreInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Upload images if new ones were selected
      if (_newBannerData != null) {
        await _storeService.uploadStoreBanner(
          currentUser.id,
          _newBannerData!,
          'banner.jpg',
        );
      }

      if (_newLogoData != null) {
        await _storeService.uploadStoreLogo(
          currentUser.id,
          _newLogoData!,
          'logo.jpg',
        );
      }

      // Update store branding
      await _storeService.updateStoreBranding(
        farmerId: currentUser.id,
        storeName: _storeNameController.text.trim(),
        storeDescription: _storeDescriptionController.text.trim(),
        storeMessage: _storeMessageController.text.trim(),
        businessHours: _businessHoursController.text.trim(),
        isStoreOpen: _isStoreOpen,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store information updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear new image data
        setState(() {
          _newBannerData = null;
          _newLogoData = null;
        });

        // Reload current info
        _loadCurrentStoreInfo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating store: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Customization'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveStoreInfo,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Branding', icon: Icon(Icons.palette, size: 18)),
            Tab(text: 'Images', icon: Icon(Icons.image, size: 18)),
            Tab(text: 'Business', icon: Icon(Icons.business, size: 18)),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBrandingTab(),
                  _buildImagesTab(),
                  _buildBusinessTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildBrandingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Store Identity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Store Name
          TextFormField(
            controller: _storeNameController,
            decoration: const InputDecoration(
              labelText: 'Store Name',
              hintText: 'Enter your store name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.store),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Store name is required';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Store Description
          TextFormField(
            controller: _storeDescriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Store Description',
              hintText: 'Describe your farm and products...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Store description is required';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Store Message
          TextFormField(
            controller: _storeMessageController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Store Message (Optional)',
              hintText: 'Special announcement or message for customers',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.campaign),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Visual Identity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Store Banner
          _buildImageSection(
            title: 'Store Banner',
            subtitle: 'Recommended: 1200x400 pixels',
            currentImageUrl: _currentBannerUrl,
            newImageData: _newBannerData,
            onPickImage: _pickBannerImage,
            aspectRatio: 3.0,
          ),

          const SizedBox(height: 24),

          // Store Logo
          _buildImageSection(
            title: 'Store Logo',
            subtitle: 'Recommended: 400x400 pixels (square)',
            currentImageUrl: _currentLogoUrl,
            newImageData: _newLogoData,
            onPickImage: _pickLogoImage,
            aspectRatio: 1.0,
            isCircular: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Business Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Business Hours
          TextFormField(
            controller: _businessHoursController,
            decoration: const InputDecoration(
              labelText: 'Business Hours',
              hintText: 'e.g., Mon-Sun 6:00 AM - 6:00 PM',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.schedule),
            ),
          ),

          const SizedBox(height: 16),

          // Store Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Store Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Store is Open'),
                    subtitle: Text(
                      _isStoreOpen
                          ? 'Customers can place orders'
                          : 'Store is temporarily closed',
                    ),
                    value: _isStoreOpen,
                    onChanged: (value) {
                      setState(() {
                        _isStoreOpen = value;
                      });
                    },
                    activeThumbColor: AppTheme.primaryColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection({
    required String title,
    required String subtitle,
    String? currentImageUrl,
    Uint8List? newImageData,
    required VoidCallback onPickImage,
    required double aspectRatio,
    bool isCircular = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Image Preview
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: isCircular
                    ? BorderRadius.circular(60)
                    : BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: newImageData != null
                  ? ClipRRect(
                      borderRadius: isCircular
                          ? BorderRadius.circular(60)
                          : BorderRadius.circular(8),
                      child: Image.memory(
                        newImageData,
                        fit: BoxFit.cover,
                      ),
                    )
                  : currentImageUrl != null
                      ? ClipRRect(
                          borderRadius: isCircular
                              ? BorderRadius.circular(60)
                              : BorderRadius.circular(8),
                          child: Image.network(
                            currentImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImagePlaceholder(title);
                            },
                          ),
                        )
                      : _buildImagePlaceholder(title),
            ),

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickImage,
                    icon: const Icon(Icons.image),
                    label: Text(
                      newImageData != null || currentImageUrl != null
                          ? 'Change Image'
                          : 'Add Image',
                    ),
                  ),
                ),
                if (currentImageUrl != null || newImageData != null) ...[
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (title.contains('Banner')) {
                          _newBannerData = null;
                        } else {
                          _newLogoData = null;
                        }
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Remove Image',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            title.contains('Banner') ? Icons.landscape : Icons.store,
            size: 32,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'No ${title.toLowerCase()} set',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
