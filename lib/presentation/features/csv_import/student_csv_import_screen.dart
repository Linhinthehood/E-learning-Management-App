import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import '../../../utils/services/student_csv_import_service.dart';
import 'csv_import_preview_screen.dart';

/// Student CSV Import Screen
/// Allows instructors to bulk import students from CSV file
class StudentCsvImportScreen extends StatefulWidget {
  const StudentCsvImportScreen({super.key});

  @override
  State<StudentCsvImportScreen> createState() => _StudentCsvImportScreenState();
}

class _StudentCsvImportScreenState extends State<StudentCsvImportScreen> {
  final StudentCsvImportService _importService = StudentCsvImportService();
  bool _isLoading = false;
  String? _fileName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Students from CSV'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instructions card
                _buildInstructionsCard(),
                const SizedBox(height: 32),

                // CSV format info
                _buildCsvFormatCard(),
                const SizedBox(height: 32),

                // Download template button
                _buildTemplateButton(),
                const SizedBox(height: 32),

                // Upload area
                _buildUploadArea(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Text(
                  'How to Import Students',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Download the CSV template below\n'
              '2. Fill in student information\n'
              '3. Save the file as CSV format\n'
              '4. Upload the file using the upload area\n'
              '5. Review the preview and confirm import',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCsvFormatCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CSV Format Requirements',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildFormatItem(
              'email',
              'Required',
              'Must be a valid email address',
              isRequired: true,
            ),
            _buildFormatItem(
              'displayName',
              'Required',
              'Student\'s full name (2-100 characters)',
              isRequired: true,
            ),
            _buildFormatItem(
              'phone',
              'Optional',
              'Phone number (10-15 digits)',
              isRequired: false,
            ),
            _buildFormatItem(
              'studentId',
              'Optional',
              'Student ID (5-20 characters)',
              isRequired: false,
            ),
            _buildFormatItem(
              'password',
              'Optional',
              'If not provided, password will be auto-generated',
              isRequired: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatItem(
    String column,
    String requirement,
    String description, {
    required bool isRequired,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isRequired ? Colors.red[50] : Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isRequired ? Colors.red : Colors.grey,
              ),
            ),
            child: Text(
              requirement,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isRequired ? Colors.red[900] : Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  column,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateButton() {
    return OutlinedButton.icon(
      onPressed: _downloadTemplate,
      icon: const Icon(Icons.download),
      label: const Text('Download CSV Template'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: Colors.black),
        foregroundColor: Colors.black,
      ),
    );
  }

  Widget _buildUploadArea() {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _isLoading ? null : _pickAndUploadFile,
        child: Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey[300]!,
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
              const SizedBox(height: 16),
              Text(
                _fileName ?? 'Click to upload CSV file',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Supported format: .csv',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    try {
      final template = StudentCsvImportService.generateTemplate();

      // In web, this will trigger a download
      // In mobile/desktop, this will open a share dialog
      await _saveFile(template, 'student_import_template.csv');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download template: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      // Pick CSV file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;

      if (file.bytes == null) {
        throw Exception('Failed to read file data');
      }

      setState(() {
        _isLoading = true;
        _fileName = file.name;
      });

      // Convert bytes to string
      final csvContent = utf8.decode(file.bytes!);

      // Parse and validate
      final importResult = await _importService.parseAndValidate(csvContent);

      setState(() {
        _isLoading = false;
      });

      // Navigate to preview screen
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CsvImportPreviewScreen<StudentImportData>(
              title: 'Students',
              importResult: importResult,
              onConfirm: _importService.processImport,
              displayColumns: const [
                'email',
                'displayName',
                'phone',
                'studentId',
              ],
              extractDisplayData: (data) => {
                'email': data.email,
                'displayName': data.displayName,
                'phone': data.phone ?? '-',
                'studentId': data.studentId ?? '-',
              },
            ),
          ),
        );

        // Refresh after import
        setState(() {
          _fileName = null;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _saveFile(String content, String fileName) async {
    // Let user choose where to save the file
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save CSV Template',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (path == null) {
      // User cancelled the save dialog
      throw Exception('Save cancelled');
    }

    // Write the template to the selected file
    final file = File(path);
    await file.writeAsString(content);
  }
}
