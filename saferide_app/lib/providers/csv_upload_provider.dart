import 'package:flutter/foundation.dart';
import '../models/csv_student_model.dart';

enum UploadStatus { idle, picking, parsing, previewing, uploading, success, error }

class CsvUploadProvider extends ChangeNotifier {
  UploadStatus _status = UploadStatus.idle;
  List<CsvStudentModel> _students = [];
  String? _fileName;
  String? _selectedRouteId;
  String? _selectedRouteName;
  String? _selectedBusId;
  String? _selectedBusName;
  String? _errorMessage;
  int _uploadedCount = 0;

  // ── Getters ────────────────────────────────────────────────
  UploadStatus get status => _status;
  List<CsvStudentModel> get students => _students;
  List<CsvStudentModel> get validStudents =>
      _students.where((s) => !s.hasError).toList();
  List<CsvStudentModel> get invalidStudents =>
      _students.where((s) => s.hasError).toList();
  String? get fileName => _fileName;
  String? get selectedRouteId => _selectedRouteId;
  String? get selectedRouteName => _selectedRouteName;
  String? get selectedBusId => _selectedBusId;
  String? get selectedBusName => _selectedBusName;
  String? get errorMessage => _errorMessage;
  int get uploadedCount => _uploadedCount;
  bool get isPreviewing => _status == UploadStatus.previewing;
  bool get isUploading => _status == UploadStatus.uploading;
  bool get isSuccess => _status == UploadStatus.success;
  bool get hasValidStudents => validStudents.isNotEmpty;
  bool get hasErrors => invalidStudents.isNotEmpty;

  // ── Route + Bus selection ──────────────────────────────────
  void selectRoute(String id, String name) {
    _selectedRouteId = id;
    _selectedRouteName = name;
    notifyListeners();
  }

  void selectBus(String id, String name) {
    _selectedBusId = id;
    _selectedBusName = name;
    notifyListeners();
  }

  // ── Parse CSV rows ─────────────────────────────────────────
  void loadParsedStudents(List<List<dynamic>> rows, String fileName) {
    _fileName = fileName;

    // Skip header row
    final dataRows = rows.length > 1 ? rows.sublist(1) : rows;

    _students = dataRows
        .where((row) => row.any((cell) => cell.toString().trim().isNotEmpty))
        .map((row) => CsvStudentModel.fromRow(row))
        .toList();

    _status = UploadStatus.previewing;
    notifyListeners();
  }

  // ── Mock upload — replace body with real http call later ───
  Future<void> uploadStudents() async {
    if (_selectedRouteId == null || _selectedBusId == null) {
      _errorMessage = 'Please select a route and bus before uploading.';
      notifyListeners();
      return;
    }

    _status = UploadStatus.uploading;
    _errorMessage = null;
    notifyListeners();

    // ── MOCK: simulate network request ─────────────────────
    // When your backend is ready, replace this block with:
    //
    // final response = await http.post(
    //   Uri.parse('https://your-api.com/api/students/bulk-upload'),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer $token',
    //   },
    //   body: jsonEncode({
    //     'route_id': _selectedRouteId,
    //     'bus_id': _selectedBusId,
    //     'students': validStudents.map((s) => s.toJson()).toList(),
    //   }),
    // );
    // if (response.statusCode == 201) { ... success ... }
    // else { ... error ... }
    // ──────────────────────────────────────────────────────

    await Future.delayed(const Duration(seconds: 2));
    _uploadedCount = validStudents.length;
    _status = UploadStatus.success;
    notifyListeners();
  }

  // ── Reset for a new upload ─────────────────────────────────
  void reset() {
    _status = UploadStatus.idle;
    _students = [];
    _fileName = null;
    _selectedRouteId = null;
    _selectedRouteName = null;
    _selectedBusId = null;
    _selectedBusName = null;
    _errorMessage = null;
    _uploadedCount = 0;
    notifyListeners();
  }
}