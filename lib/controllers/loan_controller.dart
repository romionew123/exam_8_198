import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loan_contract.dart';

/// Controller รับผิดชอบ CRUD Operations ทั้งหมดกับ Collection "loans"
/// ใน Cloud Firestore (พอร์ตสินเชื่อที่เปิดระดมทุน)
class LoanController {
  final CollectionReference<Map<String, dynamic>> _loansRef =
      FirebaseFirestore.instance.collection('loans');

  /// Create: บันทึกสัญญาเงินกู้ใหม่ ใช้รหัสสัญญาเงินกู้เป็น Document ID โดยตรง
  /// เปิดให้ทั้ง Admin และ Operator ใช้งานได้ตาม RBAC
  Future<void> addLoan(LoanContract loan) async {
    final existing = await _loansRef.doc(loan.id).get();
    if (existing.exists) {
      throw Exception('รหัสสัญญาเงินกู้ "${loan.id}" มีอยู่ในระบบแล้ว กรุณาใช้รหัสอื่น');
    }
    await _loansRef.doc(loan.id).set(loan.toMap());
  }

  /// Read: สตรีมข้อมูลแบบ Real-time เรียงตามเวลาที่บันทึกล่าสุดก่อน
  /// ใช้ร่วมกับ StreamBuilder ในหน้า Report/List
  Stream<QuerySnapshot<Map<String, dynamic>>> streamLoans() {
    return _loansRef.orderBy('createdAt', descending: true).snapshots();
  }

  /// Update: ปรับลดวงเงินกู้ / ปรับโครงสร้างหนี้ (เฉพาะ Admin ตาม RBAC — ตรวจสิทธิ์ที่ชั้น UI)
  Future<void> updateLoan(
    String loanId, {
    required double newPrincipal,
    required int newTenureMonths,
  }) {
    return _loansRef.doc(loanId).update({
      'principalAmount': newPrincipal,
      'tenureMonths': newTenureMonths,
    });
  }

  /// Delete: ยกเลิกคำขอ / ปิดพอร์ตเมื่อระดมทุนครบ (เฉพาะ Admin ตาม RBAC — ตรวจสิทธิ์ที่ชั้น UI)
  Future<void> deleteLoan(String loanId) {
    return _loansRef.doc(loanId).delete();
  }
}