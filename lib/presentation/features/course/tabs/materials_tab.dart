import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';
import '../../../../domain/entities/course_entity.dart';
import '../../../../domain/entities/material_entity.dart';
import '../../../providers/material_provider.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/material_form_dialog.dart';

/// Materials tab - displays and manages materials
class MaterialsTab extends ConsumerStatefulWidget {
  final CourseEntity course;

  const MaterialsTab({super.key, required this.course});

  @override
  ConsumerState<MaterialsTab> createState() => _MaterialsTabState();
}

class _MaterialsTabState extends ConsumerState<MaterialsTab> {
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
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(materialProvider);

    return materialsAsync.when(
      data: (materials) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Materials',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showMaterialDialog(context, ref, null),
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(
                      'Add Material',
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
            Expanded(
              child: materials.isEmpty
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
                            'No materials yet',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: materials.length,
                      itemBuilder: (context, index) {
                        final material = materials[index];
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
                  return Chip(
                    avatar: Icon(
                      file.isExternalLink
                          ? Icons.link
                          : Icons.insert_drive_file,
                      size: 16,
                    ),
                    label: Text(
                      file.name,
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                    backgroundColor: AppColors.background,
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
}
