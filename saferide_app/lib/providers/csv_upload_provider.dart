import 'package:flutter/foundation.dart';
import '../models/csv_student_model.dart';
import '../services/csv_import_service.dart';

enum UploadStatus { idle, picking, parsing, previewing, uploading, success, error }

class CsvUploadProvider extends ChangeNotifier {
  CsvUploadProvider({CsvImportService? csvImportService})
      : _csvImportService = csvImportService ?? CsvImportService();

  final CsvImportService _csvImportService;
  UploadStatus _status = UploadStatus.idle;
  List<CsvStudentModel> _students = [];
  String? _csvText;
  String? _fileName;
  String? _errorMessage;
  int _uploadedCount = 0;
  int _skippedCount = 0;
  int _totalRows = 0;
  int _previewCount = 0;

  // ── Getters ────────────────────────────────────────────────
  UploadStatus get status => _status;
  List<CsvStudentModel> get students => _students;
  List<CsvStudentModel> get validStudents =>
      _students.where((s) => !s.hasError).toList();
  List<CsvStudentModel> get invalidStudents =>
      _students.where((s) => s.hasError).toList();
  String? get fileName => _fileName;
  String? get errorMessage => _errorMessage;
  int get uploadedCount => _uploadedCount;
  int get skippedCount => _skippedCount;
  int get totalRows => _totalRows;
  int get previewCount => _previewCount;
  bool get hasPreviewTruncation => _totalRows > _previewCount;
  bool get isPreviewing => _status == UploadStatus.previewing;
  bool get isUploading => _status == UploadStatus.uploading;
  bool get isSuccess => _status == UploadStatus.success;
  bool get hasValidStudents => validStudents.isNotEmpty;
  bool get hasErrors => invalidStudents.isNotEmpty;

  Future<void> previewCsv(String csvText, String fileName) async {
    _fileName = fileName;
    _csvText = csvText;
    _status = UploadStatus.parsing;
    _errorMessage = null;
    notifyListeners();

    try {
      final preview = await _csvImportService.preview(csvText);
      _students = preview.rows;
      _totalRows = preview.totalRows;
      _previewCount = preview.previewCount;
      _status = UploadStatus.previewing;
    } catch (e) {
      _status = UploadStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> uploadStudents() async {
    if (_csvText == null || _csvText!.trim().isEmpty) {
      _errorMessage = 'Please choose a CSV file first.';
      notifyListeners();
      return;
    }

    _status = UploadStatus.uploading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _csvImportService.commit(_csvText!);
      _uploadedCount = result.inserted;
      _skippedCount = result.skipped;
      _status = UploadStatus.success;
    } catch (e) {
      _status = UploadStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // ── Reset for a new upload ─────────────────────────────────
  void reset() {
    _status = UploadStatus.idle;
    _students = [];
    _csvText = null;
    _fileName = null;
    _errorMessage = null;
    _uploadedCount = 0;
    _skippedCount = 0;
    _totalRows = 0;
    _previewCount = 0;
    notifyListeners();
  }
}
