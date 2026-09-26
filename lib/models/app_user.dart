/// ระดับสิทธิ์การใช้งาน (Role-Based Access Control)
enum UserRole { admin, operator }

UserRole userRoleFromString(String value) {
  switch (value.trim().toLowerCase()) {
    case 'admin':
      return UserRole.admin;
    case 'operator':
      return UserRole.operator;
    default:
      // ค่าเริ่มต้นปลอดภัยที่สุดหากไม่พบ role ที่ถูกต้อง คือจำกัดสิทธิ์แบบ Operator
      return UserRole.operator;
  }
}

/// โมเดลข้อมูลผู้ใช้งานระบบ สอดคล้องกับ Collection "users" ใน Cloud Firestore
/// เก็บ uid, name, email, role
class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: userRoleFromString(data['role'] ?? 'operator'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role == UserRole.admin ? 'admin' : 'operator',
    };
  }
}