// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html; 
import 'package:flutter/material.dart';

/// Web implementation for file download helper
/// This file is only imported when running on web platform
class FileDownloadHelperImpl {
  static Future<void> downloadCsv({
    required String csvContent,
    required String filename,
    required BuildContext context,
  }) async {
    try {
      // Create blob with CSV content
      final blob = html.Blob([csvContent], 'text/csv;charset=utf-8');
      
      // Create object URL
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Create anchor element and trigger download
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      
      // Revoke object URL to free memory
      html.Url.revokeObjectUrl(url);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File downloaded successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      throw Exception('Failed to download file: ${e.toString()}');
    }
  }
}

