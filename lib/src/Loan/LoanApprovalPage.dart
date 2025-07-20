import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../constants.dart' as config;

class LoanApprovalPage extends StatefulWidget {
  @override
  State<LoanApprovalPage> createState() => _LoanApprovalPageState();
}

class _LoanApprovalPageState extends State<LoanApprovalPage> {
  List<Map<String, dynamic>> payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchPayments();
  }

  Future<void> fetchPayments() async {
    final res = await http.get(Uri.parse('${config.apiUrl}/loan/payments?status=S002'));
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      final rawData = decoded is List ? decoded : (decoded['data'] ?? []);
      if (rawData is List) {
        setState(() {
          payments = List<Map<String, dynamic>>.from(rawData);
          _loading = false;
        });
      } else {
        setState(() {
          payments = [];
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ไม่พบข้อมูลรายการชำระเงิน")),
        );
      }
    } else {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการโหลดข้อมูล")),
      );
    }
  }

  Future<void> updateStatus(String id, String status) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    final res = await http.post(
      Uri.parse('${config.apiUrl}/approve'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_payment': id, 'status': status}),
    );

    Navigator.of(context).pop(); // ปิดโหลด

    if (res.statusCode == 200) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text("อัปเดตสำเร็จ"),
        ),
      );
      await Future.delayed(Duration(seconds: 1));
      Navigator.of(context).pop(); // ปิด popup
      fetchPayments(); // โหลดใหม่
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการอัปเดต")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final blue = Color(0xFF0D47A1);
    final lightBlue = Color(0xFFE3F2FD);

    return Scaffold(
      backgroundColor: Color(0xFFF1F7FF),
      appBar: AppBar(
        title: Text("อนุมัติสลิปชำระเงินกู้"),
        backgroundColor: Color(0xFF0D47A1),
        foregroundColor: Color(0xFFF1F7FF),
        elevation: 0.5,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : payments.isEmpty
          ? Center(child: Text("ไม่มีรายการรออนุมัติ", style: TextStyle(color: blue)))
          : ListView.builder(
          itemCount: payments.length,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemBuilder: (context, index) {
            final item = payments[index];
            return Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: blue.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: blue.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ผู้ใช้: ${item['id_user']}",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: blue)),
                    SizedBox(height: 6),
                    Text("จำนวนเงิน: ฿${item['amount']}",
                        style: TextStyle(fontSize: 15)),
                    SizedBox(height: 6),
                    Text("หมายเหตุ: ${item['note'] ?? '-'}",
                        style: TextStyle(color: Colors.grey[700])),
                    SizedBox(height: 12),
                    if (item['slip_url'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item['slip_url'],
                          fit: BoxFit.cover,
                          height: 160,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Center(child: Text("โหลดรูปไม่สำเร็จ")),
                        ),
                      ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF9CC69B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: Icon(Icons.check),
                          label: Text("อนุมัติ"),
                          onPressed: () => updateStatus(item['id_payment'], "S001"),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade300,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: Icon(Icons.close),
                          label: Text("ไม่อนุมัติ"),
                          onPressed: () => updateStatus(item['id_payment'], "S003"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }
}
