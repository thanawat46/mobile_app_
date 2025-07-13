import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_app/constants.dart' as config;
import 'package:intl/intl.dart';

import 'DetailsSaving.dart';
import 'SavingMonth.dart';

class Savingspage extends StatefulWidget {
  final String idUser;

  const Savingspage({super.key, required this.idUser});

  @override
  State<Savingspage> createState() => _SavingspageState();
}

class _SavingspageState extends State<Savingspage> {
  double? DepositAmount;
  List<Map<String, dynamic>>? depositsList;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDepositAmount();
    _fetchDepositHistory();
  }

  Future<void> _fetchDepositAmount() async {
    setState(() => _isLoading = true);
    final String apiUrl = "${config.apiUrl}/deposit/total/${widget.idUser}";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          DepositAmount = (data["total_deposit"] ?? 0).toDouble();
        });

      } else {
        _showErrorDialog("เกิดข้อผิดพลาด: ${response.statusCode}");
      }
    } catch (error) {
      _showErrorDialog("ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์");
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDepositHistory() async {
    final apiUrl = "${config.apiUrl}/deposit/history/${widget.idUser}";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          depositsList = List<Map<String, dynamic>>.from(data["deposits"]);
        });
      } else {
        _showErrorDialog("เกิดข้อผิดพลาด: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("เชื่อมต่อเซิร์ฟเวอร์ไม่ได้");
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("ข้อผิดพลาด"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("ตกลง"),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildDepositListTitle(),
          _buildDepositList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 60,
            left: 20,
            child: Text(
              'เงินฝาก',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Positioned(
            top: 110,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F0FB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text("ยอดเงินฝากปัจจุบัน", style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text(
                    "฿${NumberFormat("#,##0", "en_US").format(DepositAmount ?? 0)}",
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DepositByMonthPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text(
                      "ฝากเงิน",
                      style: TextStyle(fontSize: 18, color: Colors.white),
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

  Widget _buildDepositListTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            "รายการฝาก",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositList() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView.builder(
          itemCount: depositsList?.length ?? 0,
          itemBuilder: (context, index) {
            final deposit = depositsList![index];
            return _buildDepositItem(deposit);
          },
        ),
      ),
    );
  }

  Widget _buildDepositItem(Map<String, dynamic> deposit) {
    DateTime? date;
    try {
      date = DateTime.parse(deposit['date_deposit']);
    } catch (_) {}

    String formattedDate = date != null
        ? "${date.day} ${_getThaiMonth(date.month)} ${date.year}"
        : "-";

    // แสดงสถานะ
    String statusText = "รอดำเนินการ";
    Color statusColor = Colors.orange;

    switch (deposit["id_status"]) {
      case "S001":
        statusText = "อนุมัติแล้ว";
        statusColor = Colors.green;
        break;
      case "S003":
        statusText = "ไม่อนุมัติ";
        statusColor = Colors.red;
        break;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Detailssaving(idDepositAm: deposit["id_DepositAm"]),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "฿${NumberFormat("#,##0", "en_US").format(deposit["amount_Deposit"])}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 14,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThaiMonth(int month) {
    const months = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return months[month];
  }
}
