import 'dart:io';
import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:grocery_app/core/validators/image_validator.dart';
import 'package:path/path.dart' as path;

/// **Property 6: Image Validation**
/// **Validates: Requirements 2.4**
/// For any file upload, the system SHALL accept files with type 
/// JPEG/PNG/WebP and size ≤5MB, and reject all others.
void main() {
  late ImageValidator validator;
  late Directory tempDir;

  setUp(() {
    validator = ImageValidator();
    tempDir = Directory.systemTemp.createTempSync('image_validation_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // Helper to create a file with specific size and extension
  File createTestFile(String extension, int sizeBytes) {
    final fileName = 'test_${DateTime.now().millisecondsSinceEpoch}_${sizeBytes.hashCode}$extension';
    final file = File(path.join(tempDir.path, fileName));
    
    // Create file with specific size
    final randomBytes = List<int>.generate(sizeBytes, (i) => i % 256);
    file.writeAsBytesSync(randomBytes);
    
    return file;
  }

  group('Property 6: Image Validation', () {
    // Test with regular test cases for edge cases
    test('rejects invalid file extensions', () {
      final invalidExtensions = ['.gif', '.bmp', '.tiff', '.svg', '.pdf', '.txt'];
      
      for (final ext in invalidExtensions) {
        final file = createTestFile(ext, 1000);
        final result = validator.validate(file);
        
        expect(result.isValid, isFalse,
            reason: 'File with extension $ext should be rejected');
        expect(result.errorMessage, contains('Invalid file type'));
      }
    });

    test('rejects empty files', () {
      final file = createTestFile('.jpg', 0);
      final result = validator.validate(file);
      
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('empty'));
    });

    // Property-based tests
    Glados<int>().test('accepts valid JPEG files under 5MB', (size) {
      final validSize = (size.abs() % (ImageValidator.maxSizeBytes - 1)) + 1;
      final file = createTestFile('.jpg', validSize);
      
      final result = validator.validate(file);
      
      expect(result.isValid, isTrue,
          reason: 'JPEG file of ${ImageValidator.getFileSizeString(validSize)} should be valid');
    });

    Glados<int>().test('accepts valid PNG files under 5MB', (size) {
      final validSize = (size.abs() % (ImageValidator.maxSizeBytes - 1)) + 1;
      final file = createTestFile('.png', validSize);
      
      final result = validator.validate(file);
      
      expect(result.isValid, isTrue,
          reason: 'PNG file of ${ImageValidator.getFileSizeString(validSize)} should be valid');
    });

    Glados<int>().test('accepts valid WebP files under 5MB', (size) {
      final validSize = (size.abs() % (ImageValidator.maxSizeBytes - 1)) + 1;
      final file = createTestFile('.webp', validSize);
      
      final result = validator.validate(file);
      
      expect(result.isValid, isTrue,
          reason: 'WebP file of ${ImageValidator.getFileSizeString(validSize)} should be valid');
    });

    Glados<int>().test('accepts .jpeg extension as well as .jpg', (size) {
      final validSize = (size.abs() % (ImageValidator.maxSizeBytes - 1)) + 1;
      final file = createTestFile('.jpeg', validSize);
      
      final result = validator.validate(file);
      
      expect(result.isValid, isTrue,
          reason: '.jpeg extension should be valid');
    });

    Glados<int>().test('rejects files larger than 5MB', (extraBytes) {
      final invalidSize = ImageValidator.maxSizeBytes + (extraBytes.abs() % 10000000) + 1;
      final file = createTestFile('.jpg', invalidSize);
      
      final result = validator.validate(file);
      
      expect(result.isValid, isFalse,
          reason: 'File of ${ImageValidator.getFileSizeString(invalidSize)} should be rejected');
      expect(result.errorMessage, contains('exceeds maximum allowed size'));
    });

    Glados2<int, bool>().test('size validation is accurate', (sizeMultiplier, shouldBeValid) {
      final size = shouldBeValid 
          ? (sizeMultiplier.abs() % (ImageValidator.maxSizeBytes - 1000)) + 100  // Valid: ~100 to 5MB
          : ImageValidator.maxSizeBytes + (sizeMultiplier.abs() % 5000000) + 1;  // Invalid: > 5MB
      
      final file = createTestFile('.jpg', size);
      
      final result = validator.isValidSize(file);
      
      expect(result.isValid, equals(shouldBeValid),
          reason: 'File of ${ImageValidator.getFileSizeString(size)} should be ${shouldBeValid ? "valid" : "invalid"}');
    });

    Glados3<int, int, int>().test(
      'valid type + valid size = accepted',
      (extIndex, sizeMultiplier, seed) {
        final validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
        final extension = validExtensions[extIndex.abs() % validExtensions.length];
        final validSize = (sizeMultiplier.abs() % (ImageValidator.maxSizeBytes - 1000)) + 100;
        
        final file = createTestFile(extension, validSize);
        
        final result = validator.validate(file);
        
        expect(result.isValid, isTrue,
            reason: 'Valid file ($extension, ${ImageValidator.getFileSizeString(validSize)}) should be accepted');
      },
    );

    Glados2<bool, int>().test(
      'invalid type or size results in rejection',
      (useInvalidType, size) {
        File file;
        
        if (useInvalidType) {
          // Invalid type, any size
          final invalidExtensions = ['.gif', '.bmp', '.txt'];
          final ext = invalidExtensions[size.abs() % invalidExtensions.length];
          file = createTestFile(ext, 1000);
        } else {
          // Valid type, invalid size (> 5MB)
          final invalidSize = ImageValidator.maxSizeBytes + (size.abs() % 5000000) + 1;
          file = createTestFile('.jpg', invalidSize);
        }
        
        final result = validator.validate(file);
        
        expect(result.isValid, isFalse,
            reason: 'Invalid file should be rejected');
        expect(result.errorMessage, isNotNull);
      },
    );
  });
}
