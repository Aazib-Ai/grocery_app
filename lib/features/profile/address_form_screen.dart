import 'package:flutter/material.dart';
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
    final userId = provider.userProfile?.id;

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
      latitude: null,
      longitude: null,
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
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.address != null;

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
          onPressed: () => Navigator.pop(context),
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
                            onPressed: () => Navigator.pop(context),
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
