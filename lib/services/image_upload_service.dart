import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service for handling image uploads using Cloudinary or Firebase Storage
///
/// CẤU HÌNH CLOUDINARY:
/// 1. Đăng ký tài khoản tại https://cloudinary.com (miễn phí)
/// 2. Vào Dashboard -> Settings -> Upload
/// 3. Tạo Upload Preset:
///    - Vào "Upload presets" -> "Add upload preset"
///    - Đặt tên preset (ví dụ: "e_learning_app")
///    - Signing mode: Chọn "Unsigned" (để upload không cần API key)
///    - Folder: Có thể đặt folder mặc định (ví dụ: "e_learning")
///    - Save preset
/// 4. Lấy Cloud Name từ Dashboard (ở góc trên bên phải)
/// 5. Điền thông tin vào các biến bên dưới:
class ImageUploadService {
  // ============================================
  // CẤU HÌNH CLOUDINARY - ĐIỀN THÔNG TIN CỦA BẠN VÀO ĐÂY
  // ============================================

  /// Cloud Name: Tên cloud của bạn (lấy từ Cloudinary Dashboard)
  /// Ví dụ: Nếu URL của bạn là https://res.cloudinary.com/my-cloud-name/image/upload/
  ///        thì cloud name là "my-cloud-name"
  static const String _cloudinaryCloudName = "du391fsvp";

  /// Upload Preset: Tên preset bạn đã tạo trong Cloudinary Dashboard
  /// Upload Preset là gì?
  /// - Là một cấu hình upload được lưu sẵn trong Cloudinary
  /// - Cho phép upload KHÔNG CẦN API key/secret (unsigned upload)
  /// - Có thể cấu hình folder, format, quality, transformations mặc định
  /// - Tạo tại: Dashboard -> Settings -> Upload -> Upload presets
  ///
  /// LƯU Ý QUAN TRỌNG:
  /// - Với UNSIGNED upload preset (như hiện tại), bạn CHỈ CẦN cloud name và preset name
  /// - KHÔNG CẦN API key/secret để upload
  /// - KHÔNG CẦN khai báo CLOUDINARY_URL environment variable
  /// - API key/secret chỉ cần khi muốn:
  ///   + Signed upload (bảo mật hơn)
  ///   + Delete image (xóa hình ảnh)
  ///   + Admin API operations
  ///
  /// CLOUDINARY_URL format (chỉ cần khi dùng signed upload):
  /// CLOUDINARY_URL=cloudinary://api_key:api_secret@cloud_name
  /// 
  /// QUAN TRỌNG: Preset này dành cho IMAGES
  /// Tạo preset riêng: Dashboard -> Settings -> Upload -> Add upload preset
  /// - Preset name: "e-learning-images"
  /// - Type: Upload (cho images/videos)
  /// - Signing mode: Unsigned
  /// - Access mode: Public
  static const String _cloudinaryUploadPreset = "e-learning-images";

