import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';
import '../../../../domain/entities/course_entity.dart';
import '../../../../domain/entities/material_entity.dart';
import '../../../providers/view_tracking_provider.dart';
import '../../../../services/file_download_service.dart';

/// Material Detail Screen for Students - View material details and files
class MaterialDetailScreen extends ConsumerStatefulWidget {
  final CourseEntity course;
  final MaterialEntity material;

  const MaterialDetailScreen({
    super.key,
    required this.course,
    required this.material,
  });

  @override
  ConsumerState<MaterialDetailScreen> createState() =>
      _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends ConsumerState<MaterialDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.material.title,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Material info
            Card(
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
                    Row(
                      children: [
                        Text(
                          _getMaterialTypeIcon(widget.material.type),
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.material.title,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                        _getMaterialTypeLabel(widget.material.type),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.material.description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.insert_drive_file,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.material.files.length} file(s)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Created: ${_formatDate(widget.material.createdAt)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (!widget.material.isForAllGroups) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.group,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
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
            ),

            // Files section
            if (widget.material.files.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Files (${widget.material.files.length})',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.material.files.map((file) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: AppColors.cardBackground,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          file.isExternalLink ? Icons.link : Icons.attach_file,
                          size: 24,
                          color: AppColors.buttonPrimary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.name,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new, size: 20),
                          onPressed: () => _openFile(context, file.url),
                          tooltip: 'Open file',
                        ),
                        IconButton(
                          icon: const Icon(Icons.download, size: 20),
                          onPressed: () => _downloadFile(
                            context,
                            ref,
                            widget.material.id,
                            file.url,
                            file.name,
                          ),
                          tooltip: 'Download file',
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  String _getMaterialTypeIcon(MaterialType type) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
