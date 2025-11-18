import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';
import '../../../../domain/entities/course_entity.dart';
import '../../../../domain/entities/material_entity.dart';
import '../../../providers/material_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/view_tracking_provider.dart';
import '../widgets/material_form_dialog.dart';
import '../../tracking/material_tracking_screen.dart';
import '../../../../services/file_download_service.dart';

/// Materials tab - displays and manages materials
class MaterialsTab extends ConsumerStatefulWidget {
  final CourseEntity course;
  final bool isStudent; // If true, hide create button

  const MaterialsTab({super.key, required this.course, this.isStudent = false});

  @override
  ConsumerState<MaterialsTab> createState() => _MaterialsTabState();
}

class _MaterialsTabState extends ConsumerState<MaterialsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'All';
  String _sortBy = 'Date (Newest First)';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(materialProvider.notifier).loadMaterials(widget.course.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MaterialEntity> _applyFiltersAndSort(List<MaterialEntity> materials) {
    var filtered = materials.where((material) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesSearch =
            material.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            material.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
        if (!matchesSearch) return false;
      }

      // Type filter (based on file type)
      if (_filterType != 'All') {
        final hasMatchingType = material.files.any((file) {
          final lowerUrl = file.url.toLowerCase();
          switch (_filterType) {
            case 'Documents':
              return lowerUrl.endsWith('.pdf') ||
                  lowerUrl.endsWith('.doc') ||
                  lowerUrl.endsWith('.docx') ||
                  lowerUrl.endsWith('.txt');
            case 'Videos':
              return lowerUrl.endsWith('.mp4') ||
                  lowerUrl.endsWith('.avi') ||
                  lowerUrl.endsWith('.mov') ||
                  lowerUrl.contains('youtube.com') ||
                  lowerUrl.contains('youtu.be');
            case 'Links':
              return file.isExternalLink ||
                  lowerUrl.startsWith('http://') ||
                  lowerUrl.startsWith('https://');
            default:
              return true;
          }
        });
        if (!hasMatchingType) return false;
      }

      return true;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'Date (Newest First)':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Date (Oldest First)':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Title (A-Z)':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Title (Z-A)':
        filtered.sort((a, b) => b.title.compareTo(a.title));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(materialProvider);

    return materialsAsync.when(
      data: (materials) {
        final filteredMaterials = _applyFiltersAndSort(materials);

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Materials',
                      style: GoogleFonts.inter(
                        fontSize: MediaQuery.of(context).size.width < 600
                            ? 18
                            : 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Only show Add button for instructors
                  if (!widget.isStudent)
                    ElevatedButton.icon(
                      onPressed: () => _showMaterialDialog(context, ref, null),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        MediaQuery.of(context).size.width < 600
                            ? 'Add'
                            : 'Add Material',
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
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search materials...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Filter and Sort
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    // ignore: deprecated_member_use
                    child: DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _filterType,
                      isDense: true,
                      decoration: InputDecoration(
                        labelText: MediaQuery.of(context).size.width < 600
                            ? 'Filter'
                            : 'Filter by Type',
                        prefixIcon: MediaQuery.of(context).size.width < 600
                            ? null
                            : const Icon(Icons.filter_list, size: 20),
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width < 600
                              ? 8
                              : 16,
                          vertical: MediaQuery.of(context).size.width < 600
                              ? 12
                              : 16,
                        ),
                      ),
                      items: ['All', 'Documents', 'Videos', 'Links'].map((
                        type,
                      ) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            type,
                            style: GoogleFonts.inter(
                              fontSize: MediaQuery.of(context).size.width < 600
                                  ? 12
                                  : 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _filterType = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    // ignore: deprecated_member_use
                    child: DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _sortBy,
                      isDense: true,
                      decoration: InputDecoration(
                        labelText: 'Sort',
                        prefixIcon: MediaQuery.of(context).size.width < 600
                            ? null
                            : const Icon(Icons.sort, size: 20),
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width < 600
                              ? 8
                              : 16,
                          vertical: MediaQuery.of(context).size.width < 600
                              ? 12
                              : 16,
                        ),
                      ),
                      selectedItemBuilder:
                          MediaQuery.of(context).size.width < 600
                          ? (BuildContext context) {
                              return [
                                'Date (Newest First)',
                                'Date (Oldest First)',
                                'Title (A-Z)',
                                'Title (Z-A)',
                              ].map((sortOption) {
                                // Show abbreviated text on small screens
                                String displayText;
                                switch (sortOption) {
                                  case 'Date (Newest First)':
                                    displayText = 'Date ↓';
                                    break;
                                  case 'Date (Oldest First)':
                                    displayText = 'Date ↑';
                                    break;
                                  default:
                                    displayText = sortOption;
                                }
                                return Text(
                                  displayText,
                                  style: GoogleFonts.inter(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                );
                              }).toList();
                            }
                          : null,
                      items:
                          [
                            'Date (Newest First)',
                            'Date (Oldest First)',
                            'Title (A-Z)',
                            'Title (Z-A)',
                          ].map((sortOption) {
                            return DropdownMenuItem(
                              value: sortOption,
                              child: Text(
                                sortOption,
                                style: GoogleFonts.inter(
                                  fontSize:
                                      MediaQuery.of(context).size.width < 600
                                      ? 12
                                      : 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _sortBy = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: filteredMaterials.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 64,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _filterType != 'All'
                                ? 'No materials match your filters'
                                : 'No materials yet',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty ||
                              _filterType != 'All') ...[
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _filterType = 'All';
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Clear filters',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filteredMaterials.length,
                      itemBuilder: (context, index) {
                        final material = filteredMaterials[index];
                        return _buildMaterialCard(context, ref, material);
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading materials'),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(materialProvider.notifier)
                    .loadMaterials(widget.course.id);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialCard(
    BuildContext context,
    WidgetRef ref,
    MaterialEntity material,
  ) {
    final userAsync = ref.read(authProvider);
    final isAuthor = userAsync.value?.uid == widget.course.instructorId;

    String getMaterialTypeIcon(MaterialType type) {
      switch (type) {
        case MaterialType.document:
          return '📄';
        case MaterialType.video:
          return '🎥';
        case MaterialType.audio:
          return '🎵';
        case MaterialType.link:
          return '🔗';
        case MaterialType.presentation:
          return '📊';
        case MaterialType.spreadsheet:
          return '📈';
        case MaterialType.code:
          return '💻';
        case MaterialType.image:
          return '🖼️';
        case MaterialType.other:
          return '📁';
      }
    }

    String getMaterialTypeLabel(MaterialType type) {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            getMaterialTypeIcon(material.type),
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              material.title,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              getMaterialTypeLabel(material.type),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.insert_drive_file,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${material.files.length} file(s)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isAuthor)
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                        onTap: () {
                          final navigatorContext = context;
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted && navigatorContext.mounted) {
                              _showMaterialDialog(
                                navigatorContext,
                                ref,
                                material,
                              );
                            }
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.analytics, size: 20),
                            SizedBox(width: 8),
                            Text('View Tracking'),
                          ],
                        ),
                        onTap: () {
                          final navigatorContext = context;
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted && navigatorContext.mounted) {
                              Navigator.of(navigatorContext).push(
                                MaterialPageRoute(
                                  builder: (context) => MaterialTrackingScreen(
                                    course: widget.course,
                                    material: material,
                                  ),
                                ),
                              );
                            }
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                        onTap: () {
                          final navigatorContext = context;
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted && navigatorContext.mounted) {
                              _deleteMaterial(navigatorContext, ref, material);
                            }
                          });
                        },
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              material.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (material.files.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: material.files.map((file) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          file.isExternalLink ? Icons.link : Icons.attach_file,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            file.name,
                            style: GoogleFonts.inter(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Open button
                        IconButton(
                          icon: const Icon(Icons.open_in_new, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          onPressed: () => _openFile(context, file.url),
                          tooltip: 'Open file',
                        ),
                        // Download button
                        IconButton(
                          icon: const Icon(Icons.download, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          onPressed: () => _downloadFile(
                            context,
                            ref,
                            material.id,
                            file.url,
                            file.name,
                          ),
                          tooltip: 'Download file',
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            if (!material.isForAllGroups) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.group, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Scoped to specific groups',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMaterialDialog(
    BuildContext context,
    WidgetRef ref,
    MaterialEntity? material,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          MaterialFormDialog(course: widget.course, material: material),
    ).then((success) {
      if (mounted && success == true) {
        ref.read(materialProvider.notifier).loadMaterials(widget.course.id);
      }
    });
  }

  void _deleteMaterial(
    BuildContext context,
    WidgetRef ref,
    MaterialEntity material,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Material',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${material.title}"? This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(materialProvider.notifier)
                    .deleteMaterial(material.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${material.title} deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(BuildContext context, String fileUrl) async {
    final downloadService = FileDownloadService();

    try {
      await downloadService.openFile(fileUrl: fileUrl);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadFile(
    BuildContext context,
    WidgetRef ref,
    String materialId,
    String fileUrl,
    String fileName,
  ) async {
    final downloadService = FileDownloadService();

    try {
      // Track download
      await ref
          .read(
            viewTrackingByContentProvider((
              contentId: materialId,
              contentType: 'material',
            )).notifier,
          )
          .trackDownload();

      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Downloading $fileName...'),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Download file
      await downloadService.downloadFile(fileUrl: fileUrl, fileName: fileName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final errorMessage = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage.contains('untrusted')
                  ? 'Cannot download: Cloudinary account needs verification. Use "Open" to view file.'
                  : 'Failed to download file: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
