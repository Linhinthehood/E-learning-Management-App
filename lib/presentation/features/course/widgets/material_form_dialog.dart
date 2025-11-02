import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../domain/entities/material_entity.dart';
import '../../../../domain/entities/course_entity.dart';
import '../../../common/styles/colors.dart';
import '../../../providers/material_provider.dart';
import '../../../providers/group_provider.dart';

/// Dialog for creating or editing a material
class MaterialFormDialog extends ConsumerStatefulWidget {
  final CourseEntity course;
  final MaterialEntity? material;

  const MaterialFormDialog({super.key, required this.course, this.material});

  @override
  ConsumerState<MaterialFormDialog> createState() => _MaterialFormDialogState();
}

class _MaterialFormDialogState extends ConsumerState<MaterialFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _fileNameController;
  late TextEditingController _fileUrlController;
  MaterialType _materialType = MaterialType.document;
  MaterialFileType _fileType = MaterialFileType.pdf;
  final List<MaterialFile> _files = [];
  final List<String> _selectedGroupIds = [];
  bool _isForAllGroups = true;
  bool _isLoading = false;
  bool _isExternalLink = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.material?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.material?.description ?? '',
    );
    _fileNameController = TextEditingController();
    _fileUrlController = TextEditingController();
    _materialType = widget.material?.type ?? MaterialType.document;
    _selectedGroupIds.addAll(widget.material?.scopedGroupIds ?? []);
    _isForAllGroups = widget.material?.isForAllGroups ?? true;
    _files.addAll(widget.material?.files ?? []);

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
    _fileNameController.dispose();
    _fileUrlController.dispose();
    super.dispose();
  }

  void _addFile() {
    final name = _fileNameController.text.trim();
    final url = _fileUrlController.text.trim();

    if (name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter file name and URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate URL format
    if (!_isValidUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _files.add(
        MaterialFile(
          name: name,
          url: url,
          type: _isExternalLink ? MaterialFileType.externalLink : _fileType,
        ),
      );
      _fileNameController.clear();
      _fileUrlController.clear();
    });
  }

  bool _isValidUrl(String url) {
    try {
      return Uri.parse(url).hasScheme;
    } catch (e) {
      return false;
    }
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
  }

  void _updateMaterialType(MaterialType type) {
    setState(() {
      _materialType = type;
      // Update file type based on material type
      switch (type) {
        case MaterialType.document:
          _fileType = MaterialFileType.pdf;
          break;
        case MaterialType.video:
          _fileType = MaterialFileType.video;
          break;
        case MaterialType.audio:
          _fileType = MaterialFileType.audio;
          break;
        case MaterialType.presentation:
          _fileType = MaterialFileType.powerpoint;
          break;
        case MaterialType.spreadsheet:
          _fileType = MaterialFileType.excel;
          break;
        case MaterialType.image:
          _fileType = MaterialFileType.image;
          break;
        case MaterialType.code:
          _fileType = MaterialFileType.code;
          break;
        case MaterialType.link:
          _isExternalLink = true;
          _fileType = MaterialFileType.externalLink;
          break;
        case MaterialType.other:
          _fileType = MaterialFileType.other;
          break;
      }
    });
  }

  Future<void> _saveMaterial() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one file or link'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final material = MaterialEntity(
        id: widget.material?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        files: _files,
        courseId: widget.course.id,
        scopedGroupIds: _isForAllGroups ? [] : _selectedGroupIds,
        type: _materialType,
        createdAt: widget.material?.createdAt ?? DateTime.now(),
        updatedAt: widget.material == null ? null : DateTime.now(),
      );

      if (widget.material == null) {
        await ref.read(materialProvider.notifier).createMaterial(material);
      } else {
        await ref.read(materialProvider.notifier).updateMaterial(material);
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

  String _getMaterialTypeLabel(MaterialType type) {
    switch (type) {
      case MaterialType.document:
        return 'Document';
      case MaterialType.video:
        return 'Video';
      case MaterialType.audio:
        return 'Audio';
      case MaterialType.link:
        return 'Link';
      case MaterialType.presentation:
        return 'Presentation';
      case MaterialType.spreadsheet:
        return 'Spreadsheet';
      case MaterialType.code:
        return 'Code';
      case MaterialType.image:
        return 'Image';
      case MaterialType.other:
        return 'Other';
    }
  }

  String _getFileTypeLabel(MaterialFileType type) {
    switch (type) {
      case MaterialFileType.pdf:
        return 'PDF';
      case MaterialFileType.word:
        return 'Word';
      case MaterialFileType.powerpoint:
        return 'PowerPoint';
      case MaterialFileType.excel:
        return 'Excel';
      case MaterialFileType.video:
        return 'Video';
      case MaterialFileType.audio:
        return 'Audio';
      case MaterialFileType.image:
        return 'Image';
      case MaterialFileType.code:
        return 'Code';
      case MaterialFileType.externalLink:
        return 'External Link';
      case MaterialFileType.other:
        return 'Other';
    }
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
                    widget.material == null
                        ? 'Create Material'
                        : 'Edit Material',
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

                      // Material Type
                      Text(
                        'Material Type *',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: MaterialType.values.map((type) {
                          final isSelected = _materialType == type;
                          return ChoiceChip(
                            label: Text(_getMaterialTypeLabel(type)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                _updateMaterialType(type);
                              }
                            },
                            selectedColor: AppColors.buttonPrimary,
                            labelStyle: GoogleFonts.inter(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Add File/Link Section
                      Text(
                        'Files / Links *',
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
                              controller: _fileNameController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.background,
                                hintText: 'File name',
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
                          Expanded(
                            child: TextFormField(
                              controller: _fileUrlController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.background,
                                hintText: 'URL',
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
                            onPressed: _addFile,
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.buttonPrimary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_files.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Added Files (${_files.length})',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...List.generate(_files.length, (index) {
                                final file = _files[index];
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    file.isExternalLink
                                        ? Icons.link
                                        : Icons.insert_drive_file,
                                    size: 20,
                                  ),
                                  title: Text(
                                    file.name,
                                    style: GoogleFonts.inter(fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    _getFileTypeLabel(file.type),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => _removeFile(index),
                                    color: Colors.red,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
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
                    onPressed: _isLoading ? null : _saveMaterial,
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
                            widget.material == null ? 'Create' : 'Update',
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
