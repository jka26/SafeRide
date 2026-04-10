import '../api/api_client.dart';
import '../models/csv_student_model.dart';

class CsvPreviewResult {
  CsvPreviewResult({
    required this.totalRows,
    required this.rows,
  });

  final int totalRows;
  final List<CsvStudentModel> rows;
}

class CsvImportService {
  CsvImportService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<CsvPreviewResult> preview(String csvText) async {
    final response = await _apiClient.post(
      '/csv-import/students/preview',
      body: {'csvText': csvText},
    ) as Map<String, dynamic>;

    final rows = (response['rows'] ?? []) as List<dynamic>;
    return CsvPreviewResult(
      totalRows: (response['totalRows'] as num?)?.toInt() ?? rows.length,
      rows: rows
          .map((item) => CsvStudentModel.fromBackendRow(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<int> commit(String csvText) async {
    final response = await _apiClient.post(
      '/csv-import/students/commit',
      body: {'csvText': csvText},
    ) as Map<String, dynamic>;

    return (response['inserted'] as num?)?.toInt() ?? 0;
  }
}
