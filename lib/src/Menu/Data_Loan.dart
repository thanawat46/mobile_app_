import 'package:flutter/material.dart';

import '../Home/HomePage.dart';
import 'Data_Savings/Data_Savings.dart';

class LoanScreen extends StatefulWidget {
  final String idUser;

  const LoanScreen({super.key, required this.idUser});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  bool isLoanSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        title: const Text(
          "รายชื่อสมาชิกเงินกู้",
          style: TextStyle(color: Colors.white),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            color: Colors.white,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔍 ช่องค้นหา
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'ค้นหา',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 🟢 ปุ่มสลับ
            Row(
              children: [
                _buildToggleButton("เงินกู้", isLoanSelected),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 16),

            // 🧾 หัวตาราง
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text("ชื่อ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  Expanded(flex: 2, child: Text("รหัสสมาชิก", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  Expanded(flex: 2, child: Text("ดอกเบี้ย", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  Expanded(flex: 2, child: Text("เพิ่มเติม", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 📄 รายการสมาชิกเงินกู้ (mock data)
            Expanded(
              child: ListView.builder(
                itemCount: 8,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text("Test $index", style: const TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text("6517")),
                          Expanded(flex: 2, child: Text("3000")),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(Icons.search, color: Colors.orange),
                                onPressed: () {
                                  // ไปหน้า detail ได้ที่นี่
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

            // 🚪 Footer ปุ่ม
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFooterButton('ย้อนกลับ', Colors.red, Icons.arrow_back, () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage(idUser: widget.idUser)),
                        (Route<dynamic> route) => false,
                  );
                }),
                _buildFooterButton('เพิ่มข้อมูล', Colors.green, Icons.add, () {
                  // TODO
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (text == "เงินออม") {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => SavingScreen(idUser: widget.idUser)),
                  (Route<dynamic> route) => false,
            );
          } else {
            setState(() {
              isLoanSelected = true;
            });
          }
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterButton(String text, Color color, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(text, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
