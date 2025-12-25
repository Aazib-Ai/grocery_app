import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import '../error/app_exception.dart';

/// Result of image validation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  factory ValidationResult.valid() => const ValidationResult(isValid: true);
  
  factory ValidationResult.invalid(String message) => ValidationResult(
    isValid: false,
    errorMessage: message,
  );
}

/// Validates image files for type and size constraints
class ImageValidator {
  // Maximum file size: 5MB
  static const int maxSizeBytes = 5 * 1024 * 1024; // 5MB
  
  // Allowed MIME types
  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];
  
  // Allowed file extensions
  static const List<String> allowedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  /// Validates an image file for type and size
  /// Returns ValidationResult indicating if file is valid
  ValidationResult validate(File file) {
    // Check if file exists
    if (!file.existsSync()) {
      return ValidationResult.invalid('File does not exist');
    }

    // Validate file type
    final typeValidation = isValidType(file);
    if (!typeValidation.isValid) {
      return typeValidation;
    }

    // Validate file size
    final sizeValidation = isValidSize(file);
    if (!sizeValidation.isValid) {
      return sizeValidation;
    }

    return ValidationResult.valid();
  }

  /// Checks if file type is valid (JPEG, PNG, or WebP)
  ValidationResult isValidType(File file) {
    // Check by extension
    final extension = path.extension(file.path).toLowerCase().replaceFirst('.', '');
    
    if (!allowedExtensions.contains(extension)) {
      return ValidationResult.invalid(
        'Invalid file type. Only JPEG, PNG, and WebP images are allowed. Got: .$extension'
      );
    }

    // Double-check with MIME type if available
    final mimeType = lookupMimeType(file.path);
    if (mimeType != null && !allowedMimeTypes.contains(mimeType)) {
      return ValidationResult.invalid(
        'Invalid file MIME type. Only JPEG, PNG, and WebP images are allowed. Got: $mimeType'
      );
    }

    return ValidationResult.valid();
  }

  /// Checks if file size is within allowed limit (≤5MB)
  ValidationResult isValidSize(File file) {
    final sizeBytes = file.lengthSync();
    
    if (sizeBytes > maxSizeBytes) {
      final sizeMB = (sizeBytes / (1024 * 1024)).toStringAsFixed(2);
      return ValidationResult.invalid(
        'File size exceeds maximum allowed size of 5MB. Got: ${sizeMB}MB'
      );
    }

    if (sizeBytes == 0) {
      return ValidationResult.invalid('File is empty');
    }

    return ValidationResult.valid();
  }

  /// Gets human-readable file size
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}
