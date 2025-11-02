/// Material entity for course materials (resources)
class MaterialEntity {
  final String id;
  final String title;
  final String description;
  final List<MaterialFile> files; // Files, links, or embedded content
  final String courseId;
  final List<String> scopedGroupIds; // Empty = all groups
  final MaterialType type;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MaterialEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.files,
    required this.courseId,
    required this.scopedGroupIds,
    required this.type,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if material is for all groups
  bool get isForAllGroups => scopedGroupIds.isEmpty;

  /// Check if material has files
  bool get hasFiles => files.isNotEmpty;

  /// Check if material was updated
  bool get wasUpdated => updatedAt != null;
}

/// Type of material
enum MaterialType {
  document, // PDFs, Word docs, etc.
  video, // Video files or links
  audio, // Audio files or links
  link, // External links
  presentation, // PowerPoint, Slides, etc.
  spreadsheet, // Excel, Sheets, etc.
  code, // Code files
  image, // Images
  other, // Other types
}

/// Individual file or link in material
class MaterialFile {
  final String name;
  final String url; // URL or file path
  final MaterialFileType type;
  final int? fileSizeBytes; // File size if applicable

  const MaterialFile({
    required this.name,
    required this.url,
    required this.type,
    this.fileSizeBytes,
  });

  /// Get file size in MB
  double? get fileSizeMB {
    if (fileSizeBytes == null) return null;
    return fileSizeBytes! / (1024 * 1024);
  }

  /// Check if it's a file (not a link)
  bool get isFile => type != MaterialFileType.externalLink;

  /// Check if it's an external link
  bool get isExternalLink => type == MaterialFileType.externalLink;
}

/// Type of material file
enum MaterialFileType {
  pdf,
  word,
  powerpoint,
  excel,
  video,
  audio,
  image,
  code,
  externalLink,
  other,
}
