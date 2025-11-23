import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Service for handling file uploads to Cloudinary
/// Supports PDF, Word, Excel, PowerPoint, and other document types
class FileUploadService {
  // ============================================
  // CẤU HÌNH CLOUDINARY - DÙNG CHUNG VỚI ImageUploadService
  // ============================================

  /// Cloud Name: Tên cloud của bạn (lấy từ Cloudinary Dashboard)
  static const String _cloudinaryCloudName = "du391fsvp";

  /// Upload Preset: Tên preset bạn đã tạo trong Cloudinary Dashboard
  /// Tạo preset mới: Dashboard -> Settings -> Upload -> Add upload preset
  /// - Preset name: "e-learning-files"
  /// - Signing mode: Unsigned
  /// - Delivery type: Upload (mặc định - code sẽ override thành Raw)
  /// - Access control: Public (QUAN TRỌNG!)
  /// - Format: Để trống
  /// - Allowed formats: pdf,doc,docx,xls,xlsx,ppt,pptx (tùy chọn)
  ///
  /// LƯU Ý: Code sẽ tự động dùng endpoint /raw/upload và resource_type='raw'
  /// để upload file như raw file, không cần preset có Type: Raw
  static const String _cloudinaryUploadPreset = "e-learning-files";

  /// Pick files from device
  /// Returns list of selected files
  Future<List<PlatformFile>?> pickFiles({
    FileType type = FileType.any,
    bool allowMultiple = false,
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowMultiple: allowMultiple,
        allowedExtensions: allowedExtensions,
        withData: kIsWeb, // Load file data on web
      );

      if (result != null) {
        return result.files;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick files: ${e.toString()}');
    }
  }

  /// Upload a file to Cloudinary (raw upload for documents)
  /// Returns the download URL of the uploaded file
  Future<String> uploadFile({
    required PlatformFile file,
    required String
    path, // Folder path in Cloudinary (e.g., 'courses/materials')
    Function(double)? onProgress,
    int? maxSizeInMB, // Maximum file size in MB
  }) async {
    try {
      // Validate file size if specified
      if (maxSizeInMB != null) {
        final fileSizeInBytes = file.size;
        final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
        if (fileSizeInBytes > maxSizeInBytes) {
          throw Exception(
            'File size exceeds maximum allowed size of ${maxSizeInMB}MB',
          );
        }
      }

      // Sanitize file name
      final sanitizedFileName = file.name
          .replaceAll(RegExp(r'[^\w\s.-]'), '_')
          .replaceAll(RegExp(r'\s+'), '_');

      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';

      // Cloudinary raw upload endpoint
      final String uploadUrl =
          'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/raw/upload';

      // Read file bytes
      final List<int> fileBytes;
      if (kIsWeb) {
        if (file.bytes == null) {
          throw Exception('No file data available for web upload');
        }
        fileBytes = file.bytes!;
      } else {
        if (file.path == null) {
          throw Exception('No file path available');
        }
        final fileToUpload = File(file.path!);

        // Check if file exists
        if (!await fileToUpload.exists()) {
          throw Exception('File does not exist');
        }

        fileBytes = await fileToUpload.readAsBytes();
      }

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Add upload preset
      request.fields['upload_preset'] = _cloudinaryUploadPreset;

      // Add folder
      request.fields['folder'] = path;

      // QUAN TRỌNG: Với unsigned upload preset, KHÔNG được gửi các parameters sau:
      // - 'type' (không được phép)
      // - 'access_mode' (phải set trong preset settings: Access control: Public)
      // - 'resource_type' (được xác định bởi endpoint URL: /raw/upload)
      // Access mode sẽ được set trong preset settings (Access control: Public)
      // Resource type được xác định bởi endpoint: /raw/upload = raw, /image/upload = image

      // QUAN TRỌNG: Giữ extension trong public_id để Cloudinary nhận diện đúng file type
      // Ví dụ: file.pdf thay vì chỉ file
      final publicId = fileName;
      request.fields['public_id'] = publicId;

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

      // Send request
      final streamedResponse = await request.send();

      // Simulate progress for better UX
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
        // For raw uploads, use secure_url or url
        String downloadUrl = data['secure_url'] ?? data['url'] ?? '';

        // QUAN TRỌNG: Đảm bảo URL đúng format cho raw files
        // Cloudinary raw files URL format: https://res.cloudinary.com/{cloud_name}/raw/upload/{public_id}
        // Với raw files, URL không nên có transformation

        if (downloadUrl.contains('/raw/upload/')) {
          // Parse URL để đảm bảo đúng format
          final uri = Uri.parse(downloadUrl);
          final pathSegments = uri.pathSegments;

          // Tìm vị trí các segments quan trọng
          final cloudinaryIndex = pathSegments.indexOf('cloudinary');
          final rawIndex = pathSegments.indexOf('raw');
          final uploadIndex = pathSegments.indexOf('upload');

          if (cloudinaryIndex != -1 &&
              rawIndex != -1 &&
              uploadIndex != -1 &&
              cloudinaryIndex < rawIndex &&
              rawIndex < uploadIndex) {
            // Lấy cloud name
            final cloudName = pathSegments[cloudinaryIndex + 1];

            // Lấy public_id (tất cả segments sau 'upload')
            final publicIdParts = pathSegments.sublist(uploadIndex + 1);

            // Loại bỏ version segment nếu có (format: v1234567890)
            // Version segment thường ngay sau 'upload'
            final cleanPublicIdParts = <String>[];

            for (int i = 0; i < publicIdParts.length; i++) {
              final segment = publicIdParts[i];
              // Bỏ qua version segment (v1234567890)
              if (RegExp(r'^v\d+$').hasMatch(segment)) {
                continue;
              }
              // Bỏ qua transformation segments (f_auto, q_auto, etc.)
              if (segment.startsWith('f_') ||
                  segment.startsWith('q_') ||
                  segment.startsWith('w_') ||
                  segment.startsWith('h_')) {
                continue;
              }
              cleanPublicIdParts.add(segment);
            }

            // Rebuild URL với format đúng: /raw/upload/{public_id}
            final publicId = cleanPublicIdParts.join('/');
            downloadUrl =
                'https://res.cloudinary.com/$cloudName/raw/upload/$publicId';

            // Đảm bảo có extension nếu original filename có
            if (fileName.contains('.') && !publicId.contains('.')) {
              final extension = fileName.split('.').last;
              downloadUrl = '$downloadUrl.$extension';
            }
          }
        }

        return downloadUrl;
      } else {
        // Parse error response để hiển thị lỗi rõ ràng hơn
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('error')) {
            final error = errorData['error'];
            final errorMessage = error['message']?.toString() ?? '';
            final errorCode = error['code']?.toString() ?? '';

            throw Exception(
              'Cloudinary upload failed: $errorMessage (Code: $errorCode)',
            );
          }
        } catch (e) {
          // If parsing fails, use original error
        }

