import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../domain/entities/course_entity.dart';
import '../../../../domain/entities/forum_topic_entity.dart';
import '../../../common/styles/colors.dart';
import '../../../providers/forum_topic_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../../services/file_upload_service.dart';

/// Topic Form Dialog - for creating or editing forum topics
class TopicFormDialog extends ConsumerStatefulWidget {
  final CourseEntity course;
  final ForumTopicEntity? topic; // null for create, non-null for edit

  const TopicFormDialog({super.key, required this.course, this.topic});

  @override
  ConsumerState<TopicFormDialog> createState() => _TopicFormDialogState();
}

class _TopicFormDialogState extends ConsumerState<TopicFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<String> _attachments = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  final FileUploadService _fileUploadService = FileUploadService();

  @override
  void initState() {
    super.initState();
    if (widget.topic != null) {
      _titleController.text = widget.topic!.title;
      _contentController.text = widget.topic!.content;
      _attachments = List.from(widget.topic!.attachments);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      // Pick files
      final files = await _fileUploadService.pickFiles(allowMultiple: true);

      if (files == null || files.isEmpty) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Upload files to Cloudinary
      final uploadedUrls = await _fileUploadService.uploadMultipleFiles(
        files: files,
        path: 'forum_attachments',
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

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = ref.read(authProvider).value;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to create a topic'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final topic = ForumTopicEntity(
        id: widget.topic?.id ?? '',
        courseId: widget.course.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        authorId: user.uid,
        attachments: _attachments,
        createdAt: widget.topic?.createdAt ?? DateTime.now(),
        replyCount: widget.topic?.replyCount ?? 0,
      );

      if (widget.topic == null) {
        // Create new topic
        await ref.read(forumTopicProvider.notifier).createTopic(topic);
      } else {
        // Update existing topic
        await ref.read(forumTopicProvider.notifier).updateTopic(topic);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.topic == null ? 'New Topic' : 'Edit Topic',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          labelStyle: GoogleFonts.inter(fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                        style: GoogleFonts.inter(fontSize: 14),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Content field
                      TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          labelText: 'Content',
                          labelStyle: GoogleFonts.inter(fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                        style: GoogleFonts.inter(fontSize: 14),
                        maxLines: 8,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter content';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Attachments
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Attachments',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _isUploading ? null : _pickFiles,
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.attach_file, size: 20),
                            label: Text(
                              'Add Files',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      // Upload progress
                      if (_isUploading) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.buttonPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (_attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _attachments.asMap().entries.map((entry) {
                            final index = entry.key;
                            final attachment = entry.value;
                            return Chip(
                              label: Text(
                                attachment.split('/').last,
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                              avatar: const Icon(Icons.attach_file, size: 16),
                              onDeleted: () => _removeAttachment(index),
                              backgroundColor: AppColors.background,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      widget.topic == null ? 'Create' : 'Update',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
