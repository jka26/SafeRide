/// Temporary model used during CSV upload preview.
/// Once confirmed and saved to the DB, it becomes a StudentModel.
class CsvStudentModel {
  final String name;
  final String grade;
  final String stopName;
  final String dropOffTime;
  final String emergencyContactName;
  final String emergencyContactPhone;
  bool hasError;
  String? errorMessage;

  CsvStudentModel({
    required this.name,
    required this.grade,
    required this.stopName,
    required this.dropOffTime,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    this.hasError = false,
    this.errorMessage,
  });

  /// Parse one CSV row into a CsvStudentModel.
  /// Expected columns (in order):
  /// name, grade, stop_name, drop_off_time,
  /// emergency_contact_name, emergency_contact_phone
  factory CsvStudentModel.fromRow(List<dynamic> row) {
    if (row.length < 6) {
      return CsvStudentModel(
        name: row.isNotEmpty ? row[0].toString() : '',
        grade: '', stopName: '', dropOffTime: '',
        emergencyContactName: '', emergencyContactPhone: '',
        hasError: true,
        errorMessage: 'Row has ${row.length} columns, expected 6.',
      );
    }
    final model = CsvStudentModel(
      name: row[0].toString().trim(),
      grade: row[1].toString().trim(),
      stopName: row[2].toString().trim(),
      dropOffTime: row[3].toString().trim(),
      emergencyContactName: row[4].toString().trim(),
      emergencyContactPhone: row[5].toString().trim(),
    );
    model._validate();
    return model;
  }

  void _validate() {
    if (name.isEmpty) {
      hasError = true;
      errorMessage = 'Name is required';
    } else if (grade.isEmpty) {
      hasError = true;
      errorMessage = 'Grade is required';
    } else if (stopName.isEmpty) {
      hasError = true;
      errorMessage = 'Stop name is required';
    }
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'grade': grade,
    'stop_name': stopName,
    'drop_off_time': dropOffTime,
    'emergency_contact': {
      'name': emergencyContactName,
      'phone': emergencyContactPhone,
    },
  };

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory CsvStudentModel.fromBackendRow(Map<String, dynamic> row) {
    return CsvStudentModel(
      name: (row['fullName'] ?? '').toString(),
      grade: (row['grade'] ?? '').toString(),
      stopName: (row['stopName'] ?? '').toString(),
      dropOffTime: (row['dropOffTime'] ?? '').toString(),
      emergencyContactName: (row['emergencyContactName'] ?? '').toString(),
      emergencyContactPhone: (row['emergencyContactPhone'] ?? '').toString(),
    );
  }
}
