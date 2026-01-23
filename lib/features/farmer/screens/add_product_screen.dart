import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/product_service.dart';
import '../../../core/models/product_model.dart';
import '../../../core/constants/product_units.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/image_picker_widget.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/services/address_service.dart';
import '../../../core/models/address_model.dart';
import '../../../core/router/route_names.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _shelfLifeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _storeLocationController = TextEditingController();
  
  final AuthService _authService = AuthService();
  final ProductService _productService = ProductService();
  final PremiumService _premiumService = PremiumService();
  final AddressService _addressService = AddressService();
  
  bool _isLoading = false;
  ProductCategory _selectedCategory = ProductCategory.vegetables;
  String _selectedUnit = 'kg';
  final _weightKgController = TextEditingController();
  File? _coverImage;
  final List<File> _additionalImages = [];
  int _maxAdditionalImages = 3; // Default for free tier
  bool _isPremiumUser = false;
  
  // Address management
  List<AddressModel> _userAddresses = [];
  AddressModel? _selectedAddress;
  bool _loadingAddresses = true;
  
  // Common units for agricultural products (moved to ProductUnits)
  // import '../../core/constants/product_units.dart';
  final List<String> _availableUnits = ProductUnits.options;

  @override
  void initState() {
    super.initState();
    _checkFarmerVerification();
    _loadUserAddresses();
    _checkPremiumStatus();
  }
  
  Future<void> _checkPremiumStatus() async {
    try {
      final user = await _authService.getCurrentUserProfile();
      if (user != null) {
        final isPremium = user.isPremium;
        setState(() {
          _isPremiumUser = isPremium;
          _maxAdditionalImages = isPremium ? 4 : 3; // 4 for premium, 3 for free
        });
      }
    } catch (e) {
      // Default to free tier on error
      setState(() {
        _isPremiumUser = false;
        _maxAdditionalImages = 3;
      });
    }
  }

  @override
  void dispose() {
    _weightKgController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _shelfLifeController.dispose();
    _descriptionController.dispose();
    _storeLocationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAddresses() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final addresses = await _addressService.getUserAddresses(currentUser.id);
        
        setState(() {
          _userAddresses = addresses;
          _loadingAddresses = false;
          
          // Set default address as selected
          if (addresses.isNotEmpty) {
            _selectedAddress = addresses.firstWhere(
              (addr) => addr.isDefault,
              orElse: () => addresses.first,
            );
            _storeLocationController.text = _selectedAddress!.fullAddress;
          }
        });
        
        // If no addresses exist, create one from profile
        if (addresses.isEmpty) {
          await _createDefaultAddressFromProfile();
        }
      }
    } catch (e) {
      print('Error loading user addresses: $e');
      setState(() => _loadingAddresses = false);
    }
  }
  
  Future<void> _createDefaultAddressFromProfile() async {
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      final currentUser = _authService.currentUser;
      
      if (userProfile != null && currentUser != null) {
        final municipality = userProfile.municipality ?? '';
        final barangay = userProfile.barangay ?? '';
        
        if (municipality.isNotEmpty && barangay.isNotEmpty) {
          // Create default address from profile
          await _addressService.migrateProfileAddress(
            userId: currentUser.id,
            street: 'Primary Location',
            barangay: barangay,
            municipality: municipality,
          );
          
          // Reload addresses
          await _loadUserAddresses();
        }
      }
    } catch (e) {
      print('Error creating default address: $e');
    }
  }
  
  void _showAddressSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Select Pickup Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Address list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _userAddresses.length + 1, // +1 for add new button
                itemBuilder: (context, index) {
                  if (index == _userAddresses.length) {
                    // Add new address button
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_location_alt,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      title: const Text(
                        'Add New Address',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        // Navigate to address management to add new
                        final result = await context.push('/profile/addresses');
                        if (result == true) {
                          // Reload addresses if new one was added
                          await _loadUserAddresses();
                        }
                      },
                    );
                  }
                  
                  final address = _userAddresses[index];
                  final isSelected = _selectedAddress?.id == address.id;
                  
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryGreen 
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          address.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      address.fullAddress,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryGreen,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedAddress = address;
                        _storeLocationController.text = address.fullAddress;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkFarmerVerification() async {
    final isVerified = await _authService.isFarmerVerified();
    if (!isVerified && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be verified to add products'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      context.go(RouteNames.verificationStatus);
    }
  }

  Future<void> _handleAddProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_coverImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a cover image'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    // Check product limit for free tier users
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      if (userProfile != null && !userProfile.isPremium) {
        final productCount = await _productService.getProductCount(userProfile.id);
        if (productCount >= 3) {
          if (mounted) {
            _showUpgradeDialog();
          }
          return;
        }
      }
    } catch (e) {
      print('Error checking product limit: $e');
      // Continue if check fails - don't block product creation
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Prepare all images
      final allImages = [_coverImage!, ..._additionalImages];

      // Calculate expiry date if shelf life is provided
      DateTime? expiryDate;
      if (_shelfLifeController.text.isNotEmpty) {
        final shelfLifeDays = int.tryParse(_shelfLifeController.text);
        if (shelfLifeDays != null) {
          expiryDate = DateTime.now().add(Duration(days: shelfLifeDays));
        }
      }

      // Parse shelf life for product creation
      final enteredShelfLife = int.tryParse(_shelfLifeController.text) ?? 7;

      // Create product using the service
      await _productService.addProduct(
        farmerId: currentUser.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        stock: int.tryParse(_stockController.text) ?? 0,
        unit: _selectedUnit,
        category: _selectedCategory.name,
        images: allImages,
        storeLocation: _storeLocationController.text.trim(),
        shelfLifeDays: enteredShelfLife,
        weightPerUnitKgString: _weightKgController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add product: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.lock, color: AppTheme.primaryGreen),
            const SizedBox(width: 12),
            const Expanded(child: Text('Product Limit Reached')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You\'ve reached the limit of 3 products on the Basic (Free) plan.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: AppTheme.primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Premium Benefits',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitRow('Unlimited product listings'),
                  _buildBenefitRow('5 photos per product (vs 4)'),
                  _buildBenefitRow('Priority in search results'),
                  _buildBenefitRow('Featured on homepage'),
                  _buildBenefitRow('Premium Farmer badge'),
                  const SizedBox(height: 12),
                  Text(
                    'Only ₱149/month',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(RouteNames.subscription);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Upgrade to Premium'),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Images Section
                const Text(
                  'Product Images',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Cover Image
                ImagePickerWidget(
                  label: 'Cover Image',
                  hintText: 'This will be the main image shown to buyers',
                  isRequired: true,
                  onImageSelected: (image) => setState(() => _coverImage = image),
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Additional Images
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Additional Images',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_additionalImages.length}/$_maxAdditionalImages',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_additionalImages.length < _maxAdditionalImages)
                      GestureDetector(
                        onTap: () async {
                          // Show image picker
                          final picker = ImagePickerWidget(
                            label: '',
                            hintText: '',
                            onImageSelected: (image) {
                              if (image != null && _additionalImages.length < _maxAdditionalImages) {
                                setState(() => _additionalImages.add(image));
                              }
                            },
                          );
                          // Trigger the image picker
                          await showModalBottomSheet(
                            context: context,
                            builder: (context) => Container(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt, color: AppTheme.primaryGreen),
                                    title: const Text('Take Photo'),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      final ImagePicker imagePicker = ImagePicker();
                                      final XFile? photo = await imagePicker.pickImage(source: ImageSource.camera);
                                      if (photo != null) {
                                        setState(() => _additionalImages.add(File(photo.path)));
                                      }
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library, color: AppTheme.primaryGreen),
                                    title: const Text('Choose from Gallery'),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      final ImagePicker imagePicker = ImagePicker();
                                      final XFile? photo = await imagePicker.pickImage(source: ImageSource.gallery);
                                      if (photo != null) {
                                        setState(() => _additionalImages.add(File(photo.path)));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryGreen.withOpacity(0.3),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isPremiumUser 
                                      ? 'Tap to add more photos (Premium: up to 4!)' 
                                      : 'Tap to add more photos',
                                  style: const TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isPremiumUser 
                              ? Colors.amber.withOpacity(0.1)
                              : AppTheme.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isPremiumUser 
                                ? Colors.amber.withOpacity(0.3)
                                : AppTheme.successGreen.withOpacity(0.3)
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle, 
                              color: _isPremiumUser ? Colors.amber.shade700 : AppTheme.successGreen, 
                              size: 20
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isPremiumUser
                                    ? 'Maximum of 4 additional images added (Premium)'
                                    : 'Maximum of 3 additional images added',
                                style: TextStyle(
                                  color: _isPremiumUser ? Colors.amber.shade900 : AppTheme.successGreen, 
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                            ),
                            if (!_isPremiumUser) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => _premiumService.showUpgradeDialog(
                                  context,
                                  title: 'Get More Photo Slots',
                                  message: 'Upgrade to Premium and add up to 5 photos per product (1 cover + 4 additional)!',
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                child: const Text('Upgrade'),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
                
                if (_additionalImages.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _additionalImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppBorderRadius.small),
                                child: Image.file(
                                  _additionalImages[index],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _additionalImages.removeAt(index));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.errorRed,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                
                const SizedBox(height: AppSpacing.xl),
                
                // Product Details Section
                const Text(
                  'Product Details',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Product Name
                CustomTextField(
                  label: 'Product Name',
                  hintText: 'e.g., Fresh Tomatoes, Organic Lettuce',
                  controller: _nameController,
                  isRequired: true,
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Category
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category *',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<ProductCategory>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        hintText: 'Select product category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.small),
                        ),
                      ),
                      items: ProductCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Category is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Price and Unit
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        label: 'Price (₱)',
                        hintText: '0.00',
                        controller: _priceController,
                        type: TextFieldType.number,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Price is required';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Enter valid price';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2, // Increased flex to accommodate longer unit names
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Unit *',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedUnit,
                            isExpanded: true, // Prevents overflow by expanding to fit container
                            decoration: InputDecoration(
                              hintText: 'Select unit',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppBorderRadius.small),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                            items: _availableUnits.map((unit) {
                              return DropdownMenuItem(
                                value: unit,
                                child: Text(
                                  unit,
                                  overflow: TextOverflow.ellipsis, // Handle long text gracefully
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedUnit = value;
                                  // Auto-suggest weight based on unit selection
                                  final u = value.toLowerCase();
                                  String? suggestion;
                                  final kgMatch = RegExp(r'([0-9]+\.?[0-9]*)\s*kg').firstMatch(u);
                                  if (u == 'kg' || u == 'kilo' || u == 'kilogram') {
                                    suggestion = '1.0';
                                  } else if (kgMatch != null) {
                                    suggestion = kgMatch.group(1);
                                  } else if (u.contains('sack') || u.contains('bag')) {
                                    final sackMatch = RegExp(r'([0-9]+)\s*kg').firstMatch(u);
                                    suggestion = sackMatch != null ? sackMatch.group(1) : '25';
                                  }
                                  if (suggestion != null) {
                                    _weightKgController.text = suggestion;
                                  } else {
                                    // Clear previous auto-suggested value to avoid stale weights
                                    _weightKgController.clear();
                                  }
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Unit is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Weight per unit (kg)
                CustomTextField(
                  label: 'Weight per Unit (kg)',
                  hintText: 'e.g., 1.0 for 1 kg, 25 for 25 kg sack',
                  controller: _weightKgController,
                  type: TextFieldType.number,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Weight per unit is required';
                    }
                    final kg = double.tryParse(value);
                    if (kg == null || kg < 0) {
                      return 'Enter valid kilograms';
                    }
                    // Optional: enforce kg for known unit patterns
                    if (_selectedUnit.toLowerCase() == 'kg' && kg == 0) {
                      return 'For kg unit, weight must be 1.0 (or > 0).';
                      return 'For kg unit, weight should typically be 1.0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  'Always enter kilograms per unit. For pieces/bundles, estimate the typical kg per unit.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Stock and Shelf Life
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Stock Quantity',
                        hintText: '0',
                        controller: _stockController,
                        type: TextFieldType.number,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Stock is required';
                          }
                          final stock = int.tryParse(value);
                          if (stock == null || stock < 0) {
                            return 'Enter valid stock';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: CustomTextField(
                        label: 'Shelf Life (Days)',
                        hintText: '7',
                        controller: _shelfLifeController,
                        type: TextFieldType.number,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Shelf life is required';
                          }
                          final days = int.tryParse(value);
                          if (days == null || days <= 0) {
                            return 'Enter valid days';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Pickup Location (Address Selector)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pickup Location *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_loadingAddresses)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Loading addresses...'),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _showAddressSelector,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: _selectedAddress != null 
                                    ? AppTheme.primaryGreen 
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_selectedAddress != null) ...[
                                      Text(
                                        _selectedAddress!.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedAddress!.fullAddress,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ] else
                                      Text(
                                        'Select pickup location',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_selectedAddress == null && !_loadingAddresses)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 12),
                        child: Text(
                          'Please select a pickup location',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Description
                CustomTextField(
                  label: 'Description',
                  hintText: 'Describe your product, growing methods, quality, etc.',
                  controller: _descriptionController,
                  type: TextFieldType.multiline,
                  isRequired: true,
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Add Product Button
                CustomButton(
                  text: 'Add Product',
                  type: ButtonType.primary,
                  isFullWidth: true,
                  isLoading: _isLoading,
                  onPressed: _handleAddProduct,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}