  // ============================================
  // CHỈ SỬ DỤNG CLOUDINARY - KHÔNG DÙNG FIREBASE STORAGE
  // ============================================

  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery or camera
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Compress image to 85% quality
        maxWidth: 1920, // Max width for optimization
        maxHeight: 1920, // Max height for optimization
      );
      return image;
    } catch (e) {
      throw Exception('Failed to pick image: ${e.toString()}');
    }
  }

  /// Upload image to Cloudinary
  /// Returns the URL of the uploaded image
  Future<String> uploadImage({
    required XFile imageFile,
    required String folder, // e.g., 'courses', 'users', 'avatars'
    String? fileName,
    Function(double)? onProgress,
  }) async {
    return await _uploadToCloudinary(
      imageFile: imageFile,
      folder: folder,
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  /// Upload image to Cloudinary
  Future<String> _uploadToCloudinary({
    required XFile imageFile,
    required String folder,
    String? fileName,
    Function(double)? onProgress,
  }) async {
    try {
      final String uploadUrl =
          'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload';

      // Read image bytes
      final List<int> imageBytes;
      if (kIsWeb) {
        imageBytes = await imageFile.readAsBytes();
      } else {
        final file = File(imageFile.path);
        imageBytes = await file.readAsBytes();
      }

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Add upload preset
      request.fields['upload_preset'] = _cloudinaryUploadPreset;

      // Add folder
      request.fields['folder'] = folder;

      // QUAN TRỌNG: Với unsigned upload preset, KHÔNG được gửi các parameters sau:
      // - 'type' (không được phép)
      // - 'access_mode' (phải set trong preset settings: Access control: Public)
      // Access mode sẽ được set trong preset settings (Access control: Public)

      // Add public_id if fileName is provided
      // QUAN TRỌNG: Thêm timestamp để tránh overwrite và cache URL cũ
      // Mỗi lần upload sẽ tạo file mới với unique ID
      if (fileName != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final uniqueFileName = '${fileName}_$timestamp';
        request.fields['public_id'] = uniqueFileName;
      }
      // Nếu không có fileName, Cloudinary sẽ tự generate unique ID

      // Add image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName ?? imageFile.name,
        ),
      );

      // Send request
      final streamedResponse = await request.send();

      // Simulate progress for better UX (Cloudinary doesn't provide upload progress)
      if (onProgress != null) {
        onProgress(0.5); // Show 50% during upload
      }

      // Read response
      final response = await http.Response.fromStream(streamedResponse);

      // Complete progress
      if (onProgress != null) {
        onProgress(1.0);
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String imageUrl = data['secure_url'] ?? data['url'];

        if (onProgress != null) {
          onProgress(1.0);
        }

        return imageUrl;
      } else {
        throw Exception(
          'Cloudinary upload failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to upload image to Cloudinary: ${e.toString()}');
    }
  }

  /// Delete image from Cloudinary
  /// NOTE: Với unsigned upload preset, không thể delete được
  /// Để delete được, cần dùng signed upload với API key và secret
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (!imageUrl.contains('cloudinary.com')) {
        throw Exception('Image URL is not from Cloudinary');
      }

      // Extract public_id from Cloudinary URL
      // Format: https://res.cloudinary.com/{cloud_name}/image/upload/{public_id}
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length >= 3 &&
          pathSegments[0] == 'image' &&
          pathSegments[1] == 'upload') {
        // Find the public_id (everything after /upload/)
        final publicIdIndex = pathSegments.indexOf('upload') + 1;
        if (publicIdIndex < pathSegments.length) {
          // Delete from Cloudinary requires API key and secret
          // Với unsigned upload preset, không thể delete được
          throw Exception(
            'Không thể xóa hình ảnh với unsigned upload preset. '
            'Để xóa được, cần cấu hình API key và secret trong Cloudinary.',
          );
        }
      }

      throw Exception('Invalid Cloudinary URL format');
    } catch (e) {
      throw Exception('Failed to delete image: ${e.toString()}');
    }
  }

  /// Get optimized image URL (for Cloudinary, returns transformed URL)
  String getOptimizedImageUrl(
    String originalUrl, {
    int? width,
    int? height,
    String? crop,
  }) {
    if (originalUrl.contains('cloudinary.com')) {
      // Cloudinary transformation
      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments;

      // Find upload index
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex != -1 && uploadIndex < pathSegments.length - 1) {
        final transformations = <String>[];

        if (width != null || height != null || crop != null) {
          if (crop != null) {
            transformations.add('c_$crop');
          }
          if (width != null) {
            transformations.add('w_$width');
          }
          if (height != null) {
            transformations.add('h_$height');
          }

          if (transformations.isNotEmpty) {
            final transformString = transformations.join(',');
            pathSegments.insert(uploadIndex + 1, transformString);
          }
        }

        return uri.replace(pathSegments: pathSegments).toString();
      }
    }

    // Return original URL if not Cloudinary or transformation not applicable
    return originalUrl;
  }
}
