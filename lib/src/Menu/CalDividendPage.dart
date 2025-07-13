import 'package:flutter/material.dart';

class Caldividendpage extends StatefulWidget {
  const Caldividendpage({super.key});

  @override
  State<Caldividendpage> createState() => _CaldividendpageState();
}

class _CaldividendpageState extends State<Caldividendpage> {
  int _selectedIndex = 0;

  void _onTabChange(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final TextEditingController _amountController = TextEditingController();
  double _memberAmount = 0.0;
  double _directorAmount = 0.0;
  double _utilityAmount = 0.0;
  double _contributionAmount = 0.0;
  double _insuranceAmount = 0.0;
  double _totalAmount = 0.0;
  double _paidMemberAmount = 0.0;

  void _calculateAmounts() {
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    const double baseAmount = 1200000;

    setState(() {
      _memberAmount = amount * 0.7;
      _directorAmount = amount * 0.15;
      _utilityAmount = amount * 0.1;
      _contributionAmount = amount * 0.3;
      _insuranceAmount = amount * 0.23;
      _totalAmount = amount;
      _paidMemberAmount = (amount / baseAmount) * 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        title: const Text(
          "คำนวณเงินปันผล",
          style: TextStyle(color: Colors.white),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 20), // ขยับ icon ไปทางขวา
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            color: Colors.white,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "จำนวนเงิน",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _calculateAmounts();
              },
            ),
            const SizedBox(height: 25),
            _buildRow("สมาชิก", _memberAmount),
            _buildRow("กรรมการ", _directorAmount),
            _buildRow("สาธารณูปโภค", _utilityAmount),
            _buildRow("สมทบทุน", _contributionAmount),
            _buildRow("ประกันเสียง", _insuranceAmount),
            _buildRow("รวม", _totalAmount),
            _buildRow("จ่ายสมาชิก", _paidMemberAmount, isPercentage: true),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  "บันทึก",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveData() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("✅ บันทึกสำเร็จ"),
        content: const Text("ข้อมูลได้ถูกบันทึกเรียบร้อยแล้ว"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ตกลง"),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, double value, {bool isPercentage = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: TextField(
              enabled: false,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                hintText: isPercentage
                    ? "${value.toStringAsFixed(2)}%"
                    : value.toStringAsFixed(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
