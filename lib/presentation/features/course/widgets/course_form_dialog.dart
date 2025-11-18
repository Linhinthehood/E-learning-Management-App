import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../domain/entities/course_entity.dart';
import '../../../../domain/entities/semester_entity.dart';
import '../../../common/styles/colors.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/semester_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../../services/image_upload_service.dart';

/// Dialog for creating or editing a course
class CourseFormDialog extends ConsumerStatefulWidget {
  final CourseEntity? course;

  const CourseFormDialog({super.key, this.course});

  @override
  ConsumerState<CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends ConsumerState<CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _coverImageUrlController;
  SemesterEntity? _selectedSemester;
  int _selectedSessions = 10;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  double _imageUploadProgress = 0.0;
  final ImageUploadService _imageUploadService = ImageUploadService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.course?.name ?? '');
    _codeController = TextEditingController(text: widget.course?.code ?? '');
    _coverImageUrlController = TextEditingController(
      text: widget.course?.coverImageUrl ?? '',
    );
    _selectedSessions = widget.course?.sessions ?? 10;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _coverImageUrlController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load semesters and select the one from course if editing
    final semestersAsync = ref.read(semesterProvider);
    semestersAsync.whenData((semesters) {
      if (widget.course != null && semesters.isNotEmpty) {
        final semester = semesters.firstWhere(
          (s) => s.id == widget.course!.semesterId,
          orElse: () => semesters.first,
        );
        if (mounted) {
          setState(() {
            _selectedSemester = semester;
          });
        }
      } else if (semesters.isNotEmpty && _selectedSemester == null) {
        // Select active semester or first one
        final activeSemester = semesters.firstWhere(
          (s) => s.isActive,
          orElse: () => semesters.first,
        );
        if (mounted) {
          setState(() {
            _selectedSemester = activeSemester;
          });
        }
      }
    });
  }

  Future<void> _pickAndUploadImage() async {
    try {
      // Show source selection dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Select Image Source',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Pick image
      final XFile? imageFile = await _imageUploadService.pickImage(
        source: source,
      );

      if (imageFile == null) return;

      setState(() {
        _isUploadingImage = true;
        _imageUploadProgress = 0.0;
      });

      // Upload image
      final imageUrl = await _imageUploadService.uploadImage(
        imageFile: imageFile,
        folder: 'courses/cover',
        fileName: widget.course?.id != null
            ? 'course_${widget.course!.id}'
            : null,
        onProgress: (progress) {
          setState(() {
            _imageUploadProgress = progress;
          });
        },
      );

      // Update controller with uploaded URL
      setState(() {
        _coverImageUrlController.text = imageUrl;
        _isUploadingImage = false;
        _imageUploadProgress = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
        _imageUploadProgress = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a semester'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userAsync = ref.read(authProvider);
    final user = userAsync.value;
    if (user == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final course = CourseEntity(
        id: widget.course?.id ?? '',
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        semesterId: _selectedSemester!.id,
        instructorId: user.uid,
        coverImageUrl: _coverImageUrlController.text.trim().isEmpty
            ? null
            : _coverImageUrlController.text.trim(),
        sessions: _selectedSessions,
      );

      if (widget.course == null) {
        // Create new course
        await ref.read(courseProvider.notifier).createCourse(course);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Course created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        // Update existing course
        await ref.read(courseProvider.notifier).updateCourse(course);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Course updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final semestersAsync = ref.watch(semesterProvider);

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        widget.course == null ? 'Create Course' : 'Edit Course',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Course Name
                Text(
                  'Course Name *',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Lập trình ứng dụng di động đa nền tảng',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
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
                      return 'Course name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Course Code
                Text(
                  'Course Code *',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    hintText: 'e.g., 502071',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
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
                      return 'Course code is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Semester Selection
                Text(
                  'Semester *',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                semestersAsync.when(
                  data: (semesters) {
                    if (semesters.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'No semesters available. Please create a semester first.',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }
                    return DropdownButtonFormField<SemesterEntity>(
                      // ignore: deprecated_member_use
                      value: _selectedSemester,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.buttonPrimary,
                            width: 2,
                          ),
                        ),
                      ),
                      items: semesters.map((semester) {
                        return DropdownMenuItem<SemesterEntity>(
                          value: semester,
                          child: Text(semester.name),
                        );
                      }).toList(),
                      onChanged: (SemesterEntity? value) {
                        setState(() {
                          _selectedSemester = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a semester';
                        }
                        return null;
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      'Error loading semesters',
                      style: GoogleFonts.inter(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Sessions
                Text(
                  'Number of Sessions *',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(value: 10, label: Text('10 Sessions')),
                    ButtonSegment<int>(value: 15, label: Text('15 Sessions')),
                  ],
                  selected: {_selectedSessions},
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() {
                      _selectedSessions = newSelection.first;
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.buttonPrimary,
                    selectedForegroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                // Cover Image Section
                Text(
                  'Cover Image (Optional)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                // Image Preview
                if (_coverImageUrlController.text.isNotEmpty) ...[
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _coverImageUrlController.text,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.background,
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 48),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Upload Image Button
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isUploadingImage || _isLoading
                            ? null
                            : _pickAndUploadImage,
                        icon: _isUploadingImage
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: _imageUploadProgress > 0
                                      ? _imageUploadProgress
                                      : null,
                                ),
                              )
                            : const Icon(Icons.upload, size: 20),
                        label: Text(
                          _isUploadingImage ? 'Uploading...' : 'Upload Image',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(
                            color: AppColors.buttonPrimary,
                          ),
                        ),
                      ),
                    ),
                    if (_coverImageUrlController.text.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isUploadingImage || _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _coverImageUrlController.clear();
                                });
                              },
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                        tooltip: 'Remove image',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Or enter URL manually
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: AppColors.border, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: AppColors.border, thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Manual URL Input
                TextFormField(
                  controller: _coverImageUrlController,
                  decoration: InputDecoration(
                    hintText: 'Enter image URL manually',
                    prefixIcon: const Icon(Icons.link),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.buttonPrimary,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 32),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveCourse,
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
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.course == null ? 'Create' : 'Update',
                              style: GoogleFonts.inter(
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
      ),
    );
  }
}
