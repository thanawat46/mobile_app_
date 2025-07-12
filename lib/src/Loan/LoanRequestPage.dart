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
  final TextEditingController _loanReasonController = TextEditingController();
  final TextEditingController _loanAmountController = TextEditingController();

  void _submitLoanRequest() async {
    final reason = _loanReasonController.text.trim();
    final amount = double.tryParse(_loanAmountController.text.trim());

    if (reason.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("กรุณากรอกเหตุผลและจำนวนเงินให้ถูกต้อง"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = Uri.parse('${config.apiUrl}/loan_requests'); // ✅ ใช้ POST อย่างเดียว

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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("คำขอกู้เงินของคุณถูกส่งแล้ว"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาดในการส่งคำขอ (${response.statusCode})"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        title: const Text("ขอกู้เงิน", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // ✅ Profile Card ด้านบน
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[700],
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text("รหัสผู้ใช้: ${widget.idUser}", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("กรุณากรอกแบบฟอร์มด้านล่างให้ครบถ้วน"),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ✅ Container หลัก
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6F8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: ListView(
                children: [
                  // แถบขั้นตอน
                  Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text("ขั้นตอนที่ 1/1: กรอกข้อมูลการขอกู้เงิน",
                          style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ปุ่มดาวน์โหลดเอกสาร
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: download document
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text("ดาวน์โหลดเอกสาร", style: TextStyle(fontSize: 16)),
                  ),

                  const SizedBox(height: 24),

                  // กล่องใส่จำนวนเงิน
                  const Text("จำนวนเงินที่ต้องการกู้ (บาท)", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _loanAmountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.attach_money),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "เช่น 10000",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // กล่องใส่เหตุผล
                  const Text("เหตุผลในการกู้เงิน", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    style: TextStyle(fontFamily: 'NotoSansThai'),
                    controller: _loanReasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.edit_note),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "เพื่อซ่อมบ้าน, เพื่อศึกษาต่อ ฯลฯ",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // แสดงสถานะคำขอ
                  if (_isLoanRequested)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.hourglass_top, color: Colors.orange),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text("คุณมีคำขอกู้ที่รอการอนุมัติ", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ปุ่มขอกู้
                  ElevatedButton.icon(
                    onPressed: _isLoanRequested ? null : _submitLoanRequest,
                    icon: Icon(Icons.send),
                    label: Text("ขอกู้เงิน", style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLoanRequested ? Colors.grey : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
