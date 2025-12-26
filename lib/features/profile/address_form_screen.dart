import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/address.dart';
import '../../shared/widgets/custom_button.dart';
import 'providers/profile_provider.dart';

class AddressFormScreen extends StatefulWidget {
  final Address? address; // If provided, we're editing; otherwise, creating

  const AddressFormScreen({super.key, this.address});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;
  bool _isDefault = false;
  
  // Map related
  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(31.5204, 74.3587); // Default to Lahore
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _labelController = TextEditingController(text: address?.label ?? '');
    _addressLine1Controller = TextEditingController(text: address?.addressLine1 ?? '');
    _addressLine2Controller = TextEditingController(text: address?.addressLine2 ?? '');
    _cityController = TextEditingController(text: address?.city ?? '');
    _postalCodeController = TextEditingController(text: address?.postalCode ?? '');
    _isDefault = address?.isDefault ?? false;
    
    // If editing and has coordinates, use them
    if (address?.latitude != null && address?.longitude != null) {
      _selectedLocation = LatLng(address!.latitude!, address.longitude!);
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<ProfileProvider>();
    final userId = provider.currentUserId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated'), backgroundColor: Colors.red),
      );
      return;
    }

    final address = Address(
      id: widget.address?.id ?? '',
      userId: userId,
      label: _labelController.text.trim().isEmpty ? null : _labelController.text.trim(),
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim().isEmpty ? null : _addressLine2Controller.text.trim(),
      city: _cityController.text.trim(),
      postalCode: _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim(),
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
      isDefault: _isDefault,
      createdAt: widget.address?.createdAt ?? DateTime.now(),
    );

    bool success;
    if (widget.address != null) {
      // Update existing address
      success = await provider.updateAddress(widget.address!.id, address);
    } else {
      // Create new address
      success = await provider.addAddress(address);
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.address != null ? 'Address updated successfully' : 'Address added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to save address'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openMapPicker() {
    setState(() {
      _showMap = true;
    });
  }

  void _closeMapPicker() {
    setState(() {
      _showMap = false;
    });
  }
  
  bool _isLoadingAddress = false;
  
  Future<void> _confirmLocationAndFillAddress() async {
    setState(() {
      _isLoadingAddress = true;
    });
    
    try {
      // Perform reverse geocoding to get address from coordinates
      final placemarks = await geocoding.placemarkFromCoordinates(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        // Build address line 1 from street, subLocality, etc.
        final addressParts = <String>[
          if (place.street != null && place.street!.isNotEmpty) place.street!,
          if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality!,
          if (place.locality != null && place.locality!.isNotEmpty && place.locality != place.subLocality) place.locality!,
        ];
        
        setState(() {
          // Fill address line 1 with street and area info
          if (addressParts.isNotEmpty) {
            _addressLine1Controller.text = addressParts.join(', ');
          }
          
          // Fill address line 2 with additional area info if available
          if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
            _addressLine2Controller.text = place.subAdministrativeArea!;
          }
          
          // Fill city
          if (place.locality != null && place.locality!.isNotEmpty) {
            _cityController.text = place.locality!;
          } else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            _cityController.text = place.administrativeArea!;
          }
          
          // Fill postal code
          if (place.postalCode != null && place.postalCode!.isNotEmpty) {
            _postalCodeController.text = place.postalCode!;
          }
        });
      }
    } catch (e) {
      // If geocoding fails, just close the map without filling fields
      debugPrint('Reverse geocoding failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get address details. Please fill manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
          _showMap = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.address != null;

    if (_showMap) {
      return _buildMapPickerScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F9),
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Address' : 'Add Address'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map preview / Location picker
                  const Text("Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  
                  GestureDetector(
                    onTap: _openMapPicker,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            FlutterMap(
                              options: MapOptions(
                                initialCenter: _selectedLocation,
                                initialZoom: 15,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none, // Disable interaction in preview
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.grocery_app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _selectedLocation,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_pin,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.touch_app, color: Colors.white, size: 32),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap to select location',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  Text(
                    'Lat: ${_selectedLocation.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation.longitude.toStringAsFixed(4)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text("Address Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),

                  // Label field
                  _buildTextField(
                    controller: _labelController,
                    label: 'Label (e.g., Home, Work)',
                    hint: 'Enter address label',
                  ),
                  const SizedBox(height: 16),

                  // Address Line 1 field
                  _buildTextField(
                    controller: _addressLine1Controller,
                    label: 'Address Line 1',
                    hint: 'Street address, P.O. box, company name',
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),

                  // Address Line 2 field
                  _buildTextField(
                    controller: _addressLine2Controller,
                    label: 'Address Line 2 (Optional)',
                    hint: 'Apartment, suite, unit, building, floor, etc.',
                  ),
                  const SizedBox(height: 16),

                  // City field
                  _buildTextField(
                    controller: _cityController,
                    label: 'City',
                    hint: 'Enter city',
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),

                  // Postal Code field
                  _buildTextField(
                    controller: _postalCodeController,
                    label: 'Postal Code (Optional)',
                    hint: 'Enter postal code',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),

                  // Set as default checkbox
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _isDefault,
                          onChanged: (value) {
                            setState(() {
                              _isDefault = value ?? false;
                            });
                          },
                          activeColor: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Set as default address',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (profileProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Column(
                      children: [
                        PrimaryButton(
                          text: isEditing ? "Update Address" : "Save Address",
                          onPressed: _saveAddress,
                        ),
                        if (isEditing) ...[
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => context.pop(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: AppColors.primaryGreen),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.primaryGreen, fontSize: 16),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapPickerScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _closeMapPicker,
        ),
        actions: [
          _isLoadingAddress
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _confirmLocationAndFillAddress,
                  child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 15,
              onTap: (tapPosition, latlng) {
                setState(() {
                  _selectedLocation = latlng;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.grocery_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Crosshair in center
          const Center(
            child: IgnorePointer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.keyboard_arrow_up, size: 30, color: Colors.black54),
                  Icon(Icons.circle, size: 12, color: Colors.black54),
                  Icon(Icons.keyboard_arrow_down, size: 30, color: Colors.black54),
                ],
              ),
            ),
          ),
          // Location info at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_pin, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Selected Location', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tap anywhere on the map to select a location',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
            ),
            keyboardType: keyboardType,
            validator: isRequired
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '$label is required';
                    }
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
