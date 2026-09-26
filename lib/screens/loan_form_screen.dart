import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import '../controllers/loan_controller.dart';
import '../models/loan_contract.dart';

/// แท็บ 1: ฟอร์มยื่นเสนอโครงการเพื่อระดมทุน (Create)
/// ตาม RBAC ทั้ง Admin และ Operator สามารถบันทึกข้อมูลใหม่ได้
class LoanFormScreen extends StatefulWidget {
  final String currentUid;
  const LoanFormScreen({super.key, required this.currentUid});

  @override
  State<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends State<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loanController = LoanController();

  final _idController = TextEditingController();
  final _projectNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _principalController = TextEditingController();
  final _tenureController = TextEditingController();

  bool _isSaving = false;

  final _requiredValidator =
      RequiredValidator(errorText: 'ห้ามเว้นว่าง');

  final _emailValidator = MultiValidator([
    RequiredValidator(errorText: 'ห้ามเว้นว่าง'),
    EmailValidator(errorText: 'รูปแบบอีเมลไม่ถูกต้อง'),
  ]);

  @override
  void dispose() {
    _idController.dispose();
    _projectNameController.dispose();
    _emailController.dispose();
    _principalController.dispose();
    _tenureController.dispose();
    super.dispose();
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'ห้ามเว้นว่าง';
    if (double.tryParse(value.trim()) == null) return 'กรุณากรอกเป็นตัวเลขเท่านั้น';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final loan = LoanContract(
        id: _idController.text.trim(),
        projectName: _projectNameController.text.trim(),
        officerEmail: _emailController.text.trim(),
        principalAmount: double.parse(_principalController.text.trim()),
        tenureMonths: int.parse(_tenureController.text.trim()),
        createdByUid: widget.currentUid,
      );

      await _loanController.addLoan(loan);

      if (!mounted) return;
      _formKey.currentState!.reset();
      _idController.clear();
      _projectNameController.clear();
      _emailController.clear();
      _principalController.clear();
      _tenureController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกโครงการ "${loan.projectName}" สำเร็จ')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ยื่นเสนอโครงการเพื่อระดมทุน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'รหัสสัญญาเงินกู้ (Loan Contract ID)',
                hintText: 'เช่น LOAN-AGRI-501',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _projectNameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อโครงการ / สหกรณ์ผู้กู้',
                prefixIcon: Icon(Icons.agriculture),
                border: OutlineInputBorder(),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'อีเมลเจ้าหน้าที่สินเชื่อภาคสนาม',
                hintText: 'officer@microfund.co.th',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: _emailValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _principalController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'วงเงินที่ต้องการขอกู้ (บาท)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              validator: _validateNumber,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tenureController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ระยะเวลาผ่อนชำระ (เดือน)',
                hintText: 'เช่น 3, 6, 12, 24',
                prefixIcon: Icon(Icons.calendar_month),
                border: OutlineInputBorder(),
              ),
              validator: _validateNumber,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _submit,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_isSaving ? 'กำลังบันทึก...' : 'ยื่นเสนอโครงการ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}