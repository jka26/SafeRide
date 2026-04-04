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
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      schoolId: json['school_id'],
      phone: json['phone'],
    );
  }
}