// การทดสอบพื้นฐานสำหรับแอป MicroFund
//
// หมายเหตุ: ไม่ทดสอบ MicroFundApp (main.dart) ตรง ๆ เพราะแอปเรียก
// Firebase.initializeApp() ซึ่งต้องมีการ mock ก่อนจึงจะรันใน widget test ได้
// จึงทดสอบเฉพาะ LoginScreen ซึ่งไม่ต้องพึ่ง Firebase ในการแสดงผล UI

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exam_8_198/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen shows MicroFund title and login form',
      (WidgetTester tester) async {
    // Build LoginScreen ภายใต้ MaterialApp (จำเป็นสำหรับ Theme/Navigator)
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // ต้องเห็นชื่อแอป
    expect(find.text('MicroFund'), findsOneWidget);

    // ต้องมีช่องกรอกอีเมลและรหัสผ่าน
    expect(find.widgetWithText(TextFormField, 'อีเมล'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'รหัสผ่าน'), findsOneWidget);

    // ต้องมีปุ่มเข้าสู่ระบบ
    expect(find.widgetWithText(ElevatedButton, 'เข้าสู่ระบบ'), findsOneWidget);
  });

  testWidgets('LoginScreen shows validation errors on empty submit',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // กดปุ่มเข้าสู่ระบบโดยไม่กรอกข้อมูลใด ๆ
    await tester.tap(find.widgetWithText(ElevatedButton, 'เข้าสู่ระบบ'));
    await tester.pump();

    // ต้องมีข้อความแจ้งเตือนห้ามเว้นว่างปรากฏขึ้น
    expect(find.text('กรุณากรอกอีเมล ห้ามเว้นว่าง'), findsOneWidget);
    expect(find.text('กรุณากรอกรหัสผ่าน ห้ามเว้นว่าง'), findsOneWidget);
  });
}