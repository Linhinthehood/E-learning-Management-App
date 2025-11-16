import 'package:flutter/material.dart';

// Conditional imports for web and mobile
import 'file_download_helper_stub.dart'
    if (dart.library.html) 'file_download_helper_web.dart'
    if (dart.library.io) 'file_download_helper_mobile.dart';

/// File Download Helper for downloading files on web and mobile
class FileDownloadHelper {
  /// Download CSV file with given content and filename
  ///
  /// On web: Uses browser download
  /// On mobile: Saves to Downloads folder
  static Future<void> downloadCsv({
    required String csvContent,
    required String filename,
    required BuildContext context,
  }) async {
    try {
      await FileDownloadHelperImpl.downloadCsv(
        csvContent: csvContent,
        filename: filename,
        context: context,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
