import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/constants.dart' as config;
import 'dart:convert';

class Loanpage extends StatefulWidget {
  final String idUser;

  const Loanpage({Key? key, required this.idUser}) : super(key: key);

  @override
  State<Loanpage> createState() => _LoanPageState();
}

class _LoanPageState extends State<Loanpage> {
  double? loanBalance;
  List<Map<String, dynamic>> repaymentList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchLoanData();
  }

  Future<void> fetchLoanData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("${config.apiUrl}/loan/${widget.idUser}"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print("Loan API response: $data"); // debug

        setState(() {
          loanBalance = (data["loan_balance"] ?? 0).toDouble();
          repaymentList = List<Map<String, dynamic>>.from(data["repayment_schedule"]);
        });
      } else {
        _showErrorDialog("เกิดข้อผิดพลาด: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("ข้อผิดพลาด"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("ตกลง"),
              ),
            ],
          );
        },
      );
    });
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildHeader(),
          SizedBox(height: 20),
          _buildRepaymentTitle(),
          _buildRepaymentList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC62828), Color(0xFFFFFFFF)],
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
          Positioned(
            top: 60,
            left: 20,
            child: Text(
              'เงินกู้',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Positioned(
            top: 110,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFE7F0FB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text("ยอดเงินกู้ยืม", style: TextStyle(fontSize: 16)),
                  SizedBox(height: 10),
                  Text(
                    "฿${loanBalance?.toStringAsFixed(0) ?? '0'}",
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // ไปหน้าชำระเงิน
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFC62828),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text("ชำระเงินกู้", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepaymentTitle() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            "กำหนดวันชำระ",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRepaymentList() {
    final unpaidList = repaymentList; // แสดงทั้งหมด

    if (unpaidList.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(20),
        child: Text("ไม่มีรายการวันชำระ", style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: unpaidList.map((repayment) {
          final rawDate = repayment["Payment_Due_Date"];
          DateTime? dueDate;

          if (rawDate != null && rawDate is String && rawDate.isNotEmpty) {
            try {
              dueDate = DateTime.parse(rawDate).toLocal();
            } catch (_) {
              dueDate = null;
            }
          }

          final formattedDate = dueDate != null
              ? "${_twoDigits(dueDate.day)}/${_twoDigits(dueDate.month)}/${dueDate.year + 543} เวลา ${_twoDigits(dueDate.hour)}:${_twoDigits(dueDate.minute)}"
              : "ไม่ทราบวันที่";

          return Card(
            margin: EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.calendar_today, color: Colors.blue),
              title: Text("วันครบกำหนด", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(formattedDate),
              trailing: Icon(Icons.warning_amber, color: Colors.redAccent),
            ),
          );
        }).toList(),
      ),
    );
  }
}
