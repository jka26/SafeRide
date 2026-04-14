import '../api/api_client.dart';
import '../models/csv_student_model.dart';

class CsvPreviewResult {
  CsvPreviewResult({
    required this.totalRows,
    required this.previewCount,
    required this.rows,
  });

  final int totalRows;
  final int previewCount;
  final List<CsvStudentModel> rows;
}

class CsvCommitResult {
  CsvCommitResult({required this.inserted, required this.skipped});

  final int inserted;
  /// Rows not inserted, usually because `studentCode` already exists (`skipDuplicates`).
  final int skipped;
}

class CsvImportService {
  CsvImportService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<CsvPreviewResult> preview(String csvText) async {
    final response = await _apiClient.post(
      '/csv-import/students/preview',
      body: {
        'csvText': csvText,
        'previewLimit': 200,
      },
    ) as Map<String, dynamic>;

    final rows = (response['rows'] ?? []) as List<dynamic>;
    return CsvPreviewResult(
      totalRows: (response['totalRows'] as num?)?.toInt() ?? rows.length,
      previewCount: (response['previewCount'] as num?)?.toInt() ?? rows.length,
      rows: rows
          .map((item) => CsvStudentModel.fromBackendRow(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<CsvCommitResult> commit(String csvText) async {
    final response = await _apiClient.post(
      '/csv-import/students/commit',
      body: {'csvText': csvText},
    ) as Map<String, dynamic>;

    return CsvCommitResult(
      inserted: (response['inserted'] as num?)?.toInt() ?? 0,
      skipped: (response['skipped'] as num?)?.toInt() ?? 0,
    );
  }
}
