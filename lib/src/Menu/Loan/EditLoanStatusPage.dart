import 'package:flutter/material.dart';
import 'package:mobile_app/constants.dart' as config;
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditLoanStatusPage extends StatefulWidget {
  final String idUser;
  const EditLoanStatusPage({Key? key, required this.idUser}) : super(key: key);

  @override
  State<EditLoanStatusPage> createState() => _EditLoanStatusPageState();
}

class _EditLoanStatusPageState extends State<EditLoanStatusPage> {
  List<Map<String, dynamic>> loanRequests = [];
  bool _isLoading = false;

  final List<Map<String, String>> statuses = [
    {'id': 'S000', 'name': 'กำลังรออนุมัติ'},
    {'id': 'S001', 'name': 'อนุมัติแล้ว'},
    {'id': 'S002', 'name': 'รอดำเนินการ'},
    {'id': 'S003', 'name': 'ไม่ผ่านอนุมัติ'},
  ];

  @override
  void initState() {
    super.initState();
    fetchLoanRequests();
  }

  Future<void> fetchLoanRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("${config.apiUrl}/loan-requests"));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          loanRequests = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (_) {
      _showError("ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> updateStatus(String idLoanReq, String idStatus, String? dueDate) async {
    final url = Uri.parse("${config.apiUrl}/update-loan-status");
    try {
      final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_loanReq': idLoanReq,
          'id_status': idStatus,
          'payment_due_date': dueDate
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("อัปเดตเรียบร้อย")));
      } else {
        _showError("ไม่สามารถอัปเดตได้ (${response.statusCode})");
      }
    } catch (_) {
      _showError("เกิดข้อผิดพลาดในการเชื่อมต่อ");
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("ข้อผิดพลาด"),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("ตกลง"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("จัดการสถานะคำขอกู้เงิน"), backgroundColor: const Color(0xFF0D47A1)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : loanRequests.isEmpty
          ? const Center(child: Text("ไม่มีคำขอกู้ยืม", style: TextStyle(fontSize: 18)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: loanRequests.length,
        itemBuilder: (context, index) {
          final item = loanRequests[index];
          String selectedStatus = item['id_status'];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("รหัสผู้ใช้: ${item['id_user']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("ชื่อ-สกุล: ${item['first_name']} ${item['last_name']}", style: const TextStyle()),
                  Text("จำนวนเงินที่ขอกู้: ฿${item['loan_amount']}", style: const TextStyle()),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(labelText: "สถานะคำขอ"),
                    items: statuses.map((status) => DropdownMenuItem(
                        value: status['id'], child: Text(status['name']!))).toList(),
                    onChanged: (value) {
                      setState(() {
                        loanRequests[index]['id_status'] = value!;
                      });
                    },
                  ),
                  if (loanRequests[index]['id_status'] == 'S001') ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        loanRequests[index]['due_date'] != null
                            ? loanRequests[index]['due_date'].substring(0, 10)
                            : "เลือกวันครบกำหนด",
                      ),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            loanRequests[index]['due_date'] = picked.toIso8601String();
                          });
                        }
                      },
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("บันทึกสถานะ"),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("ยืนยันการบันทึก"),
                            content: const Text("คุณต้องการบันทึกสถานะนี้ใช่หรือไม่?"),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("ยกเลิก")),
                              ElevatedButton(
                                child: const Text("ยืนยัน"),
                                onPressed: () {
                                  Navigator.pop(context);
                                  updateStatus(
                                    item['id_loanReq'],
                                    loanRequests[index]['id_status'],
                                    loanRequests[index]['due_date'],
                                  );
                                },
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
