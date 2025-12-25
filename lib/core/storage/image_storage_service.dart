import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:xml/xml.dart';
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

/// Implementation of ImageStorageService using Cloudflare R2 via Direct AWS SigV4
class R2ImageStorageService implements ImageStorageService {
  final ImageValidator validator;
  final Uuid uuid;
  final String? accountId;
  final String? accessKeyId;
  final String? secretAccessKey;
  final String? bucketName;

  R2ImageStorageService({
    ImageValidator? validator,
    Uuid? uuid,
  })  : validator = validator ?? ImageValidator(),
        uuid = uuid ?? const Uuid(),
        accountId = dotenv.env['R2_ACCOUNT_ID'],
        accessKeyId = dotenv.env['R2_ACCESS_KEY_ID'],
        secretAccessKey = dotenv.env['R2_SECRET_ACCESS_KEY'],
        bucketName = dotenv.env['R2_BUCKET_NAME'];

  /// Uploads a product image to R2
  @override
  Future<String> uploadProductImage(File file, String productId) async {
    return _uploadDirectToR2(file, 'products', productId);
  }

  /// Uploads a user avatar to R2
  @override
  Future<String> uploadUserAvatar(File file, String userId) async {
    return _uploadDirectToR2(file, 'avatars', userId);
  }

  /// Internal method to handle direct R2 upload using AWS Ref4
  Future<String> _uploadDirectToR2(File file, String folder, String entityId) async {
    // Validate the image
    final validationResult = validator.validate(file);
    if (!validationResult.isValid) {
      throw ValidationException(
        validationResult.errorMessage ?? 'Image validation failed',
      );
    }

    if (accountId == null || accessKeyId == null || secretAccessKey == null || bucketName == null) {
      throw StorageException('R2 credentials are not configured in .env');
    }

    try {
      final extension = path.extension(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueId = uuid.v4();
      final objectKey = '$folder/${entityId}_${timestamp}_$uniqueId$extension';
      final fileBytes = await file.readAsBytes();
      final contentSha256 = sha256.convert(fileBytes).toString();
      final date = DateTime.now().toUtc(); // Use UTC for signing

      final endpoint = 'https://$accountId.r2.cloudflarestorage.com/$bucketName/$objectKey';
      
      // We will perform a PUT request
      final method = 'PUT';
      final service = 's3';
      final region = 'auto';
      final contentType = _getContentType(extension);

      // --- AWS Signature V4 Logic ---
      
      // 1. Canonical Request
      final amzDate = _formatAmzDate(date);
      final dateStamp = _formatDateStamp(date);
      
      // Headers must be sorted
      final canonicalUri = '/$bucketName/$objectKey';
      final canonicalQueryString = '';
      
      // Headers to sign
      final host = '$accountId.r2.cloudflarestorage.com';
      final canonicalHeaders = 
        'host:$host\n'
        'x-amz-content-sha256:$contentSha256\n'
        'x-amz-date:$amzDate\n';
        
      final signedHeaders = 'host;x-amz-content-sha256;x-amz-date';
      
      final canonicalRequest = 
        '$method\n'
        '$canonicalUri\n'
        '$canonicalQueryString\n'
        '$canonicalHeaders\n'
        '$signedHeaders\n'
        '$contentSha256';

      // 2. String to Sign
      final algorithm = 'AWS4-HMAC-SHA256';
      final credentialScope = '$dateStamp/$region/$service/aws4_request';
      final stringToSign = 
        '$algorithm\n'
        '$amzDate\n'
        '$credentialScope\n'
        '${sha256.convert(utf8.encode(canonicalRequest))}';
      
      // 3. Signature
      final signingKey = _getSignatureKey(secretAccessKey!, dateStamp, region, service);
      final signature = Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).toString();
      
      // 4. Authorization Header
      final authorization = 
        '$algorithm Credential=$accessKeyId/$credentialScope, '
        'SignedHeaders=$signedHeaders, '
        'Signature=$signature';
        
      final headers = {
        'Authorization': authorization,
        'x-amz-date': amzDate,
        'x-amz-content-sha256': contentSha256,
        'Content-Type': contentType,
        'Content-Length': fileBytes.length.toString(),
      };

      final response = await http.put(
        Uri.parse(endpoint),
        headers: headers,
        body: fileBytes,
      );

      if (response.statusCode != 200) {
        // Try to parse error from XML
        String errorMessage = response.body;
        try {
          final document = XmlDocument.parse(response.body);
          final message = document.findAllElements('Message').firstOrNull?.text;
          final code = document.findAllElements('Code').firstOrNull?.text;
          if (message != null) errorMessage = '$code: $message';
        } catch (_) {}

        throw StorageException(
          'Failed to upload image: $errorMessage',
          code: response.statusCode.toString(),
        );
      }

      // Return the public URL
      final publicDomain = dotenv.env['R2_PUBLIC_DOMAIN'] ?? 'https://pub-$accountId.r2.dev';
      return '$publicDomain/$objectKey';
      
    } on SocketException catch (e) {
      throw NetworkException('Network error during upload: ${e.message}');
    } catch (e) {
       if (e is StorageException || e is ValidationException) rethrow;
      throw StorageException('Unexpected error during upload: $e');
    }
  }

