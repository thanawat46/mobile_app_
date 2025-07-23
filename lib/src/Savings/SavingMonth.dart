import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'SlipPage.dart';
import 'package:mobile_app/constants.dart' as config ;

class DepositByMonthPage extends StatefulWidget {
  const DepositByMonthPage({super.key});

  @override
  State<DepositByMonthPage> createState() => _DepositByMonthPageState();
}

class _DepositByMonthPageState extends State<DepositByMonthPage> {
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _memberIdController = TextEditingController();

  final List<String> _months = const [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];

  @override
  void initState() {
    super.initState();
    for (var month in _months) {
      _controllers[month] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _memberIdController.dispose();
    super.dispose();
  }

  double get totalDeposit => _controllers.values.fold(
    0.0,
        (sum, controller) => sum + (double.tryParse(controller.text) ?? 0.0),
  );

  Future<void> _submitDeposit(BuildContext context) async {
    final hasAnyAmount = _controllers.values.any(
          (controller) => double.tryParse(controller.text) != null && double.parse(controller.text) > 0,
    );

    if (!hasAnyAmount) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          Future.delayed(const Duration(seconds: 2), () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          });

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text(
                  "แจ้งเตือน",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
            content: const Text(
              "กรุณากรอกจำนวนเงินที่จะฝาก",
              style: TextStyle(fontSize: 16, color: Color(0xFF555555)),
            ),
          );
        },
      );
      return;
    }

    final depositMonth = List.generate(12, (index) {
      final month = index + 1;
      final amount = _controllers[_months[index]]?.text ?? '0';
      final parsedAmount = double.tryParse(amount);

      if (parsedAmount != null && parsedAmount > 0) {
        return {
          "month": month.toString(),
          "amount": parsedAmount.toString()
        };
      } else {
        return null;
      }
    }).where((item) => item != null).toList();

    final Map<String, dynamic> requestBody = {
      'id_user': _memberIdController.text.toString(),
      'date_deposit': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'Deposit_month': depositMonth,
    };

    print('Request Body: ${jsonEncode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse('${config.apiUrl}/deposit-month'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseBody['data'] != null && responseBody['data']['idDepositAm'] != null) {
          final idDepositAm = responseBody['data']['idDepositAm'].toString();

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SlipPage(
                memberId: _memberIdController.text,
                amount: totalDeposit,
                idDepositAm: idDepositAm,
              ),
            ),
          );

          // ✅ ถ้าไม่ได้แนบสลิป → ลบ deposit_amount
          if (result != 'slip_uploaded') {
            await _deleteDepositAmount(idDepositAm);
          }

        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("ไม่พบข้อมูล id_DepositAm ใน API Response")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseBody['message'] ?? 'Error')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send data')),
      );
    }
  }

  Future<void> _deleteDepositAmount(String idDepositAm) async {
    try {
      final response = await http.delete(
        Uri.parse('${config.apiUrl}/deposit-amount/$idDepositAm'),
      );

      if (response.statusCode == 200) {
        print('✔️ ลบ deposit_amount เรียบร้อยแล้ว');
      } else {
        print('❌ ลบไม่สำเร็จ: ${response.body}');
      }
    } catch (e) {
      print('❌ Error ลบข้อมูลฝากเงิน: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    final leftMonths = _months.sublist(0, 6);
    final rightMonths = _months.sublist(6);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: const Text(
          "ฝากเงินรายเดือน",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0069FF),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const HeaderTitle(),
                const SizedBox(height: 16),
                TextField(
                  controller: _memberIdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "รหัสสมาชิก",
                    prefixIcon: const Icon(Icons.person),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                DepositFormColumns(
                  leftMonths: leftMonths,
                  rightMonths: rightMonths,
                  controllers: _controllers,
                  onChanged: () => setState(() {}),
                ),
                const Divider(height: 32, thickness: 1.5),
                TotalDepositSummary(total: totalDeposit),
                const SizedBox(height: 24),
                SubmitButton(
                  memberId: _memberIdController.text,
                  amount: totalDeposit,
                  onPressed: () {
                    _submitDeposit(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HeaderTitle extends StatelessWidget {
  const HeaderTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      "ฝากเงินรายเดือน",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF003366),
      ),
    );
  }
}

class DepositFormColumns extends StatelessWidget {
  final List<String> leftMonths;
  final List<String> rightMonths;
  final Map<String, TextEditingController> controllers;
  final VoidCallback onChanged;

  const DepositFormColumns({
    super.key,
    required this.leftMonths,
    required this.rightMonths,
    required this.controllers,
    required this.onChanged,
  });

  Widget _buildTextField(String month) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(month, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          TextField(
            controller: controllers[month],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "บาท",
              prefixIcon: const Icon(Icons.savings, size: 18),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => onChanged(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: leftMonths.map(_buildTextField).toList(),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rightMonths.map(_buildTextField).toList(),
          ),
        ),
      ],
    );
  }
}

class TotalDepositSummary extends StatelessWidget {
  final double total;

  const TotalDepositSummary({super.key, required this.total});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat("#,##0.00", "th_TH");
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("รวมเงินฝาก", style: TextStyle(fontSize: 18)),
        Text(
          "${numberFormat.format(total)} บาท",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0069FF),
          ),
        ),
      ],
    );
  }
}

class SubmitButton extends StatelessWidget {
  final String memberId;
  final double amount;
  final Function onPressed;

  const SubmitButton({
    super.key,
    required this.memberId,
    required this.amount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          onPressed(); // เรียกใช้งานฟังก์ชันเมื่อกดปุ่ม
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0069FF),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 4,
        ),
        child: const Text(
          "จ่ายเงิน",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
