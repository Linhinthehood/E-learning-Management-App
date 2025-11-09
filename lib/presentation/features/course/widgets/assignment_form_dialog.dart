import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../domain/entities/assignment_entity.dart';
import '../../../../domain/entities/course_entity.dart';
import '../../../../domain/entities/notification_entity.dart';
import '../../../common/styles/colors.dart';
import '../../../providers/assignment_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../../services/file_upload_service.dart';

/// Dialog for creating or editing an assignment
class AssignmentFormDialog extends ConsumerStatefulWidget {
  final CourseEntity course;
  final AssignmentEntity? assignment;

  const AssignmentFormDialog({
    super.key,
    required this.course,
    this.assignment,
  });

  @override
  ConsumerState<AssignmentFormDialog> createState() =>
      _AssignmentFormDialogState();
}

class _AssignmentFormDialogState extends ConsumerState<AssignmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _fileFormatsController;
  DateTime? _startDate;
  DateTime? _deadline;
  DateTime? _lateDeadline;
  int _maxAttempts = 1;
  int _maxFileSizeMB = 10;
  final List<String> _selectedGroupIds = [];
  bool _isForAllGroups = true;
  bool _allowsLateSubmission = false;
  bool _isLoading = false;
  final List<String> _allowedFileFormats = [];
  final List<String> _attachments = [];
  late TextEditingController _attachmentController;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  final FileUploadService _fileUploadService = FileUploadService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.assignment?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.assignment?.description ?? '',
    );
    _fileFormatsController = TextEditingController();
    _startDate = widget.assignment?.startDate ?? DateTime.now();
    _deadline =
        widget.assignment?.deadline ??
        DateTime.now().add(const Duration(days: 7));
    _lateDeadline = widget.assignment?.lateDeadline;
    _maxAttempts = widget.assignment?.maxAttempts ?? 1;
    _maxFileSizeMB = widget.assignment?.maxFileSizeMB ?? 10;
    _selectedGroupIds.addAll(widget.assignment?.scopedGroupIds ?? []);
    _isForAllGroups = widget.assignment?.isForAllGroups ?? true;
    _allowsLateSubmission = widget.assignment?.allowsLateSubmission ?? false;
    _allowedFileFormats.addAll(
      widget.assignment?.allowedFileFormats ?? ['pdf'],
    );
    _attachmentController = TextEditingController();
    _attachments.addAll(widget.assignment?.attachments ?? []);

    // Load groups when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(groupProvider.notifier).loadGroups(widget.course.id);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fileFormatsController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }

  void _addAttachment() {
    final url = _attachmentController.text.trim();
    if (url.isNotEmpty && !_attachments.contains(url)) {
      setState(() {
        _attachments.add(url);
        _attachmentController.clear();
      });
    }
  }

  Future<void> _pickAndUploadFiles() async {
    try {
      // Pick files
      final files = await _fileUploadService.pickFiles(allowMultiple: true);

      if (files == null || files.isEmpty) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Upload files
      final uploadedUrls = await _fileUploadService.uploadMultipleFiles(
        files: files,
        path: 'courses/${widget.course.id}/assignments',
        onProgress: (current, total) {
          setState(() {
            _uploadProgress = current / total;
          });
        },
      );

      // Add uploaded URLs to attachments
      setState(() {
        _attachments.addAll(uploadedUrls);
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${files.length} file(s) uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload files: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeAttachment(String url) {
    setState(() {
      _attachments.remove(url);
    });
  }

  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start date and deadline'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_deadline!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deadline must be after start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_allowsLateSubmission && _lateDeadline != null) {
      if (_lateDeadline!.isBefore(_deadline!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Late deadline must be after deadline'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final assignment = AssignmentEntity(
        id: widget.assignment?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        courseId: widget.course.id,
        scopedGroupIds: _isForAllGroups ? [] : _selectedGroupIds,
        startDate: _startDate!,
        deadline: _deadline!,
        lateDeadline: _allowsLateSubmission ? _lateDeadline : null,
        maxAttempts: _maxAttempts,
        allowedFileFormats: _allowedFileFormats,
        maxFileSizeMB: _maxFileSizeMB,
        attachments: _attachments,
        createdAt: widget.assignment?.createdAt ?? DateTime.now(),
      );

      if (widget.assignment == null) {
        // Create new assignment
        final createdAssignment = await ref
            .read(assignmentProvider.notifier)
            .createAssignment(assignment);
        
        // Send notification to students
        try {
          final linkTo = 'assignment/${widget.course.id}/${createdAssignment.id}';
          
          if (createdAssignment.isForAllGroups) {
            // Send to all students in course
            await ref.read(notificationProvider.notifier).sendToAllStudentsInCourse(
              widget.course.id,
              'New Assignment: ${createdAssignment.title}',
              'A new assignment "${createdAssignment.title}" has been posted. Deadline: ${_formatDate(createdAssignment.deadline)}',
              linkTo,
              NotificationEntity.typeAssignment,
            );
          } else {
            // Send to specific groups
            await ref.read(notificationProvider.notifier).sendToGroupStudents(
              createdAssignment.scopedGroupIds,
              'New Assignment: ${createdAssignment.title}',
              'A new assignment "${createdAssignment.title}" has been posted. Deadline: ${_formatDate(createdAssignment.deadline)}',
              linkTo,
              NotificationEntity.typeAssignment,
            );
          }
        } catch (e) {
          // Log error but don't fail the assignment creation
          debugPrint('Error sending notification: $e');
        }
      } else {
        await ref
            .read(assignmentProvider.notifier)
            .updateAssignment(assignment);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _selectStartDate() async {
    if (!mounted) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted || picked == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDate ?? DateTime.now()),
    );
    if (!mounted || time == null) return;
    setState(() {
      _startDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _selectDeadline() async {
    if (!mounted) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted || picked == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? DateTime.now()),
    );
    if (!mounted || time == null) return;
    setState(() {
      _deadline = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _selectLateDeadline() async {
    if (!mounted) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _lateDeadline ?? _deadline ?? DateTime.now(),
      firstDate: _deadline ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted || picked == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _lateDeadline ?? _deadline ?? DateTime.now(),
      ),
    );
    if (!mounted || time == null) return;
    setState(() {
      _lateDeadline = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _addFileFormat() {
    final format = _fileFormatsController.text.trim().toLowerCase();
    if (format.isNotEmpty && !_allowedFileFormats.contains(format)) {
      setState(() {
        _allowedFileFormats.add(format);
        _fileFormatsController.clear();
      });
    }
  }

  void _removeFileFormat(String format) {
    setState(() {
      _allowedFileFormats.remove(format);
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupProvider);

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 900),
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.assignment == null
                        ? 'Create Assignment'
                        : 'Edit Assignment',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form fields
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Title *',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.buttonPrimary,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text(
                        'Description *',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.buttonPrimary,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Date and Time Selection
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Date *',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _selectStartDate,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _startDate != null
                                              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} ${_startDate!.hour}:${_startDate!.minute.toString().padLeft(2, '0')}'
                                              : 'Select start date',
                                          style: GoogleFonts.inter(),
                                        ),
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Deadline *',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _selectDeadline,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _deadline != null
                                              ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year} ${_deadline!.hour}:${_deadline!.minute.toString().padLeft(2, '0')}'
                                              : 'Select deadline',
                                          style: GoogleFonts.inter(),
                                        ),
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Late Submission
                      CheckboxListTile(
                        title: const Text('Allow Late Submissions'),
                        value: _allowsLateSubmission,
                        onChanged: (value) {
                          setState(() {
                            _allowsLateSubmission = value ?? false;
                            if (!_allowsLateSubmission) {
                              _lateDeadline = null;
                            }
                          });
                        },
                        activeColor: AppColors.buttonPrimary,
                      ),
                      if (_allowsLateSubmission) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Late Deadline',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectLateDeadline,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _lateDeadline != null
                                      ? '${_lateDeadline!.day}/${_lateDeadline!.month}/${_lateDeadline!.year} ${_lateDeadline!.hour}:${_lateDeadline!.minute.toString().padLeft(2, '0')}'
                                      : 'Select late deadline',
                                  style: GoogleFonts.inter(),
                                ),
                                const Icon(Icons.calendar_today, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Max Attempts
                      Text(
                        'Max Attempts *',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              initialValue: _maxAttempts.toString(),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                hintText: '0 = unlimited',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _maxAttempts = int.tryParse(value) ?? 1;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter max attempts';
                                }
                                final attempts = int.tryParse(value);
                                if (attempts == null || attempts < 0) {
                                  return 'Must be 0 or greater';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _maxAttempts = 0; // Unlimited
                              });
                            },
                            child: const Text('Unlimited (0)'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // File Size Limit
                      Text(
                        'Max File Size (MB) *',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        initialValue: _maxFileSizeMB.toString(),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _maxFileSizeMB = int.tryParse(value) ?? 10;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter max file size';
                          }
                          final size = int.tryParse(value);
                          if (size == null || size <= 0) {
                            return 'Must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Allowed File Formats
                      Text(
                        'Allowed File Formats',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _fileFormatsController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.background,
                                hintText: 'Enter file format (e.g., pdf)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addFileFormat,
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.buttonPrimary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (_allowedFileFormats.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allowedFileFormats.map((format) {
                            return Chip(
                              label: Text(
                                format.toUpperCase(),
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                              onDeleted: () => _removeFileFormat(format),
                              deleteIcon: const Icon(Icons.close, size: 16),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Attachments
                      Text(
                        'Attachments (Instructions/Materials)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Upload file button
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickAndUploadFiles,
                        icon: const Icon(Icons.upload_file, size: 20),
                        label: Text(
                          _isUploading
                              ? 'Uploading...'
                              : 'Browse & Upload Files',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      // Upload progress
                      if (_isUploading) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.buttonPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Or paste URL
                      Text(
                        'Or paste URL',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _attachmentController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.background,
                                hintText: 'Enter attachment URL',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addAttachment,
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.buttonPrimary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (_attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _attachments.map((attachment) {
                            return Chip(
                              label: Text(
                                attachment.split('/').last,
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                              onDeleted: () => _removeAttachment(attachment),
                              deleteIcon: const Icon(Icons.close, size: 16),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Scope selector
                      Text(
                        'Scope *',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      groupsAsync.when(
                        data: (groups) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CheckboxListTile(
                                title: const Text('All Groups'),
                                value: _isForAllGroups,
                                onChanged: (value) {
                                  setState(() {
                                    _isForAllGroups = value ?? true;
                                    if (_isForAllGroups) {
                                      _selectedGroupIds.clear();
                                    }
                                  });
                                },
                                activeColor: AppColors.buttonPrimary,
                              ),
                              if (!_isForAllGroups && groups.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: groups.length,
                                    itemBuilder: (context, index) {
                                      final group = groups[index];
                                      final isSelected = _selectedGroupIds
                                          .contains(group.id);
                                      return CheckboxListTile(
                                        title: Text(group.name),
                                        value: isSelected,
                                        onChanged: (value) {
                                          setState(() {
                                            if (value ?? false) {
                                              _selectedGroupIds.add(group.id);
                                            } else {
                                              _selectedGroupIds.remove(
                                                group.id,
                                              );
                                            }
                                          });
                                        },
                                        activeColor: AppColors.buttonPrimary,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Text('Error loading groups'),
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: GoogleFonts.inter()),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveAssignment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            widget.assignment == null ? 'Create' : 'Update',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
