import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../controllers/loan_controller.dart';
import '../models/loan_contract.dart';

/// แท็บ 2: แสดงพอร์ตสินเชื่อที่เปิดระดมทุนแบบ Real-time (Read)
/// ปุ่ม Edit / Delete จะแสดงเฉพาะผู้ใช้ที่มีสิทธิ์ Admin เท่านั้น (RBAC)
class LoanListScreen extends StatelessWidget {
  final bool isAdmin;
  const LoanListScreen({super.key, required this.isAdmin});

  Future<void> _showEditDialog(
    BuildContext context,
    LoanController controller,
    LoanContract loan,
  ) async {
    final principalController =
        TextEditingController(text: loan.principalAmount.toStringAsFixed(0));
    final tenureController =
        TextEditingController(text: loan.tenureMonths.toString());

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('ปรับโครงสร้างหนี้: ${loan.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: principalController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'วงเงินที่ขอกู้ใหม่ (บาท)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tenureController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ระยะเวลาผ่อนชำระใหม่ (เดือน)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPrincipal =
                    double.tryParse(principalController.text.trim());
                final newTenure = int.tryParse(tenureController.text.trim());
                if (newPrincipal == null || newTenure == null) return;
                try {
                  await controller.updateLoan(
                    loan.id,
                    newPrincipal: newPrincipal,
                    newTenureMonths: newTenure,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('แก้ไขไม่สำเร็จ: $e')),
                    );
                  }
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    LoanController controller,
    LoanContract loan,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: Text(
            'ต้องการยกเลิกคำขอ/ปิดพอร์ต "${loan.id} - ${loan.projectName}" ใช่หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  await controller.deleteLoan(loan.id);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('ลบไม่สำเร็จ: $e')),
                    );
                  }
                }
              },
              child: const Text('ยืนยันลบ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = LoanController();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: controller.streamLoans(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'ยังไม่มีโครงการที่เปิดระดมทุน\nไปที่แท็บ "ยื่นเสนอโครงการ" เพื่อเพิ่มรายการ',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        final loans = docs.map((d) => LoanContract.fromDoc(d)).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: loans.length,
          itemBuilder: (context, index) {
            final loan = loans[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.amber.shade700,
                  child: Text(
                    '${loan.tenureMonths}\nด.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                ),
                title: Text(
                  loan.id,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${loan.projectName}\n'
                  'วงเงิน: ${loan.principalAmount.toStringAsFixed(0)} บาท',
                ),
                isThreeLine: true,
                // RBAC: ปุ่ม Edit / Delete แสดงเฉพาะ Admin เท่านั้น
                // Operator จะไม่เห็นปุ่มเหล่านี้เลย (ถูกซ่อน ไม่ใช่แค่ปิดใช้งาน)
                trailing: isAdmin
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: 'แก้ไข',
                            onPressed: () =>
                                _showEditDialog(context, controller, loan),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'ลบ',
                            onPressed: () => _showDeleteConfirmDialog(
                                context, controller, loan),
                          ),
                        ],
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}