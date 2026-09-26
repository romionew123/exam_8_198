import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

/// Controller รับผิดชอบการยืนยันตัวตน (Authentication) และการดึงข้อมูล Role
/// จาก Collection "users" ใน Cloud Firestore เพื่อใช้กับระบบ RBAC
class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference<Map<String, dynamic>> _usersRef =
      FirebaseFirestore.instance.collection('users');

  /// สตรีมสถานะการล็อกอิน ใช้กับ StreamBuilder ใน main.dart เพื่อสลับหน้าจอ
  /// อัตโนมัติระหว่าง LoginScreen และ HomeScreen
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  /// เข้าสู่ระบบด้วยอีเมล/รหัสผ่าน
  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  /// ดึงข้อมูล Role ของผู้ใช้ปัจจุบันจาก Firestore collection "users"
  Future<AppUser> fetchAppUser(User firebaseUser) async {
    // ---- DEBUG: ลบทิ้งได้หลังแก้ปัญหาเสร็จ ----
    // ignore: avoid_print
    print('🔍 [DEBUG] กำลังล็อกอินด้วย email: ${firebaseUser.email}');
    // ignore: avoid_print
    print('🔍 [DEBUG] UID ของ Firebase Auth: ${firebaseUser.uid}');

    final doc = await _usersRef
        .doc(firebaseUser.uid)
        .get(const GetOptions(source: Source.server)); // บังคับอ่านจาก server ตรงๆ ไม่เอา cache

    // ignore: avoid_print
    print('🔍 [DEBUG] Document exists: ${doc.exists}');
    // ignore: avoid_print
    print('🔍 [DEBUG] Document data ทั้งหมด: ${doc.data()}');

    if (!doc.exists) {
      throw Exception(
        'ไม่พบข้อมูลผู้ใช้ในระบบ (users collection) กรุณาสร้างเอกสารผู้ใช้ '
        'ที่มี Document ID ตรงกับ Firebase Auth UID ก่อน',
      );
    }

    final appUser = AppUser.fromMap(firebaseUser.uid, doc.data()!);

    // ignore: avoid_print
    print('🔍 [DEBUG] Role ที่แปลงได้: ${appUser.role} (isAdmin: ${appUser.isAdmin})');
    // ---- END DEBUG ----

    return appUser;
  }
}