  @override
  Future<void> deleteImage(String url) async {
     if (accountId == null || accessKeyId == null || secretAccessKey == null || bucketName == null) {
      throw StorageException('R2 credentials are not configured');
    }

    try {
      // Extract object key from URL
      final uri = Uri.parse(url);
      final objectKey = uri.path.substring(1); // Remove leading slash

      final date = DateTime.now().toUtc();
      final endpoint = 'https://$accountId.r2.cloudflarestorage.com/$bucketName/$objectKey';
      
      // DELETE
      final method = 'DELETE';
      final service = 's3';
      final region = 'auto';
      
      final emptyHash = sha256.convert(utf8.encode('')).toString(); // Empty body
      final amzDate = _formatAmzDate(date);
      final dateStamp = _formatDateStamp(date);
      
      final canonicalUri = '/$bucketName/$objectKey';
      final host = '$accountId.r2.cloudflarestorage.com';
      
       final canonicalHeaders = 
        'host:$host\n'
        'x-amz-content-sha256:$emptyHash\n'
        'x-amz-date:$amzDate\n';
        
      final signedHeaders = 'host;x-amz-content-sha256;x-amz-date';
      
      final canonicalRequest = 
        '$method\n'
        '$canonicalUri\n'
        '\n' // Query string
        '$canonicalHeaders\n'
        '$signedHeaders\n'
        '$emptyHash';
        
      final algorithm = 'AWS4-HMAC-SHA256';
      final credentialScope = '$dateStamp/$region/$service/aws4_request';
      final stringToSign = 
        '$algorithm\n'
        '$amzDate\n'
        '$credentialScope\n'
        '${sha256.convert(utf8.encode(canonicalRequest))}';
      
      final signingKey = _getSignatureKey(secretAccessKey!, dateStamp, region, service);
      final signature = Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).toString();
      
      final authorization = 
        '$algorithm Credential=$accessKeyId/$credentialScope, '
        'SignedHeaders=$signedHeaders, '
        'Signature=$signature';
        
      final headers = {
        'Authorization': authorization,
        'x-amz-date': amzDate,
        'x-amz-content-sha256': emptyHash,
      };
      
      final response = await http.delete(Uri.parse(endpoint), headers: headers);
      
      if (response.statusCode != 204 && response.statusCode != 200) {
         throw StorageException('Failed to delete image. Code: ${response.statusCode}');
      }

    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('Unexpected error during deletion: $e');
    }
  }

  @override
  String getPublicUrl(String path) {
     final publicDomain = dotenv.env['R2_PUBLIC_DOMAIN'] ?? '';
     if (publicDomain.isNotEmpty) {
       return '$publicDomain/$path';
     }
     return path;
  }

  // --- Helpers ---

  String _formatAmzDate(DateTime date) {
    return date.toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first + 'Z';
  }

  String _formatDateStamp(DateTime date) {
    return date.toIso8601String().split('T').first.replaceAll('-', '');
  }

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
  
  List<int> _getSignatureKey(String key, String dateStamp, String regionName, String serviceName) {
    final kDate = Hmac(sha256, utf8.encode('AWS4$key')).convert(utf8.encode(dateStamp)).bytes;
    final kRegion = Hmac(sha256, kDate).convert(utf8.encode(regionName)).bytes;
    final kService = Hmac(sha256, kRegion).convert(utf8.encode(serviceName)).bytes;
    final kSigning = Hmac(sha256, kService).convert(utf8.encode('aws4_request')).bytes;
    return kSigning;
  }
}

/// Mock implementation for testing
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
    final validationResult = validator.validate(file);
    if (!validationResult.isValid) {
      throw ValidationException(
        validationResult.errorMessage ?? 'Image validation failed',
      );
    }
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
}
