import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';
import '../../../utils/services/group_csv_import_service.dart';
import '../../providers/course_provider.dart';
import '../../providers/semester_provider.dart';
import 'csv_import_preview_screen.dart';

/// Group CSV Import Screen
/// Allows instructors to bulk import groups from CSV file
class GroupCsvImportScreen extends ConsumerStatefulWidget {
  const GroupCsvImportScreen({super.key});

  @override
  ConsumerState<GroupCsvImportScreen> createState() =>
      _GroupCsvImportScreenState();
}

class _GroupCsvImportScreenState extends ConsumerState<GroupCsvImportScreen> {
  final GroupCsvImportService _importService = GroupCsvImportService();
  bool _isLoading = false;
  String? _fileName;
  String? _selectedCourseId;
  String? _selectedSemesterId;

  @override
  Widget build(BuildContext context) {
    final semestersAsync = ref.watch(semesterProvider);
    final coursesAsync = ref.watch(courseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Groups from CSV'),
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
                _buildDefaultValuesCard(semestersAsync, coursesAsync),
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
                  'How to Import Groups',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Select default course and semester (optional)\n'
              '2. Download the CSV template below\n'
              '3. Fill in group information\n'
              '4. Optionally add student emails (comma-separated)\n'
              '5. Save the file as CSV format\n'
              '6. Upload the file using the upload area\n'
              '7. Review the preview and confirm import',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultValuesCard(
    AsyncValue semestersAsync,
    AsyncValue coursesAsync,
  ) {
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

            // Course dropdown
            coursesAsync.when(
              data: (courses) {
                // Filter courses by selected semester if any
                final filteredCourses = _selectedSemesterId != null
                    ? courses
                          .where((c) => c.semesterId == _selectedSemesterId)
                          .toList()
                    : courses;

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Default Course',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _selectedCourseId,
                  items: filteredCourses.map((course) {
                    return DropdownMenuItem(
                      value: course.id,
                      child: Text('${course.code} - ${course.name}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCourseId = value;
                    });
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading courses'),
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
              'name',
              'Required',
              'Group name (2-100 characters)',
              isRequired: true,
            ),
            _buildFormatItem(
              'courseId',
              'Required*',
              'Course ID (use default if not provided)',
              isRequired: true,
            ),
            _buildFormatItem(
              'semesterId',
              'Optional',
              'Semester ID (will be fetched from course if not provided)',
              isRequired: false,
            ),
            _buildFormatItem(
              'studentEmails',
              'Optional',
              'Comma-separated student emails to add to group',
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
      final template = GroupCsvImportService.generateTemplate();

      // Let user choose where to save the file
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV Template',
        fileName: 'groups_template.csv',
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
        defaultCourseId: _selectedCourseId,
        defaultSemesterId: _selectedSemesterId,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CsvImportPreviewScreen<GroupImportData>(
              title: 'Groups',
              importResult: importResult,
              onConfirm: _importService.processImport,
              displayColumns: const ['name', 'courseId'],
              extractDisplayData: (data) => {
                'name': data.name,
                'courseId': data.courseId,
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
