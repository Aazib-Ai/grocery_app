import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/image_storage_service.dart';
import '../../../core/config/supabase_config.dart';
import '../../riders/providers/rider_provider.dart';
import '../../../domain/entities/rider.dart';

/// Admin rider form screen for creating and editing riders.
class AdminRiderFormScreen extends StatefulWidget {
  final String? riderId;

  const AdminRiderFormScreen({super.key, this.riderId});

  bool get isEditMode => riderId != null;

  @override
  State<AdminRiderFormScreen> createState() => _AdminRiderFormScreenState();
}

class _AdminRiderFormScreenState extends State<AdminRiderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _vehicleNumberController = TextEditingController();

  late final ImageStorageService _imageStorage;
  final ImagePicker _imagePicker = ImagePicker();

  RiderStatus _status = RiderStatus.offline;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isSaving = false;
  File? _selectedImage;
  String? _currentAvatarUrl;
  Rider? _rider;

  @override
  void initState() {
    super.initState();
    // Use R2ImageStorageService for real image uploads
    _imageStorage = R2ImageStorageService();

    if (widget.isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRider();
      });
    }
  }

  Future<void> _loadRider() async {
    setState(() {
      _isLoading = true;
    });

    final provider = context.read<RiderProvider>();
    final rider = await provider.getRiderById(widget.riderId!);

    if (rider != null) {
      setState(() {
        _rider = rider;
        _nameController.text = rider.name;
        _phoneController.text = rider.phone;
        _emailController.text = rider.email ?? '';
        _vehicleTypeController.text = rider.vehicleType ?? '';
        _vehicleNumberController.text = rider.vehicleNumber ?? '';
        _status = rider.status;
        _isActive = rider.isActive;
        _currentAvatarUrl = rider.avatarUrl;
        _isLoading = false;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rider not found')),
        );
        context.go('/admin/riders');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) {
      return _currentAvatarUrl;
    }

    try {
      final userId = widget.riderId ?? 'new_rider_${DateTime.now().millisecondsSinceEpoch}';
      final imageUrl = await _imageStorage.uploadUserAvatar(
        _selectedImage!,
        userId,
      );

      if (widget.isEditMode && _currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) {
        try {
          await _imageStorage.deleteImage(_currentAvatarUrl!);
        } catch (e) {
          debugPrint('Failed to delete old image: $e');
        }
      }

      return imageUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _saveRider() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final imageUrl = await _uploadImage();
      final provider = context.read<RiderProvider>();

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
      final vehicleType = _vehicleTypeController.text.trim().isEmpty ? null : _vehicleTypeController.text.trim();
      final vehicleNumber = _vehicleNumberController.text.trim().isEmpty ? null : _vehicleNumberController.text.trim();

      if (widget.isEditMode) {
        final updated = await provider.updateRider(
          widget.riderId!,
          name: name,
          phone: phone,
          email: email,
          avatarUrl: imageUrl,
          vehicleType: vehicleType,
          vehicleNumber: vehicleNumber,
          status: _status,
          isActive: _isActive,
        );

        if (mounted && updated != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rider updated successfully'), backgroundColor: Colors.green),
          );
          context.go('/admin/riders');
        }
      } else {
        final created = await provider.createRider(
          name: name,
          phone: phone,
          email: email,
          avatarUrl: imageUrl,
          vehicleType: vehicleType,
          vehicleNumber: vehicleNumber,
        );

        if (mounted && created != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rider created successfully'), backgroundColor: Colors.green),
          );
          context.go('/admin/riders');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Rider' : 'Add Rider'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty
                                ? NetworkImage(_currentAvatarUrl!) as ImageProvider
                                : null),
                        child: _selectedImage == null && (_currentAvatarUrl == null || _currentAvatarUrl!.isEmpty)
                            ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: AppColors.primaryGreen,
                          radius: 18,
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter rider name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _vehicleTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Type',
                        hintText: 'e.g. Bike, Car',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.directions_bike),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _vehicleNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pin),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (widget.isEditMode) ...[
                DropdownButtonFormField<RiderStatus>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  items: RiderStatus.values.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()));
                  }).toList(),
                  onChanged: (value) => setState(() => _status = value!),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active Account'),
                  subtitle: const Text('Allow rider to receive orders'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  activeColor: AppColors.primaryGreen,
                ),
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveRider,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.isEditMode ? 'Update Rider' : 'Create Rider'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _isSaving ? null : () => context.pop(),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
