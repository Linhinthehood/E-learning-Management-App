import 'package:flutter/material.dart';
import '../../../utils/services/csv_import_service.dart';

/// Generic CSV Import Preview Screen
/// Shows preview of CSV data with validation status before confirming import
class CsvImportPreviewScreen<T> extends StatefulWidget {
  final String title;
  final CsvImportResult<T> importResult;
  final Future<CsvImportFinalResult> Function(List<CsvImportRow<T>>) onConfirm;
  final List<String> displayColumns;
  final Map<String, dynamic> Function(T data) extractDisplayData;

  const CsvImportPreviewScreen({
    super.key,
    required this.title,
    required this.importResult,
    required this.onConfirm,
    required this.displayColumns,
    required this.extractDisplayData,
  });

  @override
  State<CsvImportPreviewScreen<T>> createState() =>
      _CsvImportPreviewScreenState<T>();
}

class _CsvImportPreviewScreenState<T>
    extends State<CsvImportPreviewScreen<T>> {
  bool _isProcessing = false;
  CsvImportFinalResult? _finalResult;

  @override
  Widget build(BuildContext context) {
    if (_finalResult != null) {
      return _buildResultScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} - Import Preview'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Summary card
          _buildSummaryCard(),
          const Divider(height: 1),

          // Preview table
          Expanded(
            child: _buildPreviewTable(),
          ),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Import Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryItem(
                label: 'Total Rows',
                value: widget.importResult.totalRows.toString(),
                color: Colors.blue,
                icon: Icons.list_alt,
              ),
              const SizedBox(width: 24),
              _buildSummaryItem(
                label: 'Will Be Added',
                value: widget.importResult.validRows.toString(),
                color: Colors.green,
                icon: Icons.check_circle,
              ),
              const SizedBox(width: 24),
              _buildSummaryItem(
                label: 'Already Exist',
                value: widget.importResult.duplicateRows.toString(),
                color: Colors.orange,
                icon: Icons.warning,
              ),
              const SizedBox(width: 24),
              _buildSummaryItem(
                label: 'Invalid Data',
                value: widget.importResult.invalidRows.toString(),
                color: Colors.red,
                icon: Icons.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
          columns: [
            const DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            ...widget.displayColumns.map(
              (col) => DataColumn(
                label: Text(
                  col,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          rows: widget.importResult.rows.map((row) {
            return DataRow(
              color: MaterialStateProperty.all(_getRowColor(row.status)),
              cells: [
                DataCell(Text(row.rowNumber.toString())),
                DataCell(_buildStatusChip(row.status, row.errorMessage)),
                ...widget.displayColumns.map((col) {
                  final displayData = row.data != null
                      ? widget.extractDisplayData(row.data as T)
                      : row.rawData;
                  return DataCell(
                    Text(
                      displayData[col]?.toString() ?? row.rawData[col]?.toString() ?? '-',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getRowColor(CsvRowStatus status) {
    switch (status) {
      case CsvRowStatus.willBeAdded:
        return Colors.green[50]!;
      case CsvRowStatus.alreadyExists:
        return Colors.orange[50]!;
      case CsvRowStatus.invalidData:
        return Colors.red[50]!;
    }
  }

  Widget _buildStatusChip(CsvRowStatus status, String? errorMessage) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case CsvRowStatus.willBeAdded:
        color = Colors.green;
        label = 'Will be added';
        icon = Icons.check_circle;
        break;
      case CsvRowStatus.alreadyExists:
        color = Colors.orange;
        label = 'Already exists';
        icon = Icons.warning;
        break;
      case CsvRowStatus.invalidData:
        color = Colors.red;
        label = 'Invalid data';
        icon = Icons.error;
        break;
    }

    return Tooltip(
      message: errorMessage ?? label,
      child: Chip(
        avatar: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: color.withOpacity(0.1),
        side: BorderSide(color: color, width: 1),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isProcessing || widget.importResult.validRows == 0
                ? null
                : _confirmImport,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Confirm Import (${widget.importResult.validRows} records)',
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmImport() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await widget.onConfirm(widget.importResult.rows);

      setState(() {
        _finalResult = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildResultScreen() {
    final result = _finalResult!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} - Import Complete'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                result.errorCount > 0 ? Icons.warning : Icons.check_circle,
                size: 80,
                color: result.errorCount > 0 ? Colors.orange : Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                'Import Complete',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 32),
              _buildResultCard('Successfully Added', result.addedCount, Colors.green),
              const SizedBox(height: 16),
              _buildResultCard('Skipped (Duplicates)', result.skippedCount, Colors.orange),
              const SizedBox(height: 16),
              _buildResultCard('Errors', result.errorCount, Colors.red),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Error Details:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...result.errors.map(
                          (error) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $error',
                              style: TextStyle(color: Colors.red[800]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
