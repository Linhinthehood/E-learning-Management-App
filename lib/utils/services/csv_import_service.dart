import 'package:csv/csv.dart';

/// Represents the status of a CSV row during import preview
enum CsvRowStatus {
  willBeAdded,    // New record, will be imported
  alreadyExists,  // Duplicate detected, will be skipped
  invalidData,    // Validation error, cannot import
}

/// Represents a single row in the CSV import preview
class CsvImportRow<T> {
  final int rowNumber;
  final T? data;
  final CsvRowStatus status;
  final String? errorMessage;
  final Map<String, dynamic> rawData;

  CsvImportRow({
    required this.rowNumber,
    this.data,
    required this.status,
    this.errorMessage,
    required this.rawData,
  });
}

/// Result of the CSV import operation
class CsvImportResult<T> {
  final List<CsvImportRow<T>> rows;
  final int totalRows;
  final int validRows;
  final int duplicateRows;
  final int invalidRows;

  CsvImportResult({
    required this.rows,
    required this.totalRows,
    required this.validRows,
    required this.duplicateRows,
    required this.invalidRows,
  });
}

/// Final result after confirming and processing the import
class CsvImportFinalResult {
  final int addedCount;
  final int skippedCount;
  final int errorCount;
  final List<String> errors;

  CsvImportFinalResult({
    required this.addedCount,
    required this.skippedCount,
    required this.errorCount,
    required this.errors,
  });
}

/// Service for importing data from CSV files with preview and validation
class CsvImportService {
  /// Parse and validate CSV content for preview
  static Future<CsvImportResult<T>> parseAndValidate<T>({
    required String csvContent,
    required List<String> requiredColumns,
    required Future<T?> Function(Map<String, dynamic> row) validateRow,
    required Future<bool> Function(Map<String, dynamic> row) checkDuplicate,
  }) async {
    final List<CsvImportRow<T>> rows = [];
    int validCount = 0;
    int duplicateCount = 0;
    int invalidCount = 0;

    try {
      // Parse CSV
      final List<List<dynamic>> csvData = const CsvToListConverter(
        fieldDelimiter: ',',
        eol: '\n',
      ).convert(csvContent);

      if (csvData.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Get headers (first row)
      final List<String> headers = csvData.first.map((e) => e.toString().trim()).toList();

      // Validate required columns
      for (final column in requiredColumns) {
        if (!headers.contains(column)) {
          throw Exception('Required column "$column" not found in CSV file');
        }
      }

      // Process each data row (skip header)
      for (int i = 1; i < csvData.length; i++) {
        final rowData = csvData[i];
        final rowNumber = i + 1; // Row number in spreadsheet (1-indexed)

        // Skip empty rows
        if (rowData.isEmpty || rowData.every((cell) => cell.toString().trim().isEmpty)) {
          continue;
        }

        // Convert row to map
        final Map<String, dynamic> rowMap = {};
        for (int j = 0; j < headers.length && j < rowData.length; j++) {
          rowMap[headers[j]] = rowData[j]?.toString().trim() ?? '';
        }

        // Check if duplicate
        final isDuplicate = await checkDuplicate(rowMap);
        if (isDuplicate) {
          rows.add(CsvImportRow<T>(
            rowNumber: rowNumber,
            data: null,
            status: CsvRowStatus.alreadyExists,
            errorMessage: 'This record already exists in the system',
            rawData: rowMap,
          ));
          duplicateCount++;
          continue;
        }

        // Validate row data
        try {
          final T? validatedData = await validateRow(rowMap);
          if (validatedData != null) {
            rows.add(CsvImportRow<T>(
              rowNumber: rowNumber,
              data: validatedData,
              status: CsvRowStatus.willBeAdded,
              errorMessage: null,
              rawData: rowMap,
            ));
            validCount++;
          } else {
            rows.add(CsvImportRow<T>(
              rowNumber: rowNumber,
              data: null,
              status: CsvRowStatus.invalidData,
              errorMessage: 'Validation failed: Invalid data format',
              rawData: rowMap,
            ));
            invalidCount++;
          }
        } catch (e) {
          rows.add(CsvImportRow<T>(
            rowNumber: rowNumber,
            data: null,
            status: CsvRowStatus.invalidData,
            errorMessage: 'Validation error: ${e.toString()}',
            rawData: rowMap,
          ));
          invalidCount++;
        }
      }

      return CsvImportResult<T>(
        rows: rows,
        totalRows: rows.length,
        validRows: validCount,
        duplicateRows: duplicateCount,
        invalidRows: invalidCount,
      );
    } catch (e) {
      throw Exception('Failed to parse CSV file: ${e.toString()}');
    }
  }

  /// Process confirmed import (only import valid, non-duplicate rows)
  static Future<CsvImportFinalResult> processImport<T>({
    required List<CsvImportRow<T>> rows,
    required Future<void> Function(T data) importRow,
  }) async {
    int addedCount = 0;
    int skippedCount = 0;
    int errorCount = 0;
    final List<String> errors = [];

    for (final row in rows) {
      // Skip duplicates and invalid rows
      if (row.status == CsvRowStatus.alreadyExists) {
        skippedCount++;
        continue;
      }

      if (row.status == CsvRowStatus.invalidData) {
        errorCount++;
        errors.add('Row ${row.rowNumber}: ${row.errorMessage}');
        continue;
      }

      // Import valid rows
      if (row.status == CsvRowStatus.willBeAdded && row.data != null) {
        try {
          await importRow(row.data as T);
          addedCount++;
        } catch (e) {
          errorCount++;
          errors.add('Row ${row.rowNumber}: Failed to import - ${e.toString()}');
        }
      }
    }

    return CsvImportFinalResult(
      addedCount: addedCount,
      skippedCount: skippedCount,
      errorCount: errorCount,
      errors: errors,
    );
  }

  /// Generate sample CSV template
  static String generateTemplate({
    required List<String> columns,
    List<List<String>>? sampleData,
  }) {
    final List<List<String>> csvData = [columns];

    if (sampleData != null) {
      csvData.addAll(sampleData);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate string length
  static String? validateLength(String? value, String fieldName, {
    int? min,
    int? max,
  }) {
    if (value == null || value.trim().isEmpty) {
      return null; // Use validateRequired for required checks
    }

    final length = value.trim().length;

    if (min != null && length < min) {
      return '$fieldName must be at least $min characters';
    }

    if (max != null && length > max) {
      return '$fieldName must not exceed $max characters';
    }

    return null;
  }

  /// Validate numeric value
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return null; // Use validateRequired for required checks
    }

    if (int.tryParse(value.trim()) == null && double.tryParse(value.trim()) == null) {
      return '$fieldName must be a valid number';
    }

    return null;
  }
}
