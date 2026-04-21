import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'dio_client.dart';

class ImageUploadService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick single image from gallery
  static Future<File?> pickImageFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Pick multiple images from gallery
  static Future<List<File>> pickMultipleImages({int maxImages = 10}) async {
    final picked = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    return picked.take(maxImages).map((x) => File(x.path)).toList();
  }

  /// Pick image from camera
  static Future<File?> pickImageFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Upload images to server (standalone upload)
  static Future<ApiResponse<List<String>>> uploadImages(
      List<File> files) async {
    try {
      final dioClient = DioClient();
      final dio = dioClient.dio;
      final formData = FormData();

      for (final file in files) {
        final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
              contentType: DioMediaType.parse(mimeType),
            ),
          ),
        );
      }

      final response = await dio.post(
        '/api/v1/provider/upload-images',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final urls =
            (response.data['data']['urls'] as List<dynamic>).cast<String>();
        return ApiResponse.ok(urls);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to upload images',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  /// Upload and add images to existing service
  static Future<ApiResponse<List<String>>> addImagesToService(
    String serviceId,
    List<File> files,
  ) async {
    try {
      final dioClient = DioClient();
      final dio = dioClient.dio;
      final formData = FormData();

      for (final file in files) {
        final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
              contentType: DioMediaType.parse(mimeType),
            ),
          ),
        );
      }

      final response = await dio.post(
        '/api/v1/provider/services/$serviceId/images',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final urls =
            (response.data['data']['images'] as List<dynamic>).cast<String>();
        return ApiResponse.ok(urls);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to add images',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  /// Remove images from service
  static Future<ApiResponse<void>> removeImagesFromService(
    String serviceId,
    List<String> imageUrls,
  ) async {
    try {
      final dioClient = DioClient();
      final dio = dioClient.dio;
      final response = await dio.delete(
        '/api/v1/provider/services/$serviceId/images',
        data: {'imageUrls': imageUrls},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse.ok(null);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to remove images',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  /// Show image source selector dialog
  static Future<File?> showImageSourceSelector(BuildContext context) async {
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context).gallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context).camera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (result == null) return null;
    if (result == ImageSource.gallery) {
      return await pickImageFromGallery();
    } else {
      return await pickImageFromCamera();
    }
  }
}
