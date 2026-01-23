# Pickup Address Implementation Guide

## Overview
This guide explains how to complete the pickup address feature that allows farmers to:
1. Use their farm location as the default pickup address
2. Add multiple pickup addresses using location dropdowns
3. Manage and select different pickup locations

## Database Changes ✅ COMPLETED

Run the SQL file: `supabase_setup/22_add_pickup_addresses_column.sql`

This adds:
- `pickup_addresses` JSONB column to store multiple addresses
- Migrates existing farm locations to the new format
- Creates indexes for performance

## Backend Changes ✅ COMPLETED

The following backend changes are already implemented in `pickup_settings_screen.dart`:

1. **Load farm location as default** ✅
   - Reads `municipality`, `barangay`, and `street_address` from user profile
   - Creates default "Farm Location" address if no addresses exist
   - Loads into `_pickupAddresses` array

2. **Address management methods** ✅
   - `_loadSelectedAddress()` - Loads selected address into form fields
   - `_addNewAddress()` - Adds a new address slot
   - `_removeAddress(index)` - Removes an address (keeps at least 1)
   - `_updateCurrentAddress()` - Saves current form data to the address
   - `_saveSettings()` - Validates and saves all addresses to database

3. **Location dropdown support** ✅
   - `_selectedMunicipality` and `_selectedBarangay` variables
   - `_availableBarangays` list updated when municipality changes
   - Integration with `LocationData.municipalityBarangays`

## UI Changes Needed 🔧

You need to replace the pickup address section in the UI (around line 427-470) with the following:

### Step 1: Find this section in `pickup_settings_screen.dart`:

```dart
// Pick-up Address Card
if (_pickupEnabled) ...[
  const SizedBox(height: 16),
  Card(
    // ... existing address TextField code
  ),
],
```

### Step 2: Replace with this new address management UI:

```dart
// Pick-up Addresses Card
if (_pickupEnabled) ...[
  const SizedBox(height: 16),
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
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
          
          // Municipality dropdown
          DropdownButtonFormField<String>(
            value: _selectedMunicipality,
            decoration: InputDecoration(
              labelText: 'Municipality',
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
            validator: (value) => value == null ? 'Please select municipality' : null,
          ),
          
          const SizedBox(height: 16),
          
          // Barangay dropdown
          DropdownButtonFormField<String>(
            value: _selectedBarangay,
            decoration: InputDecoration(
              labelText: 'Barangay',
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
            validator: (value) => value == null ? 'Please select barangay' : null,
          ),
          
          const SizedBox(height: 16),
          
          // Street address
          TextField(
            controller: _streetAddressController,
            decoration: InputDecoration(
              labelText: 'Street Address / Landmark',
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
],
```

## Testing Steps

1. **Run the SQL migration**:
   ```sql
   -- In Supabase SQL Editor
   -- Copy and paste: supabase_setup/22_add_pickup_addresses_column.sql
   ```

2. **Test the feature**:
   - Login as a farmer with farm information
   - Go to Pickup Settings
   - Verify farm location appears as default
   - Add a new address using dropdowns
   - Switch between addresses
   - Remove an address (should keep at least 1)
   - Save and reload to verify persistence

## Summary

✅ **Completed**:
- Database schema with `pickup_addresses` column
- Backend logic for loading, managing, and saving addresses
- Farm location automatically set as default
- Location dropdown integration

🔧 **To Do**:
- Replace the UI section in `pickup_settings_screen.dart` with the code above
- Test the feature end-to-end

## Benefits

- ✅ Farmers can manage multiple pickup locations
- ✅ Farm location is automatically used as default
- ✅ Easy location selection with dropdowns (same as address setup)
- ✅ Can add up to 5 pickup addresses
- ✅ Must keep at least 1 address
- ✅ Clear visual indicators for default address
