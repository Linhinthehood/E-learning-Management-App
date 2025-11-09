import 'package:flutter/material.dart';

/// Stub implementation for file download helper
/// This file is used as a fallback when neither web nor mobile imports are available
class FileDownloadHelperImpl {
  static Future<void> downloadCsv({
    required String csvContent,
    required String filename,
    required BuildContext context,
  }) async {
    throw UnsupportedError(
      'File download not supported on this platform',
    );
  }
}

