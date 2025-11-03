import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service for handling file uploads to Firebase Storage
class FileUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

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

  /// Upload a file to Firebase Storage
  /// Returns the download URL of the uploaded file
  Future<String> uploadFile({
    required PlatformFile file,
    required String path,
    Function(double)? onProgress,
  }) async {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final Reference ref = _storage.ref().child('$path/$fileName');

      UploadTask uploadTask;

      if (kIsWeb) {
        // Web: use bytes
        if (file.bytes == null) {
          throw Exception('No file data available for web upload');
        }
        uploadTask = ref.putData(
          file.bytes!,
          SettableMetadata(contentType: _getContentType(file.extension)),
        );
      } else {
        // Mobile/Desktop: use file path
        if (file.path == null) {
          throw Exception('No file path available');
        }
        final fileToUpload = File(file.path!);
        uploadTask = ref.putFile(
          fileToUpload,
          SettableMetadata(contentType: _getContentType(file.extension)),
        );
      }

      // Listen to upload progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  /// Upload multiple files
  /// Returns list of download URLs
  Future<List<String>> uploadMultipleFiles({
    required List<PlatformFile> files,
    required String path,
    Function(int current, int total)? onProgress,
  }) async {
    final List<String> downloadUrls = [];

    for (int i = 0; i < files.length; i++) {
      try {
        final url = await uploadFile(file: files[i], path: path);
        downloadUrls.add(url);
        onProgress?.call(i + 1, files.length);
      } catch (e) {
        throw Exception(
          'Failed to upload file ${files[i].name}: ${e.toString()}',
        );
      }
    }

    return downloadUrls;
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }

  /// Get content type based on file extension
  String? _getContentType(String? extension) {
    if (extension == null) return null;

    switch (extension.toLowerCase()) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';

      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';

      // Archives
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';

      // Videos
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mov':
        return 'video/quicktime';

      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';

      default:
        return 'application/octet-stream';
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
