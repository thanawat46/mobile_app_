import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/constants.dart' as config;

class LoanScreen extends StatefulWidget {
  final String idUser;

  const LoanScreen({super.key, required this.idUser});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  List<dynamic> loanUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLoanUsers();
  }

  Future<void> fetchLoanUsers() async {
    try {
      final response = await http.get(Uri.parse("${config.apiUrl}/loan"));
      if (response.statusCode == 200) {
        setState(() {
          loanUsers = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print("โหลดข้อมูลไม่สำเร็จ: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("เกิดข้อผิดพลาด: $e");
    }
  }

  Future<void> updateLoanAmount(String idLoan, double newAmount) async {
    try {
      final response = await http.put(
        Uri.parse("${config.apiUrl}/loan/update-amount"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_loan": idLoan,
          "loan_amount": newAmount,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("อัปเดตจำนวนเงินสำเร็จ")),
        );
        fetchLoanUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("เกิดข้อผิดพลาดในการอัปเดต")),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์")),
      );
    }
  }

  Future<void> deleteLoan(String idLoan) async {
    final response = await http.delete(Uri.parse("${config.apiUrl}/loan-full/$idLoan"));
    if (response.statusCode == 200) {
      fetchLoanUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ลบข้อมูลสำเร็จ")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เกิดข้อผิดพลาดในการลบ")),
      );
    }
  }

  void _confirmDelete(String idLoan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: const Text("คุณแน่ใจหรือไม่ว่าต้องการลบรายการนี้?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("ยกเลิก")),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              deleteLoan(idLoan);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("ลบเลย", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        title: const Text("รายชื่อสมาชิกเงินกู้", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeaderRow(),
            const SizedBox(height: 8),
            Expanded(child: _buildLoanList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Expanded(flex: 4, child: Text("ชื่อ - รหัส", style: TextStyle(color: Colors.white))),
          Expanded(flex: 2, child: Text("วงเงิน", style: TextStyle(color: Colors.white))),
          Expanded(flex: 3, child: Text("การจัดการ", textAlign: TextAlign.right, style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildLoanList() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (loanUsers.isEmpty) return const Center(child: Text("ไม่พบข้อมูลเงินกู้"));

    return ListView.builder(
      itemCount: loanUsers.length,
      itemBuilder: (context, index) {
        final user = loanUsers[index];
        final fullName = "${user['first_name']} ${user['last_name']}";
        final userId = user['id_user'];
        final amount = user['loan_amount'].toString();
        final idLoan = user['id_loan'];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text("รหัส: $userId", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text("฿$amount", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.orange),
                        onPressed: () {
                          final TextEditingController _amountController = TextEditingController(text: amount);
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text("รายละเอียดเงินกู้", style: TextStyle(fontWeight: FontWeight.bold)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("ชื่อ: $fullName"),
                                    Text("รหัสสมาชิก: $userId"),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _amountController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: "จำนวนเงิน (บาท)"),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text("ยกเลิก"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final updatedAmount = double.tryParse(_amountController.text);
                                      if (updatedAmount != null) {
                                        await updateLoanAmount(idLoan, updatedAmount);
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    child: const Text("บันทึก"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _confirmDelete(idLoan);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
