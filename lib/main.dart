import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'controllers/auth_controller.dart';
import 'models/app_user.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MicroFundApp());
}

class MicroFundApp extends StatelessWidget {
  const MicroFundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MicroFund',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber.shade700),
        useMaterial3: true,
      ),
      // Initialize Firebase ผ่าน FutureBuilder ตามข้อกำหนดของใบงานที่ 6
      // Firebase.initializeApp() จะอ่านค่าคอนฟิกจาก google-services.json
      // (Android) โดยอัตโนมัติ หลังตั้งค่า Gradle ตามคู่มือใน SETUP.md
      home: FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'เชื่อมต่อ Firebase ไม่สำเร็จ:\n${snapshot.error}\n\n'
                    'ตรวจสอบไฟล์ google-services.json และการตั้งค่า Gradle '
                    'ตามคู่มือ SETUP.md',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            );
          }
          return const AuthGate();
        },
      ),
    );
  }
}

/// สลับหน้าจออัตโนมัติระหว่าง LoginScreen และ HomeScreen
/// ตามสถานะการล็อกอินปัจจุบัน (Firebase Authentication)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = AuthController();

    return StreamBuilder<User?>(
      stream: authController.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final firebaseUser = snapshot.data;
        if (firebaseUser == null) {
          return const LoginScreen();
        }

        // ผู้ใช้ล็อกอินแล้ว -> ดึง Role จาก Firestore collection "users"
        // เพื่อใช้กับระบบ RBAC ก่อนเข้าหน้า HomeScreen
        return FutureBuilder<AppUser>(
          future: authController.fetchAppUser(firebaseUser),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (userSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ไม่สามารถโหลดข้อมูลสิทธิ์ผู้ใช้ได้:\n${userSnapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => authController.signOut(),
                          child: const Text('ออกจากระบบ'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return HomeScreen(currentUser: userSnapshot.data!);
          },
        );
      },
    );
  }
}