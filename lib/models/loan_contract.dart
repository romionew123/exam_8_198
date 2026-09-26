import 'package:cloud_firestore/cloud_firestore.dart';

/// โมเดลข้อมูลสัญญาเงินกู้ 1 รายการ (Loan Contract)
/// ใช้ "รหัสสัญญาเงินกู้ (Loan Contract ID)" เป็น Document ID ใน Cloud Firestore โดยตรง
/// เพื่อให้การ Update / Delete ตาม ID ทำได้ง่ายและตรงไปตรงมา
class LoanContract {
  final String id; // รหัสสัญญาเงินกู้ เช่น LOAN-AGRI-501 (= Document ID)
  final String projectName; // ชื่อโครงการ / สหกรณ์ผู้กู้
  final String officerEmail; // อีเมลเจ้าหน้าที่สินเชื่อภาคสนาม
  final double principalAmount; // วงเงินที่ต้องการขอกู้ (บาท)
  final int tenureMonths; // ระยะเวลาผ่อนชำระ (เดือน)
  final Timestamp? createdAt; // เวลาที่บันทึก (สำหรับเรียงลำดับ)
  final String createdByUid; // uid ของผู้ยื่นเสนอโครงการ

  LoanContract({
    required this.id,
    required this.projectName,
    required this.officerEmail,
    required this.principalAmount,
    required this.tenureMonths,
    required this.createdByUid,
    this.createdAt,
  });

  /// แปลงเป็น Map เพื่อบันทึกลง Cloud Firestore
  Map<String, dynamic> toMap() {
    return {
      'loanContractId': id,
      'projectName': projectName,
      'officerEmail': officerEmail,
      'principalAmount': principalAmount,
      'tenureMonths': tenureMonths,
      'createdByUid': createdByUid,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  /// สร้างอ็อบเจ็กต์จาก Firestore DocumentSnapshot
  factory LoanContract.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return LoanContract(
      id: doc.id,
      projectName: data['projectName'] ?? '',
      officerEmail: data['officerEmail'] ?? '',
      principalAmount: (data['principalAmount'] ?? 0).toDouble(),
      tenureMonths: (data['tenureMonths'] ?? 0) as int,
      createdByUid: data['createdByUid'] ?? '',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}