import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/constants.dart' as config;
import 'dart:convert';

class LoanRequestPage extends StatefulWidget {
  final String idUser;

  const LoanRequestPage({Key? key, required this.idUser}) : super(key: key);

  @override
  State<LoanRequestPage> createState() => _LoanRequestPageState();
}

class _LoanRequestPageState extends State<LoanRequestPage> {
  bool _isLoanRequested = false;
  bool _isLoading = false;

  final TextEditingController _loanReasonController = TextEditingController();
  final TextEditingController _loanAmountController = TextEditingController();

  void _submitLoanRequest() async {
    final reason = _loanReasonController.text.trim();
    final amount = double.tryParse(_loanAmountController.text.trim());

    if (reason.isEmpty || amount == null || amount <= 0) {
      _showSnackbar("กรุณากรอกเหตุผลและจำนวนเงินให้ถูกต้อง", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse('${config.apiUrl}/loan_requests');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_user': widget.idUser,
          'loan_amount': amount,
          'notes': reason,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isLoanRequested = true;
        });
        _showSnackbar("คำขอกู้เงินถูกส่งเรียบร้อย", Colors.green);
      } else {
        _showSnackbar("เกิดข้อผิดพลาด (${response.statusCode})", Colors.red);
      }
    } catch (e) {
      _showSnackbar("ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        title: const Text("ขอกู้เงิน", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          _buildFormContent(),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProfileCard(),
          const SizedBox(height: 20),
          _buildStepInfo(),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _loanAmountController,
            label: "จำนวนเงินที่ต้องการกู้ (บาท)",
            hint: "เช่น 10000",
            icon: Icons.attach_money,
            keyboard: TextInputType.number,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _loanReasonController,
            label: "เหตุผลในการกู้เงิน",
            hint: "เพื่อซ่อมบ้าน, เพื่อศึกษาต่อ ฯลฯ",
            icon: Icons.edit_note,
            maxLines: 3,
          ),
          const SizedBox(height: 30),
          if (_isLoanRequested)
            _buildInfoBox("คุณมีคำขอกู้ที่รอการอนุมัติ", Icons.hourglass_top, Colors.orange),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isLoanRequested ? null : _submitLoanRequest,
            icon: const Icon(Icons.send),
            label: const Text("ส่งคำขอกู้", style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isLoanRequested ? Colors.grey : Colors.blue[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[700],
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          "รหัสผู้ใช้: ${widget.idUser}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text("กรุณากรอกแบบฟอร์มด้านล่างให้ครบถ้วน"),
      ),
    );
  }

  Widget _buildStepInfo() {
    return Row(
      children: const [
        Icon(Icons.check_circle, color: Colors.green),
        SizedBox(width: 8),
        Text(
          "ขั้นตอนที่ 1/1: กรอกข้อมูลการขอกู้เงิน",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String message, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
