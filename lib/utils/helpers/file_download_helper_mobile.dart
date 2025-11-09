import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Mobile implementation for file download helper
class FileDownloadHelperImpl {
  static Future<void> downloadCsv({
    required String csvContent,
    required String filename,
    required BuildContext context,
  }) async {
    try {
      // Get downloads directory
      Directory? directory;
      
      if (Platform.isAndroid) {
        // Android: Try to use external storage downloads directory
        try {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            // Fallback to app documents directory
            directory = await getApplicationDocumentsDirectory();
          }
        } catch (e) {
          // Fallback to app documents directory if external storage is not accessible
          directory = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        // iOS: Use app documents directory (iOS doesn't allow direct access to Downloads)
        directory = await getApplicationDocumentsDirectory();
      } else {
        // Desktop: Use downloads directory
        final homePath = Platform.environment['HOME'] ?? 
                        Platform.environment['USERPROFILE'] ?? 
                        '';
        if (homePath.isNotEmpty) {
          directory = Directory('$homePath/Downloads');
          if (!await directory.exists()) {
            directory = await getApplicationDocumentsDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
      }

      // Ensure directory exists
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Create file
      final file = File('${directory.path}/$filename');
      await file.writeAsString(csvContent);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved to: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      throw Exception('Failed to save file: ${e.toString()}');
    }
  }
}

