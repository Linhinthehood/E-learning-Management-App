import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for downloading and opening files from URLs (Cloudinary, etc.)
class FileDownloadService {
  /// Open file in browser/app (view only, no download)
  /// For web: opens in new tab
  /// For mobile: opens URL in browser
  Future<void> openFile({required String fileUrl}) async {
    try {
      final uri = Uri.parse(fileUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      throw Exception('Failed to open file: ${e.toString()}');
    }
  }

  /// Download file to device
  /// For web: triggers browser download
  /// For mobile/desktop: saves to downloads folder
  Future<void> downloadFile({
    required String fileUrl,
    required String fileName,
  }) async {
    try {
      if (kIsWeb) {
        // Web: trigger browser download by opening URL
        // Browser will handle the download
        final uri = Uri.parse(fileUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Mobile/Desktop: download to local storage
        await _downloadFileMobile(fileUrl, fileName);
      }
    } catch (e) {
      // Check if it's a Cloudinary untrusted account error
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('untrusted') ||
          errorMessage.contains('customer_untrusted')) {
        throw Exception(
          'Cloudinary account is untrusted. '
          'Please verify your email in Cloudinary Dashboard to enable downloads. '
          'You can still view files by clicking "Open" instead of "Download".',
        );
      }
      throw Exception('Failed to download file: ${e.toString()}');
    }
  }

  /// Download file on mobile/desktop
  Future<void> _downloadFileMobile(String fileUrl, String fileName) async {
    try {
      // Get download directory
      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${directory.path}/downloads');

      // Create downloads directory if it doesn't exist
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Download file
      final response = await http.get(Uri.parse(fileUrl));

      // Check for Cloudinary untrusted account error
      if (response.statusCode != 200) {
        // Try to parse error response
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map &&
              errorData.containsKey('error') &&
              errorData['error'] is Map) {
            final error = errorData['error'] as Map;
            final errorCode = error['code']?.toString() ?? '';
            final errorMessage = error['message']?.toString() ?? '';

            if (errorCode.contains('untrusted') ||
                errorMessage.toLowerCase().contains('untrusted')) {
              throw Exception(
                'Cloudinary account is untrusted. '
                'Please verify your email in Cloudinary Dashboard to enable downloads. '
                'You can still view files by clicking "Open" instead of "Download".',
              );
            }
          }
        } catch (e) {
          // If parsing fails, continue with generic error
        }

        throw Exception('Failed to download file: HTTP ${response.statusCode}');
      }

      // Save file
      final file = File('${downloadDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      // Try to open the download directory to show user where file is saved
      try {
        final dirUri = Uri.file(downloadDir.path);
        await launchUrl(dirUri);
      } catch (e) {
        // Ignore if can't open directory
      }
    } catch (e) {
      // Re-throw if it's already a formatted exception
      if (e.toString().contains('Cloudinary account is untrusted')) {
        rethrow;
      }
      throw Exception('Failed to download file: ${e.toString()}');
    }
  }

  /// Download file and open it (legacy method - kept for compatibility)
  /// NOTE: For Cloudinary untrusted accounts, use openFile() and downloadFile() separately
  @Deprecated('Use openFile() or downloadFile() instead')
  Future<void> downloadAndOpenFile({
    required String fileUrl,
    required String fileName,
  }) async {
    // Try to download first, if fails, try to open
    try {
      await downloadFile(fileUrl: fileUrl, fileName: fileName);
    } catch (e) {
      // If download fails (e.g., untrusted account), try to open instead
      if (e.toString().contains('untrusted')) {
        await openFile(fileUrl: fileUrl);
        throw Exception(
          'Cannot download file (Cloudinary untrusted account). '
          'File opened in browser instead. Please verify your Cloudinary account to enable downloads.',
        );
      }
      rethrow;
    }
  }

  /// Get file name from URL
  String getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      if (pathSegments.isNotEmpty) {
        // Get last segment (filename)
        final fileName = pathSegments.last;

        // Remove query parameters if any
        final cleanFileName = fileName.split('?').first;

        // If no extension, try to get from URL
        if (!cleanFileName.contains('.')) {
          // For Cloudinary URLs, try to extract from public_id or use default
          return 'file_${DateTime.now().millisecondsSinceEpoch}';
        }

        return cleanFileName;
      }

      return 'file_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      return 'file_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
