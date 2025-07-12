import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoanDocumentsPage extends StatefulWidget {
  const LoanDocumentsPage({super.key});

  @override
  State<LoanDocumentsPage> createState() => _LoanDocumentsPageState();
}

class _LoanDocumentsPageState extends State<LoanDocumentsPage> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> dataList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      const String userId = "001"; // ใช้ id_user จริง

      final response = await http.get(
        Uri.parse("http://192.168.10.58:3001/loanRequests/$userId"),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          dataList = jsonData.map((item) {
            return {
              "name": "${item["first_name"] ?? ''} ${item["last_name"] ?? ''}",
              "time": item["request_date"] ?? '-',
              "status": mapStatus(item["id_status"]),
              "document": item["id_loanReq"] ?? '-',
            };
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('โหลดข้อมูลไม่สำเร็จ');
      }
    } catch (e) {
      print('เกิดข้อผิดพลาด: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String mapStatus(String? statusCode) {
    switch (statusCode) {
      case 'S001':
        return 'อนุมัติ';
      case 'S002':
        return 'รอดำเนินการ';
      case 'S003':
        return 'ไม่อนุมัติ';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        title: const Text("เอกสารสัญญากู้ยืม", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔍 ช่องค้นหา
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "ค้นหา",
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📅 ปุ่มเลือกวันที่
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("เลือกวันที่", style: TextStyle(fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                  ),
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  label: Text(
                    "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // หัวตาราง
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text("ชื่อ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  Expanded(flex: 2, child: Text("เวลา", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  Expanded(flex: 2, child: Text("สถานะ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  Expanded(flex: 2, child: Text("เอกสาร", textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // รายการ
            Expanded(
              child: ListView.builder(
                itemCount: dataList.length,
                itemBuilder: (context, index) {
                  final data = dataList[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(data["name"] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text(data["time"] ?? '')),
                          Expanded(flex: 2, child: Text(data["status"] ?? '', style: TextStyle(
                            color: data["status"] == "อนุมัติ"
                                ? Colors.green
                                : (data["status"] == "รอดำเนินการ"
                                ? Colors.orange
                                : Colors.red),
                            fontWeight: FontWeight.bold,
                          ))),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(Icons.search, color: Colors.orange),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("ดูเอกสารกู้ยืม: ${data['document']}"),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
