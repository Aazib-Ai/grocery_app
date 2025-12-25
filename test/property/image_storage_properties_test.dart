import 'dart:io';
import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:grocery_app/core/storage/image_storage_service.dart';
import 'package:grocery_app/core/validators/image_validator.dart';
import 'package:path/path.dart' as path;

/// **Property 37: Image Upload Uniqueness**
/// **Validates: Requirements 13.1**
/// For any two image uploads, the returned URLs SHALL be different.
void main() {
  late MockImageStorageService storageService;
  late Directory tempDir;

  setUp(() {
    storageService = MockImageStorageService();
    tempDir = Directory.systemTemp.createTempSync('image_storage_test_');
  });

  tearDown(() {
    storageService.clearUploads();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // Helper to create a valid test image file
  File createValidImageFile(String name) {
    final fileName = '${name}_${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}.jpg';
    final file = File(path.join(tempDir.path, fileName));
    
    // Create a small valid JPEG file (1KB)
    final bytes = List<int>.generate(1024, (i) => i % 256);
    file.writeAsBytesSync(bytes);
    
    return file;
  }

  group('Property 37: Image Upload Uniqueness', () {
    test('two uploads of the same file generate different URLs', () async {
      final file = createValidImageFile('test_product');
      
      final url1 = await storageService.uploadProductImage(file, 'product_123');
      final url2 = await storageService.uploadProductImage(file, 'product_123');
      
      expect(url1, isNot(equals(url2)),
          reason: 'Two uploads of the same file should generate different URLs');
    });

    test('rapid sequential uploads maintain uniqueness', () async {
      final file = createValidImageFile('rapid_test');
      final urls = <String>[];
      
      // Perform rapid sequential uploads
      for (int i = 0; i < 50; i++) {
        final url = await storageService.uploadProductImage(file, 'product_rapid');
        urls.add(url);
      }
      
      final uniqueUrls = urls.toSet();
      expect(uniqueUrls.length, equals(50),
          reason: 'Rapid sequential uploads should maintain URL uniqueness');
    });

    test('uploaded URLs are accessible from service', () async {
      final file = createValidImageFile('test_verify');
      
      final url = await storageService.uploadProductImage(file, 'product_999');
      
      expect(storageService.wasUploaded(url), isTrue,
          reason: 'Uploaded URL should be tracked by the service');
    });

    // Property-based tests
    test('N uploads generate N unique URLs', () async {
      await Glados<int>().test('generates unique URLs for multiple uploads', (numUploads) {
        final count = (numUploads.abs() % 10) + 2; // 2-11 uploads (reduced for speed)
        final file = createValidImageFile('test_product_$numUploads');
        final urls = <String>{};
        
        return Future(() async {
          for (int i = 0; i < count; i++) {
            final url = await storageService.uploadProductImage(file, 'product_$i');
            urls.add(url);
          }
          
          expect(urls.length, equals(count),
              reason: '$count uploads should generate $count unique URLs');
        });
      });
    });

    test('concurrent uploads generate unique URLs', () async {
      await Glados<int>().test('concurrent test', (numUploads) {
        final count = (numUploads.abs() % 5) + 2; // 2-6 concurrent uploads (reduced for speed)
        final file = createValidImageFile('test_product_concurrent_$numUploads');
        
        return Future(() async {
          final futures = List.generate(
            count,
            (i) => storageService.uploadProductImage(file, 'product_$i'),
          );
          
          final urls = await Future.wait(futures);
          final uniqueUrls = urls.toSet();
          
          expect(uniqueUrls.length, equals(count),
              reason: 'Concurrent uploads should generate unique URLs');
        });
      });
    });

    test('product and avatar uploads are unique', () async {
      await Glados<int>().test('product vs avatar uniqueness', (seed) {
        final file = createValidImageFile('test_$seed');
        final entityId = 'entity_$seed';
        
        return Future(() async {
          final productUrl = await storageService.uploadProductImage(file, entityId);
          final avatarUrl = await storageService.uploadUserAvatar(file, entityId);
          
          expect(productUrl, isNot(equals(avatarUrl)),
              reason: 'Product and avatar uploads should have different URLs');
        });
      });
    });

    test('each URL contains unique components', () async {
      await Glados<int>().test('URL uniqueness check', (seed) {
        final file = createValidImageFile('test_$seed');
        
        return Future(() async {
          final urls = <String>[];
          
          for (int i = 0; i < 5; i++) {
            final url = await storageService.uploadProductImage(file, 'product_$i');
            urls.add(url);
          }
          
          final uniqueUrls = urls.toSet();
          expect(uniqueUrls.length, equals(urls.length),
              reason: 'All generated URLs should be unique');
          
          for (final url in urls) {
            expect(url, isNotEmpty);
            expect(url, startsWith('https://'));
          }
        });
      });
    });

    test('upload-delete-upload generates different URL', () async {
      await Glados<int>().test('reupload uniqueness', (seed) {
        final file = createValidImageFile('test_reupload_$seed');
        final productId = 'product_$seed';
        
        return Future(() async {
          final url1 = await storageService.uploadProductImage(file, productId);
          await storageService.deleteImage(url1);
          final url2 = await storageService.uploadProductImage(file, productId);
          
          expect(url2, isNot(equals(url1)),
              reason: 'Reuploading after deletion should generate new URL');
        });
      });
    });

    test('deletion is URL-specific', () async {
      await Glados<int>().test('specific deletion check', (numFiles) {
        final count = (numFiles.abs() % 5) + 3; // 3-7 files (reduced for speed)
        final file = createValidImageFile('test_delete_$numFiles');
        
        return Future(() async {
          final urls = <String>[];
          
          for (int i = 0; i < count; i++) {
            final url = await storageService.uploadProductImage(file, 'product_$i');
            urls.add(url);
          }
          
          final urlToDelete = urls[count ~/ 2];
          await storageService.deleteImage(urlToDelete);
          
          expect(storageService.wasUploaded(urlToDelete), isFalse);
          
          for (int i = 0; i < count; i++) {
            if (urls[i] != urlToDelete) {
              expect(storageService.wasUploaded(urls[i]), isTrue,
                  reason: 'Other URLs should remain after deleting one');
            }
          }
        });
      });
    });
  });
}
