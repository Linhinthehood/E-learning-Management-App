import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';
import '../../../utils/services/course_csv_import_service.dart';
import '../../providers/semester_provider.dart';
import 'csv_import_preview_screen.dart';
import '../../providers/auth_provider.dart';

/// Course CSV Import Screen
/// Allows instructors to bulk import courses from CSV file
class CourseCsvImportScreen extends ConsumerStatefulWidget {
  const CourseCsvImportScreen({super.key});

  @override
  ConsumerState<CourseCsvImportScreen> createState() =>
      _CourseCsvImportScreenState();
}

class _CourseCsvImportScreenState extends ConsumerState<CourseCsvImportScreen> {
  final CourseCsvImportService _importService = CourseCsvImportService();
  bool _isLoading = false;
  String? _fileName;
  String? _selectedSemesterId;
  String? _selectedInstructorId;

  @override
  void initState() {
    super.initState();
    // Get current user as default instructor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userAsync = ref.read(authProvider);
        userAsync.whenData((user) {
          if (user != null && mounted) {
            setState(() {
              _selectedInstructorId = user.uid;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final semestersAsync = ref.watch(semesterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Courses from CSV'),
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

                // Default values
                _buildDefaultValuesCard(semestersAsync),
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
                  'How to Import Courses',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Select default semester and instructor (optional)\n'
              '2. Download the CSV template below\n'
              '3. Fill in course information\n'
              '4. Save the file as CSV format\n'
              '5. Upload the file using the upload area\n'
              '6. Review the preview and confirm import',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultValuesCard(AsyncValue semestersAsync) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Default Values (Optional)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'These values will be used if not specified in CSV',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Semester dropdown
            semestersAsync.when(
              data: (semesters) {
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Default Semester',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _selectedSemesterId,
                  items: semesters.map((semester) {
                    return DropdownMenuItem(
                      value: semester.id,
                      child: Text(semester.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSemesterId = value;
                    });
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading semesters'),
            ),
            const SizedBox(height: 16),

            // Instructor ID field (read-only for now)
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Default Instructor ID',
                border: OutlineInputBorder(),
                enabled: false,
              ),
              initialValue: _selectedInstructorId ?? 'Current user',
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFormatItem(
              'code',
              'Required',
              'Course code (3-20 characters)',
              isRequired: true,
            ),
            _buildFormatItem(
              'name',
              'Required',
              'Course name (3-200 characters)',
              isRequired: true,
            ),
            _buildFormatItem(
              'semesterId',
              'Required*',
              'Semester ID (use default if not provided)',
              isRequired: true,
            ),
            _buildFormatItem(
              'instructorId',
              'Required*',
              'Instructor ID (use default if not provided)',
              isRequired: true,
            ),
            _buildFormatItem(
              'description',
              'Optional',
              'Course description',
              isRequired: false,
            ),
            _buildFormatItem(
              'sessions',
              'Optional',
              'Number of sessions (1-20, default: 15)',
              isRequired: false,
            ),
            _buildFormatItem(
              'coverImageUrl',
              'Optional',
              'URL to cover image',
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
              border: Border.all(color: isRequired ? Colors.red : Colors.grey),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Supported format: .csv',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    try {
      final template = CourseCsvImportService.generateTemplate();

      // Let user choose where to save the file
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV Template',
        fileName: 'courses_template.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (path == null) {
        // User cancelled the save dialog
        return;
      }

      // Write the template to the selected file
      final file = File(path);
      await file.writeAsString(template);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template downloaded successfully!'),
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

      final csvContent = utf8.decode(file.bytes!);

      final importResult = await _importService.parseAndValidate(
        csvContent,
        defaultSemesterId: _selectedSemesterId,
        defaultInstructorId: _selectedInstructorId,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CsvImportPreviewScreen<CourseImportData>(
              title: 'Courses',
              importResult: importResult,
              onConfirm: _importService.processImport,
              displayColumns: const ['code', 'name', 'sessions'],
              extractDisplayData: (data) => {
                'code': data.code,
                'name': data.name,
                'sessions': data.sessions.toString(),
              },
            ),
          ),
        );

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
}