        throw Exception(
          'Cloudinary upload failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to upload file to Cloudinary: ${e.toString()}');
    }
  }

  /// Upload multiple files
  /// Returns list of download URLs
  Future<List<String>> uploadMultipleFiles({
    required List<PlatformFile> files,
    required String path,
    Function(int current, int total)? onProgress,
    int? maxSizeInMB,
  }) async {
    if (files.isEmpty) {
      return [];
    }

    final List<String> downloadUrls = [];
    final List<String> errors = [];

    for (int i = 0; i < files.length; i++) {
      try {
        final url = await uploadFile(
          file: files[i],
          path: path,
          maxSizeInMB: maxSizeInMB,
        );
        downloadUrls.add(url);
        onProgress?.call(i + 1, files.length);
      } catch (e) {
        errors.add('${files[i].name}: ${e.toString()}');
        // Continue with other files instead of stopping
      }
    }

    // If some files failed, throw an error with details
    if (errors.isNotEmpty && downloadUrls.isEmpty) {
      throw Exception('Failed to upload all files:\n${errors.join('\n')}');
    } else if (errors.isNotEmpty) {
      // Some files succeeded, some failed
      throw Exception(
        'Some files failed to upload:\n${errors.join('\n')}\n\n'
        'Successfully uploaded: ${downloadUrls.length} file(s)',
      );
    }

    return downloadUrls;
  }

  /// Upload a file from file path (for use in repository layer)
  /// This is a convenience method that converts file path to PlatformFile
  /// Returns the download URL of the uploaded file
  Future<String> uploadFileFromPath({
    required String filePath,
    required String fileName,
    required String
    path, // Folder path in Cloudinary (e.g., 'courses/materials')
    Function(double)? onProgress,
    int? maxSizeInMB,
  }) async {
    try {
      // Read file to get bytes and size
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      final fileBytes = await file.readAsBytes();
      final fileSize = await file.length();

      // Create PlatformFile from file path
      final platformFile = PlatformFile(
        name: fileName,
        path: filePath,
        size: fileSize,
        bytes: fileBytes,
      );

      // Use existing uploadFile method
      return await uploadFile(
        file: platformFile,
        path: path,
        onProgress: onProgress,
        maxSizeInMB: maxSizeInMB,
      );
    } catch (e) {
      throw Exception('Failed to upload file from path: ${e.toString()}');
    }
  }

  /// Delete a file from Cloudinary
  /// NOTE: Với unsigned upload preset, không thể delete được
  /// Để delete được, cần dùng signed upload với API key và secret
  Future<void> deleteFile(String downloadUrl) async {
    try {
      if (!downloadUrl.contains('cloudinary.com')) {
        throw Exception('File URL is not from Cloudinary');
      }

      // Extract public_id from Cloudinary URL
      // Format: https://res.cloudinary.com/{cloud_name}/raw/upload/{public_id}
      final uri = Uri.parse(downloadUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length >= 3 &&
          (pathSegments[0] == 'raw' || pathSegments[0] == 'image') &&
          pathSegments[1] == 'upload') {
        // Delete from Cloudinary requires API key and secret
        // Với unsigned upload preset, không thể delete được
        throw Exception(
          'Không thể xóa file với unsigned upload preset. '
          'Để xóa được, cần cấu hình API key và secret trong Cloudinary.',
        );
      }

      throw Exception('Invalid Cloudinary URL format');
    } catch (e) {
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }

  /// Get file extension from filename
  String? getFileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return parts.last;
    }
    return null;
  }

  /// Get file size in human-readable format
  String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
