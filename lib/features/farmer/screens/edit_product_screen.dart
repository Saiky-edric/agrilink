import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/product_service.dart';
import '../../../core/router/route_names.dart';
import '../../../core/constants/product_units.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _weightKgController = TextEditingController();

  final ProductService _productService = ProductService();
  bool _isSaving = false;
  String _selectedUnit = 'kg';
  final List<String> _availableUnits = ProductUnits.options;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController.text = p.name;
    _priceController.text = p.price.toStringAsFixed(2);
    _stockController.text = p.stock.toString();
    _descriptionController.text = p.description;
    final existingWeight = (p.toJson()['weight_per_unit'] as num?)?.toDouble() ?? 0.0;
    _weightKgController.text = existingWeight.toStringAsFixed(2);
    // Normalize unit to match dropdown options
    String unit = p.unit.toLowerCase();
    String normalized;
    if (ProductUnits.options.contains(p.unit)) {
      normalized = p.unit;
    } else if (unit.contains('sack')) {
      if (existingWeight >= 49) {
        normalized = 'sack 50 kg';
      } else {
        normalized = 'sack 25 kg';
      }
    } else if (unit.contains('bag')) {
      normalized = 'bag 25 kg';
    } else if (unit == 'kg' || unit == 'kilo' || unit == 'kilogram') {
      normalized = 'kg';
    } else {
      normalized = ProductUnits.options.first;
    }
    _selectedUnit = normalized;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _weightKgController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final price = double.tryParse(_priceController.text) ?? widget.product.price;
      final stock = int.tryParse(_stockController.text) ?? widget.product.stock;
      final unit = _selectedUnit;
      final weight = double.tryParse(_weightKgController.text) ??
          ((widget.product.toJson()['weight_per_unit'] as num?)?.toDouble() ?? 0.0);

      await _productService.updateProduct(
        productId: widget.product.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        stock: stock,
        unit: unit,
        weightPerUnitKg: weight,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully'), backgroundColor: AppTheme.successGreen),
        );
        if (Navigator.of(context).canPop()) {
          context.pop(true);
        } else {
          context.go(RouteNames.productList);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update product: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.productList);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Product Name',
                controller: _nameController,
                isRequired: true,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Price (₱)',
                      controller: _priceController,
                      type: TextFieldType.number,
                      isRequired: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CustomTextField(
                      label: 'Stock',
                      controller: _stockController,
                      type: TextFieldType.number,
                      isRequired: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Unit *', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedUnit,
                          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Select unit'),
                          items: _availableUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedUnit = value;
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
                                  _weightKgController.clear();
                                }
                              });
                            }
                          },
                          validator: (value) => (value == null || value.isEmpty) ? 'Unit is required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          label: 'Weight per Unit (kg)',
                          controller: _weightKgController,
                          type: TextFieldType.number,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            final kg = double.tryParse(value);
                            if (kg == null || kg < 0) return 'Enter valid kg';
                            if (_selectedUnit.toLowerCase() == 'kg' && kg == 0) return 'For kg unit, weight must be 1.0 (or > 0).';
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Always enter kilograms per unit. For pieces/bundles, estimate the typical kg per unit.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                label: 'Description',
                controller: _descriptionController,
                type: TextFieldType.multiline,
                isRequired: true,
              ),
              const SizedBox(height: AppSpacing.md),
              // Shelf Life Information (Read-only)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: widget.product.isExpired 
                      ? AppTheme.errorRed.withOpacity(0.1)
                      : widget.product.isExpiringWithin3Days
                          ? Colors.orange.withOpacity(0.1)
                          : AppTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.product.isExpired 
                        ? AppTheme.errorRed
                        : widget.product.isExpiringWithin3Days
                            ? Colors.orange
                            : AppTheme.successGreen,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.product.isExpired 
                              ? Icons.error_outline
                              : Icons.info_outline,
                          color: widget.product.isExpired 
                              ? AppTheme.errorRed
                              : widget.product.isExpiringWithin3Days
                                  ? Colors.orange
                                  : AppTheme.successGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Shelf Life Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.product.isExpired 
                                ? AppTheme.errorRed
                                : widget.product.isExpiringWithin3Days
                                    ? Colors.orange
                                    : AppTheme.successGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Shelf Life: ${widget.product.shelfLifeDays} days',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Created: ${_formatDate(widget.product.createdAt)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Expires: ${_formatDate(widget.product.expiryDate)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.product.isExpired ? AppTheme.errorRed : null,
                      ),
                    ),
                    if (!widget.product.isExpired)
                      Text(
                        widget.product.daysUntilExpiry == 0
                            ? 'Expires today!'
                            : 'Days remaining: ${widget.product.daysUntilExpiry}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.product.isExpiringWithin3Days
                              ? Colors.orange
                              : AppTheme.successGreen,
                        ),
                      ),
                    if (widget.product.isExpired)
                      const Text(
                        '⚠️ This product has expired and will be hidden from buyers',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.errorRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              CustomButton(
                text: 'Save Changes',
                isFullWidth: true,
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
