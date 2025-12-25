import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../validators/image_validator.dart';
import '../error/app_exception.dart';

/// Abstract interface for image storage operations
abstract class ImageStorageService {
  /// Uploads a product image to R2 storage
  /// Returns the public URL of the uploaded image
  Future<String> uploadProductImage(File file, String productId);

  /// Uploads a user avatar to R2 storage
  /// Returns the public URL of the uploaded image
  Future<String> uploadUserAvatar(File file, String userId);

  /// Deletes an image from R2 storage by URL
  Future<void> deleteImage(String url);

  /// Gets the public URL for a given storage path
  String getPublicUrl(String path);
}

/// Implementation of ImageStorageService using Cloudflare R2 via Supabase Edge Functions
class R2ImageStorageService implements ImageStorageService {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final ImageValidator validator;
  final Uuid uuid;

  // Supabase Edge Function endpoint for R2 operations
  // TODO: Deploy this edge function to your Supabase project
  static const String edgeFunctionName = 'r2-upload';

  R2ImageStorageService({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    ImageValidator? validator,
    Uuid? uuid,
  })  : validator = validator ?? ImageValidator(),
        uuid = uuid ?? const Uuid();

  /// Uploads a product image to R2
  @override
  Future<String> uploadProductImage(File file, String productId) async {
    return _uploadImage(file, 'products', productId);
  }

  /// Uploads a user avatar to R2
  @override
  Future<String> uploadUserAvatar(File file, String userId) async {
    return _uploadImage(file, 'avatars', userId);
  }

  /// Internal method to handle image upload
  Future<String> _uploadImage(File file, String bucket, String entityId) async {
    // Validate the image
    final validationResult = validator.validate(file);
    if (!validationResult.isValid) {
      throw ValidationException(
        validationResult.errorMessage ?? 'Image validation failed',
      );
    }

    try {
      // Generate unique filename
      final extension = path.extension(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueId = uuid.v4();
      final filename = '${entityId}_${timestamp}_$uniqueId$extension';
      final filePath = '$bucket/$filename';

      // Read file as bytes
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Call Supabase Edge Function to upload to R2
      final uri = Uri.parse('$supabaseUrl/functions/v1/$edgeFunctionName');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseAnonKey',
        },
        body: jsonEncode({
          'action': 'upload',
          'path': filePath,
          'data': base64Image,
          'contentType': _getContentType(extension),
        }),
      );

      if (response.statusCode != 200) {
        throw StorageException(
          'Failed to upload image: ${response.body}',
          code: response.statusCode.toString(),
        );
      }

      // Parse response to get public URL
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final publicUrl = responseData['url'] as String?;

      if (publicUrl == null) {
        throw StorageException('No URL returned from upload');
      }

      return publicUrl;
    } on ValidationException {
      rethrow;
    } on StorageException {
      rethrow;
    } on SocketException catch (e) {
      throw NetworkException('Network error during upload: ${e.message}');
    } catch (e) {
      throw StorageException('Unexpected error during upload: $e');
    }
  }

  /// Deletes an image from R2 storage
  @override
  Future<void> deleteImage(String url) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(url);
      final path = uri.path;

      // Call Supabase Edge Function to delete from R2
      final edgeUri = Uri.parse('$supabaseUrl/functions/v1/$edgeFunctionName');
      final response = await http.post(
        edgeUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseAnonKey',
        },
        body: jsonEncode({
          'action': 'delete',
          'path': path,
        }),
      );

      if (response.statusCode != 200) {
        throw StorageException(
          'Failed to delete image: ${response.body}',
          code: response.statusCode.toString(),
        );
      }
    } on StorageException {
      rethrow;
    } on SocketException catch (e) {
      throw NetworkException('Network error during deletion: ${e.message}');
    } catch (e) {
      throw StorageException('Unexpected error during deletion: $e');
    }
  }

  /// Gets public URL for a storage path
  @override
  String getPublicUrl(String path) {
    // TODO: Update this with your actual R2 public URL format
    // This is a placeholder - actual URL depends on R2 configuration
    return 'https://your-r2-bucket.r2.cloudflarestorage.com/$path';
  }

  /// Gets content type from file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}

/// Mock implementation for testing without R2
class MockImageStorageService implements ImageStorageService {
  final ImageValidator validator;
  final Map<String, String> _uploadedImages = {};
  int _uploadCount = 0;

  MockImageStorageService({ImageValidator? validator})
      : validator = validator ?? ImageValidator();

  @override
  Future<String> uploadProductImage(File file, String productId) async {
    return _uploadImage(file, 'products', productId);
  }

  @override
  Future<String> uploadUserAvatar(File file, String userId) async {
    return _uploadImage(file, 'avatars', userId);
  }

  Future<String> _uploadImage(File file, String bucket, String entityId) async {
    // Validate the image
    final validationResult = validator.validate(file);
    if (!validationResult.isValid) {
      throw ValidationException(
        validationResult.errorMessage ?? 'Image validation failed',
      );
    }

    // Simulate upload delay
    await Future.delayed(const Duration(milliseconds: 100));

    _uploadCount++;
    final extension = path.extension(file.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = 'https://mock-r2.example.com/$bucket/${entityId}_${timestamp}_$_uploadCount$extension';
    
    _uploadedImages[url] = file.path;
    return url;
  }

  @override
  Future<void> deleteImage(String url) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _uploadedImages.remove(url);
  }

  @override
  String getPublicUrl(String path) {
    return 'https://mock-r2.example.com/$path';
  }

  /// Test helper: Check if URL was uploaded
  bool wasUploaded(String url) => _uploadedImages.containsKey(url);

  /// Test helper: Get all uploaded URLs
  List<String> get uploadedUrls => _uploadedImages.keys.toList();

  /// Test helper: Clear all uploads
  void clearUploads() {
    _uploadedImages.clear();
    _uploadCount = 0;
  }
}
