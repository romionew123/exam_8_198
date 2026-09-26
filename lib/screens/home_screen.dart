import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/app_user.dart';
import 'loan_form_screen.dart';
import 'loan_list_screen.dart';

/// หน้าหลักหลัง Login สำเร็จ ประกอบด้วย 2 แท็บหลัก
/// พร้อมแสดง Role ปัจจุบัน และปุ่ม Sign Out บน AppBar เพื่อสลับบัญชีทดสอบ
class HomeScreen extends StatefulWidget {
  final AppUser currentUser;
  const HomeScreen({super.key, required this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authController = AuthController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.currentUser.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monetization_on, color: Colors.white),
            SizedBox(width: 8),
            Text('MicroFund'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Chip(
              label: Text(
                isAdmin ? 'Admin' : 'Operator',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor:
                  isAdmin ? Colors.green.shade700 : Colors.blueGrey,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out (${widget.currentUser.email})',
            onPressed: () => _authController.signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit_document), text: 'ยื่นเสนอโครงการ'),
            Tab(icon: Icon(Icons.list_alt), text: 'พอร์ตสินเชื่อ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ทั้ง Admin และ Operator บันทึกข้อมูลใหม่ได้ (Create)
          LoanFormScreen(currentUid: widget.currentUser.uid),
          // Edit / Delete จะแสดงเฉพาะเมื่อ isAdmin เป็น true เท่านั้น
          LoanListScreen(isAdmin: isAdmin),
        ],
      ),
    );
  }
}