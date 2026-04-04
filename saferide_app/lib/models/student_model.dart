class StudentModel {
  final String id;
  final String name;
  final String grade;
  final String? stopId;
  final String? stopName;
  final String? dropOffTime;
  final String status; // 'pending', 'boarded', 'alighted', 'absent'

  const StudentModel({
    required this.id,
    required this.name,
    required this.grade,
    this.stopId,
    this.stopName,
    this.dropOffTime,
    this.status = 'pending',
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}