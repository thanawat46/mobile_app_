import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:mobile_app/constants.dart' as config;

class LoanPaymentPage extends StatefulWidget {
  final String idUser;

  const LoanPaymentPage({super.key, required this.idUser});

  @override
  State<LoanPaymentPage> createState() => _LoanPaymentPageState();
}

class _LoanPaymentPageState extends State<LoanPaymentPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  double? _loanAmount;
  bool _isSubmitting = false;
  File? _selectedSlip;

  @override
  void initState() {
    super.initState();
    fetchLoanAmount();
  }

  Future<void> fetchLoanAmount() async {
    final url = Uri.parse('${config.apiUrl}/loan/${widget.idUser}');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _loanAmount = data['loan_balance']?.toDouble() ?? 0.0;
        });
      } else {
        showSnackBar("ไม่สามารถโหลดยอดเงินกู้ได้ (${res.statusCode})", Colors.red);
      }
    } catch (e) {
      showSnackBar("เกิดข้อผิดพลาด: $e", Colors.red);
    }
  }

  Future<void> pickSlipImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedSlip = File(picked.path);
      });
    }
  }

  Future<String?> uploadSlipToFirebase(File file) async {
    try {
      final fileName = 'slips/${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      showSnackBar("อัปโหลดสลิปล้มเหลว: $e", Colors.red);
      return null;
    }
  }

  Future<void> submitPayment() async {
    final amount = double.tryParse(_amountController.text.trim());
    final note = _noteController.text.trim();

    if (amount == null || amount <= 0) {
      showSnackBar("กรุณากรอกจำนวนเงินที่ถูกต้อง", Colors.red);
      return;
    }

    if (_selectedSlip == null) {
      showSnackBar("กรุณาอัปโหลดรูปสลิป", Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    final slipUrl = await uploadSlipToFirebase(_selectedSlip!);
    if (slipUrl == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    final url = Uri.parse('${config.apiUrl}/loan/pay');
    final body = jsonEncode({
      'id_user': widget.idUser,
      'amount': amount,
      'note': note,
      'slip_url': slipUrl,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      setState(() => _isSubmitting = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        showSnackBar("ชำระเงินสำเร็จ", Colors.green);
        _amountController.clear();
        _noteController.clear();
        setState(() => _selectedSlip = null);
        fetchLoanAmount();
      } else {
        showSnackBar("เกิดข้อผิดพลาด: ${response.statusCode}", Colors.red);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      showSnackBar("เชื่อมต่อไม่ได้: $e", Colors.red);
    }
  }

  void showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("ชำระเงินกู้"),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            if (_loanAmount != null)
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text("ยอดเงินกู้คงเหลือ", style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text(
                      "฿${_loanAmount!.toStringAsFixed(0)}",
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration("จำนวนเงินที่ชำระ", Icons.payments),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: _inputDecoration("หมายเหตุ (ถ้ามี)", Icons.edit_note),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: pickSlipImage,
              icon: const Icon(Icons.upload_file),
              label: const Text("อัปโหลดรูปสลิป"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.black87,
              ),
            ),
            if (_selectedSlip != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedSlip!, height: 200),
                ),
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSubmitting ? null : submitPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFC62828),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("ชำระเงินกู้", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
