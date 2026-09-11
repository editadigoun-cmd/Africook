import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  final Dio _dio = Dio();

  String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  String get _uploadPreset => 'africook_unsigned';
  String get _baseUrl => 'https://api.cloudinary.com/v1_1/$_cloudName';

  Future<String?> uploadImage(XFile imageFile, {String folder = 'recipes'}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path),
        'upload_preset': _uploadPreset,
        'folder': folder,
      });

      final response = await _dio.post('$_baseUrl/image/upload', data: formData);
      return response.data['secure_url'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadImageBytes(Uint8List bytes,
      {required String fileName, String folder = 'recipes'}) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
        'upload_preset': _uploadPreset,
        'folder': folder,
      });
      final response = await _dio.post('$_baseUrl/image/upload', data: formData);
      return response.data['secure_url'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadVideoBytes(Uint8List bytes,
      {required String fileName, String folder = 'recipes/videos'}) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
        'upload_preset': _uploadPreset,
        'folder': folder,
        'resource_type': 'video',
      });
      final response = await _dio.post('$_baseUrl/video/upload', data: formData);
      return response.data['secure_url'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadVideo(File videoFile, {String folder = 'recipes/videos'}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(videoFile.path),
        'upload_preset': _uploadPreset,
        'folder': folder,
        'resource_type': 'video',
      });

      final response = await _dio.post('$_baseUrl/video/upload', data: formData);
      return response.data['secure_url'] as String?;
    } catch (e) {
      return null;
    }
  }

  String getThumbnailUrl(String videoUrl, {int width = 400, int height = 300}) {
    return videoUrl.replaceAll('/upload/', '/upload/w_$width,h_$height,c_fill/');
  }

  String getOptimizedImageUrl(String imageUrl,
      {int width = 800, int quality = 80}) {
    if (!imageUrl.contains('cloudinary.com')) return imageUrl;
    return imageUrl.replaceAll(
        '/upload/', '/upload/w_$width,q_$quality,f_auto/');
  }
}
