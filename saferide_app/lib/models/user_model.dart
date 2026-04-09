class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'parent', 'driver', 'admin'
  final String? schoolId;
  final String? phone;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.schoolId,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      schoolId: json['school_id']?.toString(),
      phone: json['phone']?.toString(),
    );
  }
}
