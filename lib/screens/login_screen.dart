import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:form_field_validator/form_field_validator.dart';
import '../controllers/auth_controller.dart';

/// หน้าจอลงชื่อเข้าใช้ระบบ MicroFund
/// รองรับการสลับบัญชีทดสอบระหว่าง Admin และ Operator เพื่อทดสอบ RBAC
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authController = AuthController();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  final _emailValidator = MultiValidator([
    RequiredValidator(errorText: 'กรุณากรอกอีเมล ห้ามเว้นว่าง'),
    EmailValidator(errorText: 'รูปแบบอีเมลไม่ถูกต้อง'),
  ]);

  final _passwordValidator = RequiredValidator(
    errorText: 'กรุณากรอกรหัสผ่าน ห้ามเว้นว่าง',
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authController.signIn(
        _emailController.text,
        _passwordController.text,
      );
      // ไม่ต้อง navigate เอง: main.dart ฟัง authStateChanges ผ่าน StreamBuilder
      // แล้วจะสลับไปหน้า HomeScreen ให้อัตโนมัติเมื่อ login สำเร็จ
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          'user-not-found' => 'ไม่พบบัญชีผู้ใช้นี้ในระบบ',
          'wrong-password' => 'รหัสผ่านไม่ถูกต้อง',
          'invalid-email' => 'รูปแบบอีเมลไม่ถูกต้อง',
          'invalid-credential' => 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
          _ => 'เข้าสู่ระบบไม่สำเร็จ: ${e.message}',
        };
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.monetization_on,
                        size: 56, color: Colors.amber.shade700),
                    const SizedBox(height: 8),
                    const Text(
                      'MicroFund',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'ลงชื่อเข้าใช้ระบบบริหารจัดการสินเชื่อรายย่อย',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'อีเมล',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: _emailValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'รหัสผ่าน',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: _passwordValidator,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _login,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.login),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child:
                            Text(_isLoading ? 'กำลังเข้าสู่ระบบ...' : 'เข้าสู่ระบบ'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 4),
                    const Text(
                      'บัญชีทดสอบ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text('Admin: admin@test.com  (สิทธิ์ CRUD ครบถ้วน)'),
                    const Text(
                        'Operator: operator@test.com  (สิทธิ์ Create/Read เท่านั้น)'),
                    const Text(
                      'ต้องสร้างบัญชีทั้งสองไว้ล่วงหน้าใน Firebase Authentication '
                      'และสร้างเอกสารสิทธิ์ที่ตรงกันใน Firestore collection "users"',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}