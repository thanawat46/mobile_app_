import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:mobile_app/constants.dart' as config;

class Detailssaving extends StatefulWidget {
  final String idDepositAm;
  const Detailssaving({Key? key, required this.idDepositAm}) : super(key: key);

  @override
  State<Detailssaving> createState() => _DetailssavingState();
}

class _DetailssavingState extends State<Detailssaving> {
  List<Map<String, dynamic>> savingsData = [];
  bool isLoading = true;
  String? errorMessage;

  final List<String> monthNames = [
    "มกราคม", "กุมภาพันธ์", "มีนาคม", "เมษายน", "พฤษภาคม", "มิถุนายน",
    "กรกฎาคม", "สิงหาคม", "กันยายน", "ตุลาคม", "พฤศจิกายน", "ธันวาคม"
  ];

  @override
  void initState() {
    super.initState();
    fetchSavingsData();
  }

  Future<void> fetchSavingsData() async {
    final String apiUrl = "${config.apiUrl}/deposit/DepositMonth";
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"idDepositAm": widget.idDepositAm}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse is Map && jsonResponse.containsKey("Deposit_month")) {
          final List<dynamic> data = jsonResponse["Deposit_month"];
          Map<int, double> depositMap = {};

          for (var item in data) {
            // แปลงค่า month เป็น int
            int month = int.tryParse(item["month"].toString()) ?? 0;
            // แปลงค่า amount เป็น double
            double amount = double.tryParse(item["amount"].toString()) ?? 0.0;

            // เก็บข้อมูลลง depositMap
            depositMap[month] = amount;
          }

          // สร้างข้อมูลเดือนที่เหลือและปริมาณเงิน
          List<Map<String, dynamic>> allMonthsData = List.generate(12, (index) {
            int monthNumber = index + 1;
            return {
              "month": monthNames[index],
              "amount": depositMap[monthNumber] ?? 0.0
            };
          });

          if (mounted) {
            setState(() {
              savingsData = allMonthsData;
              isLoading = false;
            });
          }
        } else {
          throw Exception("API Response ไม่มี key 'Deposit_month'");
        }
      } else {
        setState(() {
          errorMessage = "เกิดข้อผิดพลาด: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "ไม่สามารถเชื่อมต่อ API ได้: $e";
        isLoading = false;
      });
    }
  }

  int get totalAmount => savingsData.fold<int>(
    0,
        (sum, item) => sum + ((item["amount"] ?? 0) as num).toInt(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text(
          "รายละเอียดเงินฝาก",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
          : DepositDetailsBody(
        savingsData: savingsData,
        totalAmount: totalAmount,
      ),
    );
  }
}

class DepositDetailsBody extends StatelessWidget {
  final List<Map<String, dynamic>> savingsData;
  final int totalAmount;

  const DepositDetailsBody({
    super.key,
    required this.savingsData,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "รวมทั้งหมด: ฿${NumberFormat("#,##0", "en_US").format(totalAmount)}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: savingsData.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.8,
              ),
              itemBuilder: (context, index) {
                final item = savingsData[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF90CAF9), width: 1),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        item["month"],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "฿${NumberFormat("#,##0", "en_US").format(item["amount"])}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
